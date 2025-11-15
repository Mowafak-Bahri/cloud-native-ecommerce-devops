# 🚀 Quick Start: Code Templates & Commands

This file contains starter code templates and commands for your AWS DevOps project.

---

## 📁 PROJECT STRUCTURE SETUP

```bash
# Create the complete project structure
mkdir -p aws-devops-ecommerce/{services/{frontend,product-service,order-service},terraform/{modules/{networking,ecs,rds,monitoring},.github/workflows,docs,scripts}}

cd aws-devops-ecommerce

# Initialize git
git init
git add .
git commit -m "Initial project structure"
```

---

## 🐳 MICROSERVICES CODE TEMPLATES

### Frontend Service (Node.js/Express)

**File: `services/frontend/package.json`**
```json
{
  "name": "frontend-service",
  "version": "1.0.0",
  "description": "Frontend service for e-commerce platform",
  "main": "server.js",
  "scripts": {
    "start": "node server.js",
    "dev": "nodemon server.js"
  },
  "dependencies": {
    "express": "^4.18.2",
    "axios": "^1.5.0",
    "ejs": "^3.1.9"
  }
}
```

**File: `services/frontend/server.js`**
```javascript
const express = require('express');
const axios = require('axios');
const app = express();
const PORT = process.env.PORT || 3000;

// Environment variables
const PRODUCT_SERVICE_URL = process.env.PRODUCT_SERVICE_URL || 'http://localhost:8000';
const ORDER_SERVICE_URL = process.env.ORDER_SERVICE_URL || 'http://localhost:8001';

app.use(express.json());
app.set('view engine', 'ejs');

// Health check endpoint (required for ALB)
app.get('/health', (req, res) => {
  res.status(200).json({ status: 'healthy', service: 'frontend' });
});

// Home page
app.get('/', async (req, res) => {
  try {
    const response = await axios.get(`${PRODUCT_SERVICE_URL}/products`);
    res.json({
      message: 'E-Commerce Frontend',
      products: response.data,
      links: {
        products: '/products',
        orders: '/orders',
        health: '/health'
      }
    });
  } catch (error) {
    console.error('Error fetching products:', error.message);
    res.status(500).json({ error: 'Failed to fetch products' });
  }
});

// Products page
app.get('/products', async (req, res) => {
  try {
    const response = await axios.get(`${PRODUCT_SERVICE_URL}/products`);
    res.json(response.data);
  } catch (error) {
    console.error('Error:', error.message);
    res.status(500).json({ error: 'Service unavailable' });
  }
});

// Orders page
app.get('/orders', async (req, res) => {
  try {
    const response = await axios.get(`${ORDER_SERVICE_URL}/orders`);
    res.json(response.data);
  } catch (error) {
    console.error('Error:', error.message);
    res.status(500).json({ error: 'Service unavailable' });
  }
});

app.listen(PORT, () => {
  console.log(`Frontend service running on port ${PORT}`);
});
```

**File: `services/frontend/Dockerfile`**
```dockerfile
FROM node:18-alpine

# Create app directory
WORKDIR /app

# Copy package files
COPY package*.json ./

# Install dependencies
RUN npm ci --only=production

# Copy app source
COPY . .

# Expose port
EXPOSE 3000

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=40s \
  CMD node -e "require('http').get('http://localhost:3000/health', (r) => {process.exit(r.statusCode === 200 ? 0 : 1)})"

# Start app
CMD ["node", "server.js"]
```

---

### Product Service (Python/FastAPI)

**File: `services/product-service/requirements.txt`**
```
fastapi==0.104.1
uvicorn==0.24.0
psycopg2-binary==2.9.9
pydantic==2.5.0
python-dotenv==1.0.0
```

