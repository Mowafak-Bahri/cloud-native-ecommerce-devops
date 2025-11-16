# Cloud-Native E-Commerce Platform Architecture

## 1. System Overview

```
                +---------------------------+
                |        CloudFront         |
                +-------------+-------------+
                              |
                        +-----v------+
                        |    ALB     |
          +-------------+-----+------+---------------+
          |                   |                      |
   /products/*          /orders/*                 /* default
          |                   |                      |
  +-------v------+    +-------v------+       +-------v------+
  | Product Farg.|    |  Order Farg. |       | Frontend    |
  |  Service     |    |   Service    |       |  Service    |
  +-------+------+    +-------+------+       +-------+------+
          |                   |                      |
          +-----------+-------+                      |
                      |                              |
             +--------v--------+             +-------v--------+
             |  RDS PostgreSQL |<------------+ Product/Order  |
             +--------+--------+             +----------------+
                      |
             +--------v--------+
             |  CloudWatch &   |
             |    X-Ray        |
             +-----------------+
```

The platform exposes three containerized microservices running on AWS Fargate (product, order, frontend) behind a public Application Load Balancer. PostgreSQL on Amazon RDS stores product and order data. CloudWatch, X-Ray, and SNS provide observability and alerting. Terraform provisions networking, security, container infrastructure, and supporting AWS services, while GitHub Actions automates builds, scanning, and deployments.

## 2. Component Descriptions

- **Frontend Service (Node.js Express):** Lightweight API gateway that aggregates product and order data for clients. Runs on port 3000 and proxies calls to backend services.
- **Product Service (FastAPI):** Manages product catalog CRUD operations backed by PostgreSQL. Seeds demo data on startup and exposes REST endpoints.
- **Order Service (Node.js Express):** Validates stock levels via the Product Service before inserting orders into PostgreSQL. Uses pg connection pooling.
- **PostgreSQL (Amazon RDS):** Central relational database residing in private subnets with encryption at rest and daily backups.
- **Application Load Balancer:** Provides TLS termination (optional), shared entry point, and path-based routing to each service.
- **AWS Fargate + ECS:** Runs containers in private subnets with security group isolation and auto-healing deployments.
- **ECR Repositories:** Store versioned Docker images with scan-on-push and lifecycle policies.
- **CloudWatch + X-Ray:** Collect logs, metrics, alarms, distributed traces, and dashboards.
- **GitHub Actions:** CI/CD workflows for Terraform plans/applies and Docker build, scan, and ECS deploy.

## 3. Network Flow

```
Internet
   |
   v
[Route53] -> [ALB SG] -> [ALB in Public Subnets]
                               |
                               v
                +--------------+--------------+
                | Path-based routing rules    |
                +--------------+--------------+
                               |
                +--------------+--------------+
                |  ECS Tasks in Private Subnets|
                +--------------+--------------+
                               |
                               v
                        [RDS Security Group]
                        [PostgreSQL Instance]
```

- Public subnets host the ALB and NAT gateway.
- Private subnets host ECS tasks with outbound-only internet via NAT for patching/X-Ray.
- Security groups ensure only ALB can reach ECS ports (8000-8002) and only ECS can reach PostgreSQL (5432).

## 4. Data Flow

1. Client fetches `/products` through the frontend service or directly via ALB path `/products/*`.
2. Product service queries PostgreSQL via the connection pool.
3. Order creation posts to `/orders`, which calls product service to validate stock before inserting into PostgreSQL with calculated totals.
4. Responses return to clients via ALB. Logs/metrics stream to CloudWatch, and traces propagate with AWS X-Ray across HTTP calls and database operations.

## 5. Security Architecture

- **Network Segmentation:** Dedicated VPC, separate public/private subnets per AZ, NAT gateway for egress, no public IPs on ECS tasks or RDS.
- **Security Groups:** ALB SG permits 80/443 from the internet. ECS SG only accepts traffic from ALB SG on app ports. RDS SG only allows ECS SG on 5432.
- **Encryption:** RDS storage encrypted (KMS default). Secrets stored in AWS Secrets Manager. HTTPS recommended on ALB with ACM certificates.
- **IAM:** Least-privilege IAM roles for ECS tasks (image pulls, logging) and CI/CD workflows.
- **Secrets Management:** DB password generated randomly and exposed to tasks through Secrets Manager references.
- **Observability Security:** CloudWatch log groups with 7-day retention and access via IAM. SNS alarm notifications restricted to authorized emails.

## 6. Scalability Considerations

- Horizontal scaling via ECS service auto-scaling (CPU/memory or request-based policies).
- Stateless services allow multiple tasks per service and multi-AZ placement.
- ALB handles path routing and scales automatically with request load.
- PostgreSQL can scale vertically (instance size) or horizontally via read replicas for analytics.
- Caching (e.g., ElastiCache) can be added between frontend/order services and product data for read-heavy workloads.

## 7. High Availability

- Three public and three private subnets across distinct Availability Zones.
- ALB deployed across all public subnets with health checks and deregistration delays.
- ECS services use minimum healthy percentages plus Fargate-managed auto-restarts.
- RDS Multi-AZ disabled for dev but supported by simply toggling the module variable for higher tiers.
- Docker images stored redundantly in ECR with scanning and lifecycle cleanup.

## 8. Cost Breakdown (Monthly Rough Order)

| Component                   | Estimated Monthly Cost (USD) |
|----------------------------|------------------------------|
| Fargate (3 tasks, 0.5 vCPU)| $60                          |
| Application Load Balancer  | $18                          |
| NAT Gateway + Data         | $40                          |
| RDS db.t4g.micro           | $33                          |
| CloudWatch Logs & Metrics  | $8                           |
| ECR Storage & Scans        | $5                           |
| Data Transfer (public)     | $10                          |
| **Total**                  | **~$174**                    |

Assumptions: dev-sized workloads (1 task/service), us-east-1 pricing, 730 hours/month. Costs rise linearly with task count, NAT data, and ALB traffic. Use auto-scaling, Fargate Spot, and aggressive log retention to control spend in higher environments.
