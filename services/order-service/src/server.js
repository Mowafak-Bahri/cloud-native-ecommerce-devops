const express = require("express");
const axios = require("axios");
const dotenv = require("dotenv");
const pino = require("pino");
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
app.use(express.json());

app.get("/health", async (req, res) => {
  try {
    await pool.query("SELECT 1");
    res.json({ status: "healthy", service: "order-service" });
  } catch (error) {
    logger.error({ err: error }, "Health check failed");
    res.status(503).json({ error: "Database unavailable" });
  }
});

app.get("/orders", async (req, res) => {
  try {
    const result = await pool.query(
      "SELECT id, product_id, quantity, total_price, status, created_at FROM orders ORDER BY created_at DESC"
    );
    res.json(result.rows);
  } catch (error) {
    logger.error({ err: error }, "Failed to fetch orders");
    res.status(500).json({ error: "Failed to fetch orders" });
  }
});

app.post("/orders", async (req, res) => {
  const { product_id: productId, quantity } = req.body;
  if (!productId || !quantity || quantity <= 0) {
    return res.status(400).json({ error: "product_id and quantity must be provided" });
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
    const result = await pool.query(insertSQL, [productId, quantity, totalPrice, "CONFIRMED"]);
    res.status(201).json(result.rows[0]);
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
    res.status(500).json({ error: "Failed to create order" });
  }
});

app.use(AWSXRay.express.closeSegment());

const server = http.createServer(app);

server.listen(PORT, async () => {
  try {
    await initializeDatabase();
    logger.info(`Order service running on port ${PORT}`);
  } catch (error) {
    logger.error({ err: error }, "Failed to initialize database");
    process.exit(1);
  }
});