**File: `services/product-service/app/main.py`**
```python
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from typing import List, Optional
import os
import psycopg2
from psycopg2.extras import RealDictCursor

app = FastAPI(title="Product Service")

# Database configuration
DB_CONFIG = {
    "host": os.getenv("DB_HOST", "localhost"),
    "database": os.getenv("DB_NAME", "ecommerce"),
    "user": os.getenv("DB_USER", "postgres"),
    "password": os.getenv("DB_PASSWORD", "password"),
    "port": os.getenv("DB_PORT", "5432")
}

class Product(BaseModel):
    id: Optional[int] = None
    name: str
    description: str
    price: float
    stock: int

def get_db_connection():
    """Create database connection"""
    try:
        conn = psycopg2.connect(**DB_CONFIG)
        return conn
    except Exception as e:
        print(f"Database connection error: {e}")
        raise HTTPException(status_code=500, detail="Database connection failed")

@app.on_event("startup")
async def startup_event():
    """Initialize database schema"""
    try:
        conn = get_db_connection()
        cur = conn.cursor()
        cur.execute("""
            CREATE TABLE IF NOT EXISTS products (
                id SERIAL PRIMARY KEY,
                name VARCHAR(255) NOT NULL,
                description TEXT,
                price DECIMAL(10, 2) NOT NULL,
                stock INTEGER NOT NULL
            )
        """)
        # Insert sample data if table is empty
        cur.execute("SELECT COUNT(*) FROM products")
        if cur.fetchone()[0] == 0:
            cur.execute("""
                INSERT INTO products (name, description, price, stock) VALUES
                ('Laptop', 'High-performance laptop', 999.99, 50),
                ('Mouse', 'Wireless mouse', 29.99, 200),
                ('Keyboard', 'Mechanical keyboard', 79.99, 150)
            """)
        conn.commit()
        cur.close()
        conn.close()
        print("Database initialized successfully")
    except Exception as e:
        print(f"Startup error: {e}")

@app.get("/health")
async def health_check():
    """Health check endpoint for ALB"""
    try:
        conn = get_db_connection()
        conn.close()
        return {"status": "healthy", "service": "product-service"}
    except:
        raise HTTPException(status_code=503, detail="Database unhealthy")

@app.get("/products", response_model=List[Product])
async def get_products():
    """Get all products"""
    try:
        conn = get_db_connection()
        cur = conn.cursor(cursor_factory=RealDictCursor)
        cur.execute("SELECT * FROM products")
        products = cur.fetchall()
        cur.close()
        conn.close()
        return products
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/products/{product_id}", response_model=Product)
async def get_product(product_id: int):
    """Get product by ID"""
    try:
        conn = get_db_connection()
        cur = conn.cursor(cursor_factory=RealDictCursor)
        cur.execute("SELECT * FROM products WHERE id = %s", (product_id,))
        product = cur.fetchone()
        cur.close()
        conn.close()
        if not product:
            raise HTTPException(status_code=404, detail="Product not found")
        return product
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/products", response_model=Product)
async def create_product(product: Product):
    """Create new product"""
    try:
        conn = get_db_connection()
        cur = conn.cursor(cursor_factory=RealDictCursor)
        cur.execute(
            "INSERT INTO products (name, description, price, stock) VALUES (%s, %s, %s, %s) RETURNING *",
            (product.name, product.description, product.price, product.stock)
        )
        new_product = cur.fetchone()
        conn.commit()
        cur.close()
        conn.close()
        return new_product
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
```

**File: `services/product-service/Dockerfile`**
```dockerfile
FROM python:3.11-slim

# Set working directory
WORKDIR /app

# Install dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application
COPY app/ ./app/

# Expose port
EXPOSE 8000

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=40s \
  CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:8000/health').read()" || exit 1

# Run application
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
```

---

### Order Service (Node.js/Express)

**File: `services/order-service/package.json`**
```json
{
  "name": "order-service",
  "version": "1.0.0",
  "description": "Order service for e-commerce platform",
  "main": "server.js",
  "scripts": {
    "start": "node server.js"
  },
  "dependencies": {
    "express": "^4.18.2",
    "pg": "^8.11.3",
    "axios": "^1.5.0"
  }
}
```

