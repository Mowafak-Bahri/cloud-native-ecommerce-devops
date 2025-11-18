import logging
import os
from contextlib import contextmanager
from decimal import Decimal
from typing import Generator, List, Optional

import psycopg2
from pythonjsonlogger import jsonlogger
from slowapi import Limiter, _rate_limit_exceeded_handler
from slowapi.errors import RateLimitExceeded
from slowapi.middleware import SlowAPIMiddleware
from slowapi.util import get_remote_address

# Configure logger
logger = logging.getLogger("product-service")
logger.setLevel(logging.INFO)
logHandler = logging.StreamHandler()
formatter = jsonlogger.JsonFormatter()
logHandler.setFormatter(formatter)
logger.addHandler(logHandler)


from dotenv import load_dotenv
from fastapi import FastAPI, HTTPException, Request, status
from psycopg2 import pool
from psycopg2.extras import RealDictCursor
from pydantic import BaseModel, Field

load_dotenv()



app = FastAPI(title="Product Service", version="1.0.0")
limiter = Limiter(key_func=get_remote_address, default_limits=["60/minute"])
app.state.limiter = limiter
app.add_exception_handler(RateLimitExceeded, _rate_limit_exceeded_handler)
app.add_middleware(SlowAPIMiddleware)


DB_POOL: Optional[pool.SimpleConnectionPool] = None


def get_db_settings() -> dict:
    return {
        "host": os.getenv("DB_HOST", "localhost"),
        "database": os.getenv("DB_NAME", "ecommerce"),
        "user": os.getenv("DB_USER", "postgres"),
        "password": os.getenv("DB_PASSWORD", "password"),
        "port": int(os.getenv("DB_PORT", "5432")),
    }


def init_connection_pool() -> None:
    """Initialize the PostgreSQL connection pool if it does not exist."""
    global DB_POOL
    if DB_POOL is not None:
        return

    db_config = get_db_settings()
    minconn = int(os.getenv("DB_POOL_MIN", "1"))
    maxconn = int(os.getenv("DB_POOL_MAX", "5"))

    try:
        DB_POOL = pool.SimpleConnectionPool(minconn, maxconn, **db_config)
    except Exception as exc:
        logger.error("Failed to initialize database pool", extra={"error": str(exc)})
        raise


def close_connection_pool() -> None:
    global DB_POOL
    if DB_POOL:
        DB_POOL.closeall()
        DB_POOL = None


@contextmanager
def get_connection() -> Generator[psycopg2.extensions.connection, None, None]:
    """Context manager for acquiring and releasing pooled connections."""
    if DB_POOL is None:
        raise HTTPException(status_code=status.HTTP_503_SERVICE_UNAVAILABLE, detail="Database unavailable")

    conn = None
    try:
        conn = DB_POOL.getconn()
        yield conn
    except HTTPException:
        raise
    except Exception as exc:
        logger.error("Database connection error", extra={"error": str(exc)})
        raise HTTPException(status_code=status.HTTP_503_SERVICE_UNAVAILABLE, detail="Database unavailable")
    finally:
        if conn and DB_POOL:
            DB_POOL.putconn(conn)


class Product(BaseModel):
    id: Optional[int] = None
    name: str = Field(..., min_length=1, max_length=255)
    description: str = Field(..., min_length=1)
    price: float = Field(..., gt=0)
    stock: int = Field(..., ge=0)
    category: str = Field(..., min_length=1, max_length=255)


def serialize_product(record: dict) -> Product:
    return Product(
        id=record.get("id"),
        name=record.get("name"),
        description=record.get("description", ""),
        price=float(record.get("price")) if isinstance(record.get("price"), Decimal) else record.get("price"),
        stock=record.get("stock"),
        category=record.get("category", "Uncategorized"),
    )


