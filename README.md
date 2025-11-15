# Cloud-Native E-Commerce Platform - AWS Reference Implementation
![Terraform](https://img.shields.io/badge/Terraform-1.5+-623CE4?logo=terraform) ![AWS](https://img.shields.io/badge/AWS-ECS%20Fargate-FF9900?logo=amazonaws) ![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)

Production-grade reference implementation of a containerized e-commerce platform showcasing modern DevOps automation on AWS.

This implementation demonstrates how to operate a three-tier microservices architecture on AWS ECS Fargate using Terraform, GitHub Actions, and Docker. Infrastructure as Code, automated CI/CD, and operational excellence practices are applied to highlight repeatable enterprise patterns.

## Architecture Overview
The platform adopts a three-tier microservices topology with an internet-facing frontend, stateless API services, and a managed PostgreSQL data layer. Services run on AWS Fargate tasks within an ECS cluster, fronted by an Application Load Balancer. Terraform defines every component, and GitHub Actions pipelines provision infrastructure, build images, run tests, and deploy container revisions. Production-ready patterns such as blue/green deployments, auto-scaling, and automated rollbacks are modeled to reflect real-world operations.

## Features
- Containerized microservices deployed on AWS ECS Fargate with automated scaling policies.
- Infrastructure as Code managed through Terraform modules and environments.
- GitHub Actions pipelines for linting, unit tests, integration tests, and progressive deployments.
- Secure Postgres data layer provisioned via Amazon RDS with automated backups and encryption.
- Continuous delivery workflow including docker image builds, vulnerability scanning, and canary promotions.
- CloudWatch Logs, Metrics, and AWS X-Ray for centralized logging, metrics, and distributed tracing.
- AWS WAF-ready Application Load Balancer configuration with TLS termination and HTTP/2 support.
- Secrets managed through AWS Secrets Manager and injected via task definitions.
- IAM least-privilege roles for services, GitHub OIDC federation for CI, and Terraform state locking via DynamoDB/S3.
- Cost-optimization guardrails such as scheduled scaling, spot-eligible dev environments, and resource tagging.
- Automated drift detection and Terraform plan reporting inside pull requests.
- Security scanning through CodeQL, Trivy, and tfsec integrated into the pipeline.

## Architecture Components
**Compute**
- Amazon ECS on Fargate cluster hosting three services: frontend, product-service, order-service.
- Application Load Balancer distributing traffic with listener rules per service.
- Auto-scaling policies based on CPU, memory, and custom CloudWatch metrics.

**Data**
- Amazon RDS for PostgreSQL with Multi-AZ, encryption at rest, and automated backups.
- AWS Secrets Manager for connection strings, API keys, and third-party credentials.

**Networking**
- Dedicated VPC with public and private subnets across multiple AZs.
- NAT Gateways for egress, security groups enforcing least-privilege ingress, and VPC Flow Logs.
- Route 53 hosted zone with DNS records for public endpoints.

**Observability**
- Amazon CloudWatch Logs, metrics dashboards, alarms, and log retention policies.
- AWS X-Ray for distributed tracing across services.
- AWS CloudTrail for API auditing and S3-backed access logs from the ALB.

**Security**
- IAM roles scoped to tasks, Terraform, and CI workflows.
- AWS WAF-ready ALB integration and Shield protections.
- S3 + KMS for Terraform state encryption, parameterized security groups, and adherence to CIS benchmarks.

## Technology Stack
| Category                | Technologies                                            |
|-------------------------|---------------------------------------------------------|
| Container Orchestration | AWS ECS on Fargate, Docker                              |
| Infrastructure          | Terraform, AWS CLI, GitHub Actions OIDC, tfenv          |
| Database                | Amazon RDS for PostgreSQL, AWS Secrets Manager          |
| CI/CD                   | GitHub Actions workflows, docker buildx, Terraform Cloud|
| Monitoring              | Amazon CloudWatch, AWS X-Ray, CloudTrail, AWS Config    |
| Security                | IAM, AWS WAF, AWS Shield, Trivy, CodeQL, tfsec          |

## Quick Start
**Prerequisites:** AWS CLI v2, Terraform v1.5+, Docker 20+, GitHub Actions access.

1. Clone the repository and review `docs/architecture.md`.
2. Authenticate with AWS (profile or SSO) and export the target workspace variables.
3. Run `terraform init` and `terraform apply` within `infra/environments/<env>`.
4. Trigger the GitHub Actions workflow or run `scripts/deploy.sh <env>` to deploy services.
Refer to `docs/getting-started.md` for environment-specific instructions.

## Project Structure
```
.
├── README.md
├── infra/
│   ├── modules/
│   └── environments/
├── services/
│   ├── frontend/
│   ├── product-service/
│   └── order-service/
├── docs/
├── .github/workflows/
├── scripts/
└── tests/
```
- `infra/` Terraform modules and environment definitions.
- `services/` application microservices (Node.js frontend, FastAPI product service, Node.js order service).
- `docs/` architecture diagrams, runbooks, and ADRs.
- `.github/workflows/` CI/CD automation pipelines.
- `scripts/` helper automation and local tooling.
- `tests/` integration, contract, and performance test suites.

## Documentation
- [CONTRIBUTING.md](CONTRIBUTING.md) – contribution workflow and coding standards.
- [SECURITY.md](SECURITY.md) – security policy, reporting procedures, and best practices.
- [docs/](docs/) – architecture guides, operations procedures, and environment-specific notes.
- [docs/adr/](docs/adr/) – Architecture Decision Records for major changes.
- [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md) – community expectations.

## Cost Considerations
Deployments run on AWS using cost-optimized defaults such as on-demand sizing, auto-scaling schedules, and observability retention policies. Typical non-production environments operate between $30–$50 per month when idle scaling and tagging policies are applied. See `docs/cost-management.md` for calculators and optimization strategies.

## Security
Security practices include IAM least-privilege roles, secrets isolation, network segmentation, encryption at rest/in transit, and automated scanning in CI/CD. Refer to `SECURITY.md` for disclosure procedures, deployment checklists, and defense-in-depth details.

## License
Released under the [MIT License](LICENSE).