**File: `services/order-service/server.js`**
```javascript
const express = require('express');
const { Pool } = require('pg');
const axios = require('axios');

const app = express();
const PORT = process.env.PORT || 8001;

// Database connection
const pool = new Pool({
  host: process.env.DB_HOST || 'localhost',
  database: process.env.DB_NAME || 'ecommerce',
  user: process.env.DB_USER || 'postgres',
  password: process.env.DB_PASSWORD || 'password',
  port: process.env.DB_PORT || 5432,
});

// Product service URL
const PRODUCT_SERVICE_URL = process.env.PRODUCT_SERVICE_URL || 'http://localhost:8000';

app.use(express.json());

// Initialize database
const initDB = async () => {
  try {
    await pool.query(`
      CREATE TABLE IF NOT EXISTS orders (
        id SERIAL PRIMARY KEY,
        product_id INTEGER NOT NULL,
        quantity INTEGER NOT NULL,
        total_price DECIMAL(10, 2) NOT NULL,
        status VARCHAR(50) DEFAULT 'pending',
        created_at TIMESTAMP DEFAULT NOW()
      )
    `);
    console.log('Database initialized');
  } catch (error) {
    console.error('Database init error:', error);
  }
};

initDB();

// Health check
app.get('/health', async (req, res) => {
  try {
    await pool.query('SELECT 1');
    res.status(200).json({ status: 'healthy', service: 'order-service' });
  } catch (error) {
    res.status(503).json({ status: 'unhealthy', error: error.message });
  }
});

// Get all orders
app.get('/orders', async (req, res) => {
  try {
    const result = await pool.query('SELECT * FROM orders ORDER BY created_at DESC');
    res.json(result.rows);
  } catch (error) {
    console.error('Error:', error);
    res.status(500).json({ error: 'Failed to fetch orders' });
  }
});

// Create order
app.post('/orders', async (req, res) => {
  const { product_id, quantity } = req.body;

  try {
    // Check product availability
    const productResponse = await axios.get(`${PRODUCT_SERVICE_URL}/products/${product_id}`);
    const product = productResponse.data;

    if (product.stock < quantity) {
      return res.status(400).json({ error: 'Insufficient stock' });
    }

    const total_price = product.price * quantity;

    // Create order
    const result = await pool.query(
      'INSERT INTO orders (product_id, quantity, total_price) VALUES ($1, $2, $3) RETURNING *',
      [product_id, quantity, total_price]
    );

    res.status(201).json(result.rows[0]);
  } catch (error) {
    console.error('Error:', error);
    res.status(500).json({ error: 'Failed to create order' });
  }
});

app.listen(PORT, () => {
  console.log(`Order service running on port ${PORT}`);
});
```

**File: `services/order-service/Dockerfile`**
```dockerfile
FROM node:18-alpine

WORKDIR /app

COPY package*.json ./
RUN npm ci --only=production

COPY . .

EXPOSE 8001

HEALTHCHECK --interval=30s --timeout=3s --start-period=40s \
  CMD node -e "require('http').get('http://localhost:8001/health', (r) => {process.exit(r.statusCode === 200 ? 0 : 1)})"

CMD ["node", "server.js"]
```

---

## 🐳 DOCKER COMPOSE (Local Testing)

