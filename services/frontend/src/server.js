const express = require("express");
const axios = require("axios");
const dotenv = require("dotenv");
const pino = require("pino");
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

app.get("/health", async (req, res) => {
  try {
    const [productHealth, orderHealth] = await Promise.all([
      axios.get(`${PRODUCT_SERVICE_URL}/health`),
      axios.get(`${ORDER_SERVICE_URL}/health`)
    ]);
    res.json({
      status: "healthy",
      dependencies: {
        productService: productHealth.data.status,
        orderService: orderHealth.data.status
      }
    });
  } catch (error) {
    logger.error({ err: error }, "Health check failed");
    res.status(503).json({ error: "Dependent services unhealthy" });
  }
});

app.get("/products", async (req, res) => {
  try {
    const response = await axios.get(`${PRODUCT_SERVICE_URL}/products`);
    res.json(response.data);
  } catch (error) {
    logger.error({ err: error }, "Failed to fetch products");
    res.status(500).json({ error: "Failed to fetch products" });
  }
});

app.get("/orders", async (req, res) => {
  try {
    const response = await axios.get(`${ORDER_SERVICE_URL}/orders`);
    res.json(response.data);
  } catch (error) {
    logger.error({ err: error }, "Failed to fetch orders");
    res.status(500).json({ error: "Failed to fetch orders" });
  }
});

app.use(AWSXRay.express.closeSegment());

app.listen(PORT, () => {
  logger.info(`Frontend service running on port ${PORT}`);
});