def initialize_database() -> None:
    create_table_sql = """
        CREATE TABLE IF NOT EXISTS products (
            id SERIAL PRIMARY KEY,
            name VARCHAR(255) NOT NULL,
            description TEXT,
            price DECIMAL(10, 2) NOT NULL CHECK (price >= 0),
            stock INTEGER NOT NULL CHECK (stock >= 0),
            category VARCHAR(255) NOT NULL DEFAULT 'Uncategorized'
        )
    """
    seed_sql = """
        INSERT INTO products (name, description, price, stock, category) VALUES
            ('Laptop Pro', 'High-performance laptop', 1299.99, 25, 'Electronics'),
            ('Noise Cancelling Headphones', 'Wireless over-ear headphones', 249.00, 120, 'Audio'),
            ('Wireless Mouse', 'Ergonomic wireless mouse', 39.95, 200, 'Electronics')
    """

    with get_connection() as conn:
        cursor = conn.cursor()
        try:
            cursor.execute(create_table_sql)
            cursor.execute("SELECT COUNT(*) FROM products")
            row_count = cursor.fetchone()[0]

            if row_count == 0:
                cursor.execute(seed_sql)

            conn.commit()
            logger.info("Database initialized successfully")
        except Exception as exc:
            conn.rollback()
            logger.error("Database initialization error", extra={"error": str(exc)})
            raise
        finally:
            cursor.close()


@app.on_event("startup")
async def startup_event() -> None:
    try:
        init_connection_pool()
        initialize_database()
    except Exception as exc:
        logger.error("Startup error", extra={"error": str(exc)})


@app.on_event("shutdown")
async def shutdown_event() -> None:
    close_connection_pool()


@app.get("/health")
@limiter.limit("30/minute")
async def health_check(request: Request):
    try:
        with get_connection() as conn:
            cursor = conn.cursor()
            cursor.execute("SELECT 1")
            cursor.close()
        return {"status": "healthy", "service": "product-service", "database": "connected"}
    except HTTPException:
        raise
    except Exception as exc:
        logger.error("Health check failed", extra={"error": str(exc)})
        raise HTTPException(status_code=status.HTTP_503_SERVICE_UNAVAILABLE, detail="Database unhealthy")


@app.get("/products", response_model=List[Product])
@limiter.limit("60/minute")
async def get_products(request: Request):
    with get_connection() as conn:
        cursor = conn.cursor(cursor_factory=RealDictCursor)
        try:
            cursor.execute("SELECT id, name, description, price, stock, category FROM products ORDER BY id")
            records = cursor.fetchall()
            return [serialize_product(record) for record in records]
        except Exception as exc:
            logger.error("Error fetching products", extra={"error": str(exc)})
            raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail="Failed to fetch products")
        finally:
            cursor.close()


@app.get("/products/{product_id}", response_model=Product)
@limiter.limit("60/minute")
async def get_product(request: Request, product_id: int):
    with get_connection() as conn:
        cursor = conn.cursor(cursor_factory=RealDictCursor)
        try:
            cursor.execute(
                "SELECT id, name, description, price, stock, category FROM products WHERE id = %s",
                (product_id,),
            )
            record = cursor.fetchone()
            if not record:
                raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Product not found")
            return serialize_product(record)
        except HTTPException:
            raise
        except Exception as exc:
            logger.error(
                "Error fetching product",
                extra={"error": str(exc), "product_id": product_id},
            )
            raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail="Failed to fetch product")
        finally:
            cursor.close()


@app.post("/products", response_model=Product, status_code=status.HTTP_201_CREATED)
@limiter.limit("15/minute")
async def create_product(request: Request, product: Product):
    with get_connection() as conn:
        cursor = conn.cursor(cursor_factory=RealDictCursor)
        try:
            cursor.execute(
                """
                INSERT INTO products (name, description, price, stock)
                VALUES (%s, %s, %s, %s)
                RETURNING id, name, description, price, stock
                """,
                (product.name, product.description, product.price, product.stock),
            )
            created = cursor.fetchone()
            conn.commit()
            return serialize_product(created)
        except Exception as exc:
            conn.rollback()
            logger.error("Error creating product", extra={"error": str(exc)})
            raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail="Failed to create product")
        finally:
            cursor.close()