**File: `docker-compose.yml`**
```yaml
version: '3.8'

services:
  postgres:
    image: postgres:15-alpine
    environment:
      POSTGRES_DB: ecommerce
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: password
    ports:
      - "5432:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U postgres"]
      interval: 10s
      timeout: 5s
      retries: 5

  product-service:
    build: ./services/product-service
    environment:
      DB_HOST: postgres
      DB_NAME: ecommerce
      DB_USER: postgres
      DB_PASSWORD: password
      DB_PORT: 5432
    ports:
      - "8000:8000"
    depends_on:
      postgres:
        condition: service_healthy
    healthcheck:
      test: ["CMD", "python", "-c", "import urllib.request; urllib.request.urlopen('http://localhost:8000/health')"]
      interval: 30s
      timeout: 10s
      retries: 3

  order-service:
    build: ./services/order-service
    environment:
      DB_HOST: postgres
      DB_NAME: ecommerce
      DB_USER: postgres
      DB_PASSWORD: password
      DB_PORT: 5432
      PRODUCT_SERVICE_URL: http://product-service:8000
    ports:
      - "8001:8001"
    depends_on:
      postgres:
        condition: service_healthy
      product-service:
        condition: service_healthy

  frontend:
    build: ./services/frontend
    environment:
      PRODUCT_SERVICE_URL: http://product-service:8000
      ORDER_SERVICE_URL: http://order-service:8001
    ports:
      - "3000:3000"
    depends_on:
      - product-service
      - order-service

volumes:
  postgres_data:
```

---

## 🔧 TERRAFORM STARTER TEMPLATES

### Main Terraform Configuration

**File: `terraform/main.tf`**
```hcl
terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Uncomment after creating S3 bucket and DynamoDB table
  # backend "s3" {
  #   bucket         = "your-terraform-state-bucket"
  #   key            = "ecommerce/terraform.tfstate"
  #   region         = "us-east-1"
  #   encrypt        = true
  #   dynamodb_table = "terraform-state-lock"
  # }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "ecommerce-platform"
      Environment = var.environment
      ManagedBy   = "Terraform"
      Owner       = "YourName"
      CostCenter  = "Learning"
    }
  }
}

# Call modules
module "networking" {
  source = "./modules/networking"

  environment  = var.environment
  vpc_cidr     = var.vpc_cidr
  project_name = var.project_name
}

module "ecs" {
  source = "./modules/ecs"

  environment     = var.environment
  project_name    = var.project_name
  vpc_id          = module.networking.vpc_id
  public_subnets  = module.networking.public_subnet_ids
  private_subnets = module.networking.private_subnet_ids

  # Pass security group IDs
  alb_sg_id = module.networking.alb_sg_id
  ecs_sg_id = module.networking.ecs_sg_id
}

module "rds" {
  source = "./modules/rds"

  environment     = var.environment
  project_name    = var.project_name
  vpc_id          = module.networking.vpc_id
  private_subnets = module.networking.private_subnet_ids
  db_sg_id        = module.networking.db_sg_id

  db_name     = var.db_name
  db_username = var.db_username
  # Password should come from Secrets Manager
}

module "monitoring" {
  source = "./modules/monitoring"

  environment  = var.environment
  project_name = var.project_name

  # Pass resources to monitor
  alb_arn      = module.ecs.alb_arn
  ecs_cluster  = module.ecs.cluster_name
  db_instance  = module.rds.db_instance_id
}
```

**File: `terraform/variables.tf`**
```hcl
variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "project_name" {
  description = "Project name"
  type        = string
  default     = "ecommerce"
}

variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
  default     = "10.0.0.0/16"
}

variable "db_name" {
  description = "Database name"
  type        = string
  default     = "ecommerce"
}

variable "db_username" {
  description = "Database username"
  type        = string
  default     = "admin"
  sensitive   = true
}

variable "db_password" {
  description = "Database password"
  type        = string
  sensitive   = true
}
```

**File: `terraform/outputs.tf`**
```hcl
output "alb_dns_name" {
  description = "DNS name of the load balancer"
  value       = module.ecs.alb_dns_name
}

output "vpc_id" {
  description = "VPC ID"
  value       = module.networking.vpc_id
}

output "ecs_cluster_name" {
  description = "ECS cluster name"
  value       = module.ecs.cluster_name
}

output "db_endpoint" {
  description = "RDS endpoint"
  value       = module.rds.db_endpoint
  sensitive   = true
}

output "ecr_repositories" {
  description = "ECR repository URLs"
  value       = module.ecs.ecr_repositories
}
```

---

## 📋 ESSENTIAL COMMANDS CHEATSHEET

### AWS CLI Commands

