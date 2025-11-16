import os
from contextlib import contextmanager
from decimal import Decimal
from typing import Generator, List, Optional

import psycopg2
from aws_xray_sdk.core import patch_all, xray_recorder
from aws_xray_sdk.ext.fastapi.middleware import XRayMiddleware
from dotenv import load_dotenv
from fastapi import FastAPI, HTTPException, status
from psycopg2 import pool
from psycopg2.extras import RealDictCursor
from pydantic import BaseModel, Field

load_dotenv()

patch_all()
xray_recorder.configure(service="ProductService")

app = FastAPI(title="Product Service", version="1.0.0")
app.add_middleware(XRayMiddleware, recorder=xray_recorder)

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
        print(f"Failed to initialize database pool: {exc}")
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
        print(f"Database connection error: {exc}")
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


def serialize_product(record: dict) -> Product:
    return Product(
        id=record.get("id"),
        name=record.get("name"),
        description=record.get("description", ""),
        price=float(record.get("price")) if isinstance(record.get("price"), Decimal) else record.get("price"),
        stock=record.get("stock"),
    )


def initialize_database() -> None:
    create_table_sql = """
        CREATE TABLE IF NOT EXISTS products (
            id SERIAL PRIMARY KEY,
            name VARCHAR(255) NOT NULL,
            description TEXT,
            price DECIMAL(10, 2) NOT NULL CHECK (price >= 0),
            stock INTEGER NOT NULL CHECK (stock >= 0)
        )
    """
    seed_sql = """
        INSERT INTO products (name, description, price, stock) VALUES
            ('Laptop Pro', 'High-performance laptop', 1299.99, 25),
            ('Noise Cancelling Headphones', 'Wireless over-ear headphones', 249.00, 120),
            ('Wireless Mouse', 'Ergonomic wireless mouse', 39.95, 200)
    """

    with get_connection() as conn:
        cursor = conn.cursor()
        try:
            with xray_recorder.in_subsegment("create_table"):
                cursor.execute(create_table_sql)
            with xray_recorder.in_subsegment("count_products"):
                cursor.execute("SELECT COUNT(*) FROM products")
                row_count = cursor.fetchone()[0]

            if row_count == 0:
                with xray_recorder.in_subsegment("seed_products"):
                    cursor.execute(seed_sql)

            conn.commit()
            print("Database initialized successfully")
        except Exception as exc:
            conn.rollback()
            print(f"Database initialization error: {exc}")
            raise
        finally:
            cursor.close()


@app.on_event("startup")
async def startup_event() -> None:
    try:
        init_connection_pool()
        initialize_database()
    except Exception as exc:
        print(f"Startup error: {exc}")


@app.on_event("shutdown")
async def shutdown_event() -> None:
    close_connection_pool()


@app.get("/health")
async def health_check():
    try:
        with get_connection() as conn:
            cursor = conn.cursor()
            cursor.execute("SELECT 1")
            cursor.close()
        return {"status": "healthy", "service": "product-service"}
    except HTTPException:
        raise
    except Exception as exc:
        print(f"Health check failed: {exc}")
        raise HTTPException(status_code=status.HTTP_503_SERVICE_UNAVAILABLE, detail="Database unhealthy")


@app.get("/products", response_model=List[Product])
async def get_products():
    with get_connection() as conn:
        cursor = conn.cursor(cursor_factory=RealDictCursor)
        try:
            with xray_recorder.in_subsegment("get_products_query"):
                cursor.execute("SELECT id, name, description, price, stock FROM products ORDER BY id")
            records = cursor.fetchall()
            return [serialize_product(record) for record in records]
        except Exception as exc:
            print(f"Error fetching products: {exc}")
            raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail="Failed to fetch products")
        finally:
            cursor.close()


@app.get("/products/{product_id}", response_model=Product)
async def get_product(product_id: int):
    with get_connection() as conn:
        cursor = conn.cursor(cursor_factory=RealDictCursor)
        try:
            with xray_recorder.in_subsegment("get_product_query"):
                cursor.execute(
                    "SELECT id, name, description, price, stock FROM products WHERE id = %s",
                    (product_id,),
                )
            record = cursor.fetchone()
            if not record:
                raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Product not found")
            return serialize_product(record)
        except HTTPException:
            raise
        except Exception as exc:
            print(f"Error fetching product {product_id}: {exc}")
            raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail="Failed to fetch product")
        finally:
            cursor.close()


@app.post("/products", response_model=Product, status_code=status.HTTP_201_CREATED)
async def create_product(product: Product):
    with get_connection() as conn:
        cursor = conn.cursor(cursor_factory=RealDictCursor)
        try:
            with xray_recorder.in_subsegment("create_product_query"):
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
            print(f"Error creating product: {exc}")
            raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail="Failed to create product")
        finally:
            cursor.close()
