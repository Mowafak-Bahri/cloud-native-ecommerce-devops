const express = require("express");
const axios = require("axios");
const dotenv = require("dotenv");
const pino = require("pino");
const helmet = require("helmet");
const cors = require("cors");
const AWSXRay = require("aws-xray-sdk");
const http = require("http");
const https = require("https");

dotenv.config();

AWSXRay.captureHTTPsGlobal(http, true);
AWSXRay.captureHTTPsGlobal(https, true);

const logger = pino();

const PRODUCT_SERVICE_URL = process.env.PRODUCT_SERVICE_URL || "http://localhost:8000";
const ORDER_SERVICE_URL = process.env.ORDER_SERVICE_URL || "http://localhost:8001";
const PORT = process.env.PORT || 3000;

const app = express();
app.use(AWSXRay.express.openSegment("FrontendService"));
app.use(helmet());
app.use(cors());

app.get("/", (req, res) => {
  res.json({
    message: "Welcome to the Cloud-Native E-Commerce API gateway",
    links: {
      products: "/products",
      orders: "/orders",
      health: "/health"
    }
  });
});

app.get("/health", async (req, res, next) => {
  try {
    const [productHealth, orderHealth] = await Promise.all([
      axios.get(`${PRODUCT_SERVICE_URL}/health`, { timeout: 5000 }),
      axios.get(`${ORDER_SERVICE_URL}/health`, { timeout: 5000 })
    ]);
    res.json({
      status: "healthy",
      product_service: productHealth.data.status,
      order_service: orderHealth.data.status
    });
  } catch (error) {
    logger.error({ err: error }, "Health check failed");
    res.status(503).json({
      status: "unhealthy",
      error: error.message
    });
  }
});

app.get("/products", async (req, res, next) => {
  try {
    const response = await axios.get(`${PRODUCT_SERVICE_URL}/products`, { timeout: 5000 });
    res.json(response.data);
  } catch (error) {
    logger.error({ err: error }, "Failed to fetch products");
    if (error.response && error.response.status) {
      error.statusCode = error.response.status;
    }
    next(error);
  }
});

app.get("/orders", async (req, res, next) => {
  try {
    const response = await axios.get(`${ORDER_SERVICE_URL}/orders`, { timeout: 5000 });
    res.json(response.data);
  } catch (error) {
    logger.error({ err: error }, "Failed to fetch orders");
    next(error);
  }
});

app.use(AWSXRay.express.closeSegment());

// Centralized error handling middleware
app.use((err, req, res, next) => {
  logger.error({ err }, "Unhandled error occurred in frontend service");
  const statusCode = err.statusCode || 500;
  const message = (err.response && err.response.data && err.response.data.detail) || err.message || "An unexpected error occurred in frontend service";
  res.status(statusCode).json({ error: message });
});

app.listen(PORT, () => {
  logger.info(`Frontend service running on port ${PORT}`);
});