```bash
# Configure AWS CLI
aws configure

# Check current identity
aws sts get-caller-identity

# List ECS clusters
aws ecs list-clusters

# List running tasks
aws ecs list-tasks --cluster your-cluster-name

# View CloudWatch logs
aws logs tail /ecs/product-service --follow

# Check current costs
aws ce get-cost-and-usage \
  --time-period Start=2024-01-01,End=2024-01-31 \
  --granularity MONTHLY \
  --metrics BlendedCost
```

### Terraform Commands

```bash
# Initialize Terraform
terraform init

# Format code
terraform fmt -recursive

# Validate configuration
terraform validate

# Plan changes
terraform plan -out=tfplan

# Apply changes
terraform apply tfplan

# Destroy infrastructure (CAREFUL!)
terraform destroy

# Show current state
terraform show

# List resources
terraform state list

# Import existing resource
terraform import aws_vpc.main vpc-12345678
```

### Docker Commands

```bash
# Build image
docker build -t product-service ./services/product-service

# Run container locally
docker run -p 8000:8000 product-service

# View logs
docker logs container-id

# Stop all containers
docker stop $(docker ps -aq)

# Remove all containers
docker rm $(docker ps -aq)

# Clean up images
docker system prune -a

# Build and run with docker-compose
docker-compose up --build

# Stop docker-compose
docker-compose down
```

### ECR Commands

```bash
# Authenticate to ECR
aws ecr get-login-password --region us-east-1 | \
  docker login --username AWS --password-stdin \
  123456789012.dkr.ecr.us-east-1.amazonaws.com

# Tag image for ECR
docker tag product-service:latest \
  123456789012.dkr.ecr.us-east-1.amazonaws.com/product-service:latest

# Push to ECR
docker push 123456789012.dkr.ecr.us-east-1.amazonaws.com/product-service:latest

# List images in ECR
aws ecr describe-images --repository-name product-service
```

### Git Commands

```bash
# Initial setup
git init
git add .
git commit -m "Initial commit"
git branch -M main
git remote add origin https://github.com/yourusername/aws-devops-ecommerce.git
git push -u origin main

# Create feature branch
git checkout -b feature/add-monitoring

# Commit changes
git add .
git commit -m "feat: add CloudWatch monitoring"

# Push branch
git push origin feature/add-monitoring

# Merge to main
git checkout main
git merge feature/add-monitoring
git push origin main
```

---

## 🧪 TESTING COMMANDS

### Test Locally

```bash
# Start all services
docker-compose up

# Test health endpoints
curl http://localhost:8000/health  # Product service
curl http://localhost:8001/health  # Order service
curl http://localhost:3000/health  # Frontend

# Test product service
curl http://localhost:8000/products

# Create a product
curl -X POST http://localhost:8000/products \
  -H "Content-Type: application/json" \
  -d '{"name":"Test Product","description":"Test","price":99.99,"stock":10}'

# Create an order
curl -X POST http://localhost:8001/orders \
  -H "Content-Type: application/json" \
  -d '{"product_id":1,"quantity":2}'
```

### Test on AWS

```bash
# Get ALB DNS name
ALB_DNS=$(terraform output -raw alb_dns_name)

# Test health endpoints
curl http://$ALB_DNS/products/health
curl http://$ALB_DNS/orders/health

# Test endpoints
curl http://$ALB_DNS/products
curl http://$ALB_DNS/orders
```

---

## 🚀 DEPLOYMENT WORKFLOW

### First Deployment

