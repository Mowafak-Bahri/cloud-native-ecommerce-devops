const express = require("express");
const axios = require("axios");
const dotenv = require("dotenv");
const pino = require("pino");
const helmet = require("helmet");
const cors = require("cors");
const rateLimit = require("express-rate-limit");
const AWSXRay = require("aws-xray-sdk");
const http = require("http");
const https = require("https");
const pg = AWSXRay.capturePostgres(require("pg"));

dotenv.config();

AWSXRay.captureHTTPsGlobal(http, true);
AWSXRay.captureHTTPsGlobal(https, true);

const logger = pino();

const PORT = process.env.PORT || 8001;
const PRODUCT_SERVICE_URL = process.env.PRODUCT_SERVICE_URL || "http://localhost:8000";

const pool = new pg.Pool({
  host: process.env.DB_HOST || "localhost",
  port: parseInt(process.env.DB_PORT || "5432", 10),
  user: process.env.DB_USER || "postgres",
  password: process.env.DB_PASSWORD || "password",
  database: process.env.DB_NAME || "ecommerce",
  max: parseInt(process.env.DB_POOL_MAX || "10", 10),
  idleTimeoutMillis: 30000,
});

async function initializeDatabase() {
  const createTableSQL = `
    CREATE TABLE IF NOT EXISTS orders (
      id SERIAL PRIMARY KEY,
      product_id INTEGER NOT NULL,
      quantity INTEGER NOT NULL CHECK (quantity > 0),
      total_price NUMERIC(10, 2) NOT NULL CHECK (total_price >= 0),
      status VARCHAR(50) NOT NULL DEFAULT 'PENDING',
      created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
    );
  `;
  await pool.query(createTableSQL);
}

const app = express();
app.use(AWSXRay.express.openSegment("OrderService"));
// Helmet hardens common HTTP headers before requests reach business logic.
app.use(
  helmet({
    contentSecurityPolicy: false, // CSP handled upstream
    crossOriginEmbedderPolicy: false,
    crossOriginResourcePolicy: { policy: "same-site" },
    referrerPolicy: { policy: "no-referrer" },
    frameguard: { action: "deny" },
    hsts: process.env.NODE_ENV === "production" ? undefined : false, // ALB terminates TLS
  })
);
const allowedOrigins = process.env.ALLOWED_ORIGINS?.split(',') || ['http://localhost:3000'];

app.use(cors({
  origin: function (origin, callback) {
    if (!origin || allowedOrigins.indexOf(origin) !== -1) {
      callback(null, true);
    } else {
      callback(new Error('Not allowed by CORS'));
    }
  },
  credentials: true
}));
app.use(express.json());

// Apply rate limiting to all requests
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100, // Limit each IP to 100 requests per windowMs
  message: "Too many requests from this IP, please try again after 15 minutes",
});
app.use(limiter);

app.get("/health", async (req, res) => {
  try {
    await pool.query("SELECT 1");
    res.json({ status: "healthy", service: "order-service" });
  } catch (error) {
    logger.error({ err: error }, "Health check failed");
    next(error);
  }
});

app.get("/orders", async (req, res) => {
  try {
    const orders = await pool.query(
      "SELECT id, product_id, quantity, total_price, status, created_at FROM orders ORDER BY created_at DESC"
    );
    res.json(orders.rows);
  } catch (error) {
    logger.error({ err: error }, "Failed to fetch orders");
    next(error);
  }
});

app.post("/orders", async (req, res) => {
  const { product_id: productId, quantity } = req.body;
  if (!productId || !quantity || !Number.isInteger(productId) || productId <= 0 || !Number.isInteger(quantity) || quantity <= 0 || quantity > 10000) {
    return res.status(400).json({ error: "product_id must be a positive integer and quantity must be an integer between 1 and 10000" });
  }

  try {
    const productResponse = await axios.get(`${PRODUCT_SERVICE_URL}/products/${productId}`);
    const product = productResponse.data;

    if (quantity > product.stock) {
      return res.status(400).json({ error: "Insufficient stock" });
    }

    const totalPrice = Number(product.price) * quantity;
    const insertSQL = `
      INSERT INTO orders (product_id, quantity, total_price, status)
      VALUES ($1, $2, $3, $4)
      RETURNING id, product_id, quantity, total_price, status, created_at
    `;
    const createdOrder = await pool.query(insertSQL, [productId, quantity, totalPrice, "PENDING"]);
    res.status(201).json(createdOrder.rows[0]);
  } catch (error) {
    if (axios.isAxiosError(error)) {
      const status = error.response?.status || 502;
      logger.warn({ err: error, status }, "Product service request failed");
      if (status === 404) {
        return res.status(404).json({ error: "Product not found" });
      }
      return res.status(502).json({ error: "Product service unavailable" });
    }

    logger.error({ err: error }, "Failed to create order");
    next(error);
  }
});

app.use(AWSXRay.express.closeSegment());

// Centralized error handling middleware
app.use((err, req, res, next) => {
  logger.error({ err }, "Unhandled error occurred");
  const statusCode = err.statusCode || 500;
  const message = err.message || "An unexpected error occurred";
  res.status(statusCode).json({ error: message });
});

const server = http.createServer(app);

server.listen(PORT, () => {
  const namespace = AWSXRay.getNamespace();
  const bootstrapSegment = new AWSXRay.Segment("OrderServiceBootstrap");

  const runBootstrap = async () => {
    try {
      await initializeDatabase();
      logger.info(`Order service running on port ${PORT}`);
    } catch (error) {
      bootstrapSegment.addError(error);
      logger.error({ err: error }, "Failed to initialize database");
      process.exit(1);
    } finally {
      bootstrapSegment.close();
    }
  };

  if (namespace) {
    namespace.run(() => {
      AWSXRay.setSegment(bootstrapSegment);
      runBootstrap().finally(() => AWSXRay.setSegment(null));
    });
  } else {
    runBootstrap();
  }
});