```bash
# 1. Build and test locally
docker-compose up --build
# Test all endpoints
docker-compose down

# 2. Deploy infrastructure
cd terraform
terraform init
terraform plan -out=tfplan
terraform apply tfplan

# 3. Build and push Docker images
aws ecr get-login-password --region us-east-1 | \
  docker login --username AWS --password-stdin YOUR_ACCOUNT.dkr.ecr.us-east-1.amazonaws.com

# Build and push each service
docker build -t product-service ./services/product-service
docker tag product-service:latest YOUR_ACCOUNT.dkr.ecr.us-east-1.amazonaws.com/product-service:latest
docker push YOUR_ACCOUNT.dkr.ecr.us-east-1.amazonaws.com/product-service:latest

# 4. Wait for ECS to pull and deploy
aws ecs wait services-stable --cluster ecommerce-cluster --services product-service

# 5. Test
ALB_DNS=$(terraform output -raw alb_dns_name)
curl http://$ALB_DNS/products/health
```

### Subsequent Deployments

```bash
# Option 1: Manual
docker build -t product-service ./services/product-service
docker push YOUR_ACCOUNT.dkr.ecr.us-east-1.amazonaws.com/product-service:v1.1
aws ecs update-service --cluster ecommerce-cluster --service product-service --force-new-deployment

# Option 2: GitHub Actions (automatic on push to main)
git add .
git commit -m "feat: add new feature"
git push origin main
# GitHub Actions handles the rest
```

---

## 📊 MONITORING COMMANDS

```bash
# View CloudWatch Logs
aws logs tail /ecs/product-service --follow

# Get service status
aws ecs describe-services \
  --cluster ecommerce-cluster \
  --services product-service

# View running tasks
aws ecs list-tasks \
  --cluster ecommerce-cluster \
  --service-name product-service

# Check ALB target health
aws elbv2 describe-target-health \
  --target-group-arn YOUR_TARGET_GROUP_ARN

# View CloudWatch metrics
aws cloudwatch get-metric-statistics \
  --namespace AWS/ECS \
  --metric-name CPUUtilization \
  --dimensions Name=ServiceName,Value=product-service Name=ClusterName,Value=ecommerce-cluster \
  --start-time 2024-01-01T00:00:00Z \
  --end-time 2024-01-02T00:00:00Z \
  --period 3600 \
  --statistics Average
```

---

## 💰 COST MONITORING COMMANDS

```bash
# Get month-to-date costs
aws ce get-cost-and-usage \
  --time-period Start=$(date -u -d '1 day ago' +%Y-%m-01),End=$(date -u +%Y-%m-%d) \
  --granularity MONTHLY \
  --metrics BlendedCost \
  --group-by Type=SERVICE

# Get daily costs
aws ce get-cost-and-usage \
  --time-period Start=$(date -u -d '7 days ago' +%Y-%m-%d),End=$(date -u +%Y-%m-%d) \
  --granularity DAILY \
  --metrics BlendedCost

# Get cost by tag
aws ce get-cost-and-usage \
  --time-period Start=$(date -u -d '1 day ago' +%Y-%m-01),End=$(date -u +%Y-%m-%d) \
  --granularity MONTHLY \
  --metrics BlendedCost \
  --group-by Type=TAG,Key=Project
```

---

## 🧹 CLEANUP COMMANDS

### Tear Down Everything (To Stop Costs)

```bash
# Stop ECS services (keeps infrastructure)
aws ecs update-service --cluster ecommerce-cluster --service product-service --desired-count 0
aws ecs update-service --cluster ecommerce-cluster --service order-service --desired-count 0
aws ecs update-service --cluster ecommerce-cluster --service frontend --desired-count 0

# Destroy all infrastructure (CAREFUL!)
cd terraform
terraform destroy

# Delete ECR images (to save storage costs)
aws ecr batch-delete-image \
  --repository-name product-service \
  --image-ids imageTag=latest

# Empty S3 buckets (required before deletion)
aws s3 rm s3://your-bucket-name --recursive
```

---

## 🎯 NEXT STEPS

1. Copy the code templates above to your project
2. Test locally with `docker-compose up`
3. Verify all health endpoints return 200
4. Commit to Git
5. Start building Terraform modules (Week 2)

**Tomorrow, when you check in, tell me:**
- "I tested the services locally"
- "All health checks passed"
- "My current blocker is: ___"

Then we'll move to deploying infrastructure with Terraform.