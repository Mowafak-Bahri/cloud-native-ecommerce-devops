# 🎯 AWS DevOps Portfolio Project - Master Plan
## "Cloud-Native E-Commerce Platform with Complete DevOps Pipeline"

**Your Supervisor AI Agent:** Senior DevOps Architect & FinOps Expert
**Timeline:** 1 Month (4 Weeks)
**Goal:** Land a Cloud/DevOps job
**Stack:** AWS Free Tier + ChatGPT Plus + Claude Pro + Gemini Free

---

## 📋 EXECUTIVE SUMMARY

### What You're Building
A **production-grade, containerized microservices e-commerce platform** deployed on AWS with complete CI/CD, monitoring, and cost optimization.

### Why This Project Will Get You Hired
✅ Demonstrates **ALL** skills employers want:
- Infrastructure as Code (Terraform)
- Container orchestration (ECS Fargate)
- CI/CD automation (GitHub Actions)
- Monitoring & observability (CloudWatch, X-Ray)
- Security best practices (IAM, Secrets Manager, Security Groups)
- Cost optimization (FinOps practices)
- High availability & scalability
- Real-world microservices architecture

✅ **Stays within AWS Free Tier** (with proper monitoring)
✅ **Portfolio-ready** with documentation
✅ **Interview talking points** at every layer
✅ **AWS certification prep** (covers 70% of SAA/SOA exam topics)

---

## 💰 FINOPS ALERT: COST BREAKDOWN

### Free Tier Resources (12 months)
- **EC2 (ECS Fargate):** 20GB/month free tier + pay-per-use
- **ALB:** $18/month (NOT free - but essential)
- **RDS t4g.micro:** 750 hours/month free (= always on)
- **S3:** 5GB storage, 20K GET, 2K PUT requests
- **CloudWatch:** 10 custom metrics, 5GB logs
- **ECR:** 500MB storage/month
- **Lambda:** 1M requests/month free
- **CloudFormation:** Free
- **Systems Manager:** Free for parameter store (basic)

### **CRITICAL - Monthly Cost Estimate**
- **Minimum:** $18-25/month (ALB + small overages)
- **Typical:** $30-40/month (with moderate testing)
- **Maximum:** $60/month (if you go wild with testing)

### **Cost Control Strategy**
1. **Set AWS Budget Alerts** at $25, $35, $50
2. **Tear down after hours** (automate with Lambda)
3. **Use Fargate Spot** for non-prod (70% cheaper)
4. **Monitor daily** with Cost Explorer
5. **Delete resources** you're not actively using

### **Real-World Context**
In a company, this architecture would cost $500-1500/month. Your goal is to demonstrate you understand:
- How to architect efficiently
- Cost-benefit trade-offs
- Resource right-sizing
- FinOps monitoring practices

**You're learning to be a COST-CONSCIOUS DevOps engineer** - this is what separates juniors from seniors.

---

## 🏗️ PROJECT ARCHITECTURE

### The Application (What You're Deploying)

```
┌─────────────────────────────────────────────────────────────────┐
│                        Internet Gateway                         │
└───────────────────────────────┬─────────────────────────────────┘
                                │
                    ┌───────────▼──────────┐
                    │  Application Load    │
                    │     Balancer         │
                    │   (Multi-AZ)         │
                    └───────────┬──────────┘
                                │
          ┌─────────────────────┼─────────────────────┐
          │                     │                     │
    ┌─────▼──────┐      ┌──────▼─────┐      ┌───────▼──────┐
    │  Frontend  │      │  Product   │      │   Order      │
    │  Service   │──────▶  Service   │◀─────│  Service     │
    │  (ECS)     │      │  (ECS)     │      │   (ECS)      │
    └────────────┘      └─────┬──────┘      └──────┬───────┘
                              │                    │
                        ┌─────▼────────────────────▼─────┐
                        │    Amazon RDS PostgreSQL       │
                        │         (Multi-AZ)             │
                        └────────────────────────────────┘
```

### 3 Microservices

1. **Frontend Service** (Node.js/React)
   - Serves static website
   - Calls backend APIs
   - Health check endpoint

2. **Product Service** (Python/FastAPI)
   - CRUD operations for products
   - Database queries
   - Redis caching (optional)

3. **Order Service** (Node.js/Express)
   - Order processing
   - Inventory checks
   - Payment simulation

### Infrastructure Components

**Networking:**
- VPC with public/private subnets (3 AZs)
- Internet Gateway
- NAT Gateway (Conditional - cost vs security)
- Security Groups (principle of least privilege)

**Compute:**
- ECS Cluster (Fargate launch type)
- Task Definitions for each service
- Auto-scaling based on CPU/Memory

**Database:**
- RDS PostgreSQL (t4g.micro)
- Multi-AZ for HA
- Automated backups
- Parameter groups

**Load Balancing:**
- Application Load Balancer
- Target groups per service
- Health checks
- SSL/TLS termination (ACM certificate)

**Storage:**
- S3 bucket for static assets
- S3 bucket for logs
- ECR for Docker images

**Monitoring:**
- CloudWatch Logs (all services)
- CloudWatch Metrics
- CloudWatch Alarms
- X-Ray for distributed tracing
- CloudWatch Dashboard

**Security:**
- IAM roles (task execution, task role)
- Secrets Manager (DB passwords, API keys)
- Security Groups (restrictive rules)
- AWS Systems Manager Parameter Store

**CI/CD:**
- GitHub Actions workflows
- Terraform for IaC
- Docker for containerization
- Automated testing
- Blue-green deployments

---

## 🗓️ 4-WEEK IMPLEMENTATION PLAN

### **Week 1: Foundation & Local Development**
**Goal:** Learn the basics, set up local environment, understand the architecture

#### **Day 1-2: Environment Setup & Learning**
**Your Tasks:**
1. Create AWS account (if you don't have one)
2. Set up billing alerts ($25, $35, $50)
3. Install AWS CLI, configure credentials
4. Install Terraform, Docker, Git
5. Create GitHub repository

**How to Use Your AI Tools:**
- **ChatGPT Plus:** "Explain the difference between ECS Fargate and EC2. When would I use each in a real company?"
- **Gemini Free:** "Create a comparison table of AWS container services (ECS, EKS, Fargate). Include cost, complexity, and use cases."
- **Claude Pro:** "I'm learning DevOps. Explain what Infrastructure as Code is, why companies use Terraform over ClickOps, and what the alternatives are."

**Real-World Context:**
- **Why Terraform?** Companies use IaC to ensure reproducibility, version control, and collaboration. ClickOps (manual console work) leads to drift, errors, and is not scalable.
- **Why ECS Fargate over EKS?** EKS costs $0.10/hour ($73/month) just for the control plane. Fargate is serverless (pay per task) and free-tier eligible. For small teams, Fargate is preferred unless you need Kubernetes-specific features.
- **Why Multi-AZ?** In production, if one availability zone fails, your app stays online. This is critical for SLAs.

**FinOps Question:** "What is the cost implication of running NAT Gateway vs NAT Instance vs no NAT?"
- **NAT Gateway:** $32/month + data transfer (managed, highly available)
- **NAT Instance:** t3.nano $3.80/month + data transfer (you manage it, single point of failure)
- **No NAT:** $0 (but private subnets can't reach internet for updates)
- **Decision:** For learning, we'll document both options. In production, NAT Gateway for HA, cost vs risk trade-off.

---

#### **Day 3-4: Build the Application Locally**
**Your Tasks:**
1. Create 3 microservices (code provided below)
2. Dockerize each service
3. Test locally with docker-compose
4. Set up GitHub repository structure

**Folder Structure:**
```
aws-devops-ecommerce/
├── services/
│   ├── frontend/
│   │   ├── Dockerfile
│   │   ├── package.json
│   │   └── src/
│   ├── product-service/
│   │   ├── Dockerfile
│   │   ├── requirements.txt
│   │   └── app/
│   └── order-service/
│       ├── Dockerfile
│       ├── package.json
│       └── src/
├── terraform/
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   ├── modules/
│   │   ├── networking/
│   │   ├── ecs/
│   │   ├── rds/
│   │   └── monitoring/
├── .github/
│   └── workflows/
│       ├── terraform.yml
│       ├── build-deploy.yml
│       └── cost-report.yml
├── docs/
│   ├── architecture.md
│   ├── runbook.md
│   └── cost-optimization.md
├── scripts/
│   ├── setup.sh
│   ├── teardown.sh
│   └── deploy.sh
└── docker-compose.yml
```

**How to Use Your AI Tools:**
- **Claude Pro:** "I need to create a simple FastAPI microservice for managing products (CRUD operations). It should include: health check endpoint, Dockerfile, PostgreSQL connection, basic error handling. Write the code with production best practices."
- **ChatGPT Plus:** "Review this Dockerfile for security vulnerabilities and suggest improvements: [paste your Dockerfile]"
- **Gemini Free:** "Create a docker-compose.yml file for 3 services: frontend (node:18), product-service (python:3.11), order-service (node:18), and PostgreSQL database with health checks."

**Real-World Context:**
- **Why Microservices?** Companies split apps into services for independent scaling, deployment, and team ownership. A product team can deploy without waiting for the orders team.
- **Why Docker?** Ensures consistency between dev, staging, and prod. "Works on my machine" is eliminated.
- **Why Health Checks?** Load balancers need to know if a container is healthy. Unhealthy containers get replaced automatically.

**FinOps Question:** "What is the cost implication of running 3 microservices vs 1 monolith on ECS?"
- **3 Microservices:** 3 Fargate tasks (can scale independently) - more resources at baseline
- **1 Monolith:** 1 Fargate task (simpler) - less resources, but scales everything together
- **Trade-off:** Microservices cost more at low scale but save money at high scale (scale only what's needed). For learning, we use microservices to demonstrate modern architecture.

---

#### **Day 5-7: Learn Terraform & Plan Infrastructure**
**Your Tasks:**
1. Complete Terraform basics tutorial (Terraform.io)
2. Write Terraform modules for:
   - VPC & Networking
   - ECS Cluster
   - RDS Database (save for Week 2)
3. Understand state management (S3 backend)
4. Plan cost with terraform plan

**How to Use Your AI Tools:**
- **Claude Pro:** "I need a Terraform module for AWS VPC with 3 public subnets, 3 private subnets, internet gateway, and route tables. Follow AWS best practices and include detailed comments explaining each resource."
- **ChatGPT Plus:** "Explain Terraform state files. Why should I store state in S3 with DynamoDB locking? What happens if I don't?"
- **Gemini Free:** "Create a Terraform variables.tf file for an AWS ECS project. Include: environment (dev/prod), region, instance sizes, database config with sensitive values properly marked."

**Real-World Context:**
- **Why Terraform Modules?** Reusability and consistency. In a company, the platform team creates VPC modules, and app teams use them. Everyone gets the same secure network.
- **Why S3 State Backend?** Multiple team members need access to the same state. Local state files lead to conflicts and accidental infrastructure destruction.
- **Why State Locking (DynamoDB)?** Prevents two people from running terraform apply simultaneously and corrupting state.

**FinOps Question:** "What is the cost implication of using t4g (ARM) vs t3 (x86) for RDS?"
- **t4g.micro:** $0.014/hour = $10.08/month (750 hours free tier)
- **t3.micro:** $0.018/hour = $12.96/month (750 hours free tier)
- **Savings:** 20% cheaper with ARM (Graviton2). Caveat: Check application compatibility.
- **Decision:** Use t4g for learning + cost savings. In production, test performance first.

---

### **Week 2: Deploy to AWS (Infrastructure)**
**Goal:** Get infrastructure running on AWS, understand AWS services hands-on

#### **Day 8-9: Deploy Core Infrastructure**
**Your Tasks:**
1. Set up Terraform S3 backend
2. Deploy VPC, subnets, internet gateway
3. Deploy security groups
4. Deploy ECR repositories
5. Verify in AWS Console

**How to Use Your AI Tools:**
- **ChatGPT Plus:** "I'm getting a Terraform error: [paste error]. Explain what this means and how to fix it."
- **Claude Pro:** "Review my Terraform security group rules for an ECS application. Are they too permissive? Suggest improvements based on principle of least privilege."
- **Gemini Free:** "Create a Terraform output.tf file that outputs: VPC ID, subnet IDs, security group IDs, ECR repository URLs."

**Real-World Context:**
- **Why Separate Public/Private Subnets?** Defense in depth. Databases go in private subnets (no internet access), only ALB in public subnets. If ALB is compromised, attacker still can't reach database directly.
- **Why Security Groups vs NACLs?** Security groups are stateful (return traffic allowed automatically) and easier to manage. NACLs are stateless and act as an additional layer. Most companies only use security groups for simplicity.

**FinOps Question:** "What is the cost implication of NAT Gateway per AZ?"
- **1 NAT Gateway:** $32/month + data transfer
- **3 NAT Gateways (HA):** $96/month + data transfer
- **Trade-off:** High availability vs cost. For learning, use 1. In production, use 3 (or NAT instance for cost-sensitive startups).
- **Your Decision:** Document why you chose 1, what the prod architecture would be.

---

#### **Day 10-11: Deploy RDS & ECS Cluster**
**Your Tasks:**
1. Deploy RDS PostgreSQL (t4g.micro)
2. Deploy ECS Cluster (Fargate)
3. Set up CloudWatch Log Groups
4. Store DB credentials in Secrets Manager
5. Test database connectivity

**How to Use Your AI Tools:**
- **Claude Pro:** "Create Terraform code for RDS PostgreSQL with these requirements: t4g.micro, multi-AZ disabled (cost savings), automated backups, parameter group for performance tuning, private subnet placement, security group restricting access to ECS only."
- **ChatGPT Plus:** "What is the difference between ECS Task Execution Role vs ECS Task Role? When do I need each?"
- **Gemini Free:** "Create a Terraform module for AWS Secrets Manager to store: database password, API keys. Include IAM policy for ECS tasks to read these secrets."

**Real-World Context:**
- **Why Multi-AZ for RDS?** In production, yes (automatic failover = ~60s downtime). For learning, you can disable to save 2x cost. For job interviews, explain you'd enable in prod.
- **Why Secrets Manager vs Parameter Store?** Secrets Manager has automatic rotation and cross-account access. Parameter Store (free tier) is fine for simple secrets. In production, use Secrets Manager for databases, Parameter Store for config.
- **Why Fargate vs EC2?** No server management, pay per task, scales to zero. EC2 is cheaper at scale (when you have many tasks running 24/7) but requires cluster management.

**FinOps Question:** "What is the cost implication of RDS Multi-AZ?"
- **Single-AZ:** $10/month (t4g.micro, free tier)
- **Multi-AZ:** $20/month (exact double)
- **Trade-off:** High availability vs cost. For dev/staging, single-AZ is fine. For production, multi-AZ is mandatory (SLA requirements).
- **Your Decision:** Single-AZ for learning, document the prod configuration would be multi-AZ.

---

#### **Day 12-14: Deploy Application to ECS**
**Your Tasks:**
1. Build Docker images locally
2. Push images to ECR
3. Create ECS Task Definitions
4. Create ECS Services
5. Deploy Application Load Balancer
6. Configure target groups & health checks
7. Test application end-to-end

**How to Use Your AI Tools:**
- **Claude Pro:** "Create an ECS Task Definition in Terraform for a FastAPI service with these requirements: Fargate, 0.5 vCPU, 1GB RAM, CloudWatch logs, environment variables from Parameter Store, secrets from Secrets Manager, health check on /health."
- **ChatGPT Plus:** "My ECS task is failing health checks and restarting. Here are the CloudWatch logs: [paste logs]. Diagnose the issue."
- **Gemini Free:** "Create a GitHub Actions workflow to: build Docker image, tag with git SHA, push to ECR, update ECS service. Include proper AWS authentication."

**Real-World Context:**
- **Why Task Definitions?** They're like Kubernetes pods - define the container(s), resources, environment variables, IAM roles. Version controlled, can rollback.
- **Why ALB vs NLB vs CLB?** ALB is Layer 7 (HTTP/HTTPS), best for microservices (path-based routing). NLB is Layer 4 (TCP), for high performance. CLB is legacy. Almost always use ALB for web apps.
- **Why Health Checks?** ECS automatically replaces unhealthy tasks. Without health checks, broken containers stay running and users get errors.

**FinOps Question:** "What is the cost implication of ALB idle timeout settings?"
- **ALB Base Cost:** $0.0225/hour = $16.20/month + $0.008/LCU-hour
- **Optimization:** Use single ALB for all services (path-based routing) instead of ALB per service
- **3 ALBs:** $48.60/month, **1 ALB:** $16.20/month
- **Your Decision:** Use 1 ALB with path-based routing (/products → product-service, /orders → order-service). Explain this in interview.

---

### **Week 3: CI/CD, Monitoring & Security**
**Goal:** Automate deployments, add observability, implement security

#### **Day 15-16: GitHub Actions CI/CD**
**Your Tasks:**
1. Create GitHub Actions workflow for Terraform
2. Create GitHub Actions workflow for Docker build + deploy
3. Set up GitHub secrets (AWS credentials)
4. Implement blue-green deployment strategy
5. Test automated deployment

**How to Use Your AI Tools:**
- **Claude Pro:** "Create a production-ready GitHub Actions workflow for deploying to AWS ECS with these requirements: trigger on push to main, build Docker image, run tests, push to ECR, update ECS service, rollback on failure, send Slack notification. Include security best practices."
- **ChatGPT Plus:** "Explain the difference between blue-green deployment, rolling deployment, and canary deployment. Which should I use for ECS and why?"
- **Gemini Free:** "Create a GitHub Actions workflow for Terraform with these steps: checkout, setup Terraform, plan on PR, apply on merge to main, comment plan on PR. Include cost estimation with Infracost."

**Real-World Context:**
- **Why Automate Deployments?** Manual deployments lead to human error, inconsistency, and slow release cycles. In companies, deployments happen 10-100x/day with CI/CD.
- **Why Blue-Green?** Zero downtime deployments. New version runs alongside old, traffic switches after health checks pass. If new version fails, instant rollback.
- **Why Test in Pipeline?** Catch bugs before production. Unit tests, integration tests, security scans, linting. Shift-left mentality.

**FinOps Question:** "What is the cost implication of GitHub Actions minutes?"
- **GitHub Free:** 2,000 minutes/month free (Linux runners)
- **Typical Usage:** ~100-200 minutes/month for this project
- **Overage:** $0.008/minute = $0.48/hour
- **Optimization:** Use self-hosted runners (AWS EC2) if you have heavy usage, but for learning, free tier is plenty.
- **Alternative:** GitLab CI (400 minutes/month free), AWS CodePipeline + CodeBuild (100 minutes/month free)

---

#### **Day 17-18: Monitoring & Observability**
**Your Tasks:**
1. Set up CloudWatch Logs for all services
2. Create CloudWatch Dashboard
3. Set up CloudWatch Alarms (high CPU, errors, cost)
4. Implement AWS X-Ray tracing
5. Set up Cost Explorer & Budget alerts
6. Create runbook for common issues

**How to Use Your AI Tools:**
- **Claude Pro:** "Create a CloudWatch Dashboard in Terraform that shows: ECS CPU/Memory per service, ALB request count, ALB target response time, RDS CPU/connections, estimated daily cost. Include alarms for: CPU > 80%, 5xx errors > 10/min, daily cost > $2."
- **ChatGPT Plus:** "I need to implement distributed tracing with AWS X-Ray for my microservices. Explain how to instrument a FastAPI app and Node.js app. What are the costs?"
- **Gemini Free:** "Create a DevOps runbook template for: ECS task keeps restarting, RDS connections maxed out, high latency on ALB, sudden cost spike. Include diagnostic steps and resolution."

**Real-World Context:**
- **Why Observability?** You can't fix what you can't see. In production, when things break at 3 AM, you need metrics, logs, and traces to diagnose.
- **Why CloudWatch vs Datadog/New Relic?** CloudWatch is native, free tier eligible, integrates deeply with AWS. Datadog costs $15-30/host/month (better for multi-cloud). For AWS-only, CloudWatch is standard.
- **Why X-Ray?** Traces requests across microservices. When an order fails, you can see: frontend → product-service (120ms) → order-service (FAILED at DB query). Impossible to debug without tracing.

**FinOps Question:** "What is the cost implication of CloudWatch Logs retention?"
- **Storage:** $0.03/GB/month (after free tier: 5GB)
- **Typical Usage:** 1-3GB/month for this project
- **Cost:** ~$0.10/month
- **Optimization:** Set retention to 7 days for dev, 30 days for prod. Export to S3 ($0.023/GB/month) for long-term storage if needed.
- **Your Decision:** 7-day retention for learning, explain in interview you'd use 30-90 days in prod per compliance requirements.

---

#### **Day 19-21: Security Hardening**
**Your Tasks:**
1. Implement least-privilege IAM roles
2. Enable AWS WAF on ALB (optional - costs money)
3. Enable VPC Flow Logs (S3 destination)
4. Scan Docker images with Trivy/Snyk
5. Enable AWS Config (optional - costs money)
6. Implement secrets rotation (Secrets Manager)
7. Create security checklist documentation

**How to Use Your AI Tools:**
- **Claude Pro:** "Review my ECS Task Role IAM policy: [paste policy]. Is it following least privilege? What permissions are unnecessary? Suggest improvements and explain why."
- **ChatGPT Plus:** "Explain AWS security best practices for ECS applications. Include: IAM roles, secrets management, network security, image scanning, logging. For each, explain what the risk is and how to mitigate."
- **Gemini Free:** "Create a security checklist for AWS ECS deployments covering: IAM, networking, data encryption, secrets, logging, monitoring, compliance. Format as a markdown table with status column."

**Real-World Context:**
- **Why Least Privilege IAM?** If a container is compromised, attacker gets the task role permissions. Give only what's needed. For example, product-service needs RDS access, but NOT S3 or Secrets Manager (unless it uses them).
- **Why Image Scanning?** Public Docker images often have vulnerabilities (CVEs). Scan before deploying. In companies, this is automated in CI/CD - builds fail if critical CVEs found.
- **Why VPC Flow Logs?** Network forensics. If there's a breach, flow logs show who connected to what. Required for compliance (SOC2, PCI-DSS).

**FinOps Question:** "What is the cost implication of enabling AWS WAF?"
- **AWS WAF:** $5/month (per web ACL) + $1/million requests
- **Benefit:** Protects against common attacks (SQL injection, XSS)
- **Trade-off:** Essential for production, overkill for learning project (unless specifically demonstrating security)
- **Your Decision:** Document WAF configuration (don't enable to save cost), explain in interview you'd enable in prod with managed rule groups.

**FinOps Question 2:** "What is the cost implication of VPC Flow Logs?"
- **To CloudWatch:** $0.50/GB ingested
- **To S3:** $0.023/GB stored (cheaper)
- **Typical Usage:** 1-5GB/month
- **Cost:** $0.02-0.25/month (S3), $0.50-2.50/month (CloudWatch)
- **Your Decision:** Use S3 destination for cost savings. In prod, use CloudWatch for real-time analysis with Athena.

---

### **Week 4: Optimization, Documentation & Portfolio**
**Goal:** Optimize costs, create documentation, prepare for interviews

#### **Day 22-23: Cost Optimization & FinOps**
**Your Tasks:**
1. Analyze Cost Explorer (identify top spend)
2. Implement ECS Fargate Spot (dev environment)
3. Right-size Fargate tasks (reduce vCPU/memory)
4. Implement auto-scaling policies
5. Set up cost anomaly detection
6. Create cost optimization report
7. Implement automated tear-down schedule (Lambda)

**How to Use Your AI Tools:**
- **Claude Pro:** "I need a Lambda function that runs daily at 6 PM EST to: stop all ECS services in dev environment, create snapshot of RDS, tag resources with 'auto-stopped'. And another Lambda at 8 AM to start them. Include Terraform code for Lambda, EventBridge rules, IAM roles."
- **ChatGPT Plus:** "Explain AWS ECS auto-scaling strategies. What metrics should I scale on? What are the trade-offs between target tracking, step scaling, and scheduled scaling?"
- **Gemini Free:** "Create a cost optimization checklist for AWS with actual commands/links: review rightsizing recommendations, identify unused resources, check reserved instance opportunities, analyze S3 storage classes, review data transfer costs."

**Real-World Context:**
- **Why Auto-Scaling?** Companies scale based on traffic. E-commerce sites scale up for Black Friday, scale down at night. Auto-scaling saves money (FinOps) while ensuring performance.
- **Why Fargate Spot?** Up to 70% cheaper than on-demand. AWS can reclaim tasks with 2-minute warning. Perfect for dev/staging, batch jobs, stateless apps. For prod, use on-demand or mix (70% on-demand, 30% spot).
- **Why Scheduled Tear-Down?** Dev environments don't need to run 24/7. Shut down nights and weekends = 70% cost savings. In companies, dev environments run business hours only.

**FinOps Question:** "What is the cost implication of ECS Fargate Spot vs On-Demand?"
- **On-Demand:** $0.04048/vCPU/hour + $0.004445/GB/hour
- **Spot:** ~$0.012/vCPU/hour + ~$0.001/GB/hour (70% discount, varies)
- **Example:** 0.5 vCPU, 1GB, 24/7 = $15/month on-demand, $4.50/month spot
- **Risk:** Tasks can be interrupted with 2-min notice
- **Your Decision:** Use spot for dev/staging (document this decision), on-demand for prod. Show you understand cost vs reliability trade-off.

---

#### **Day 24-25: Documentation & Architecture Diagrams**
**Your Tasks:**
1. Create architecture diagram (draw.io, Lucidchart, or code with diagrams.net)
2. Write comprehensive README.md
3. Document runbook (troubleshooting guide)
4. Create cost breakdown document
5. Write "Lessons Learned" document
6. Create deployment guide
7. Write disaster recovery plan

**How to Use Your AI Tools:**
- **Claude Pro:** "I need a comprehensive README.md for my AWS DevOps portfolio project. Include: project overview, architecture, tech stack, setup instructions, deployment process, cost analysis, lessons learned, future improvements. Make it interview-ready."
- **ChatGPT Plus:** "Create a troubleshooting runbook for common ECS issues: task won't start, health checks failing, high latency, database connection issues, cost spike. For each, include: symptoms, diagnosis steps, resolution."
- **Gemini Free:** "Generate a disaster recovery plan template for an AWS ECS application covering: RTO/RPO targets, backup strategy, failover procedures, restore procedures, testing schedule, contact information."

**Real-World Context:**
- **Why Documentation?** In companies, documentation is critical for:
  - Onboarding new team members
  - Incident response (at 3 AM, you need a runbook)
  - Knowledge sharing (prevent silos)
  - Compliance (audit trails)
- **Why Architecture Diagrams?** A picture is worth 1,000 words. In interviews, you'll be asked to draw your architecture on a whiteboard. Practice now.
- **Why Runbooks?** When things break, you need step-by-step procedures. "Check CloudWatch Logs" is not enough. "Go to CloudWatch → Log Groups → /ecs/product-service → Search for 'ERROR' → Common errors and solutions" is actionable.

**Interview Prep:** For every component, know:
1. **What it does**
2. **Why you chose it** (vs alternatives)
3. **How it's configured**
4. **Cost implications**
5. **How you'd improve it**

---

#### **Day 26-28: Portfolio Prep & Interview Practice**
**Your Tasks:**
1. Record demo video (5-10 minutes)
2. Create portfolio website (optional: S3 static site)
3. Write blog post about the project
4. Update LinkedIn with project
5. Create interview talking points document
6. Practice explaining the project (rubber duck method)
7. Set up tear-down script (destroy infrastructure when done)

**How to Use Your AI Tools:**
- **Claude Pro:** "I'm interviewing for a DevOps role. Create interview Q&A based on my AWS ECS project. Include: architecture questions, troubleshooting scenarios, cost optimization, security, CI/CD, and behavioral questions. For each question, provide a strong answer with real examples from my project."
- **ChatGPT Plus:** "Review my project demo script and suggest improvements for clarity, technical depth, and storytelling: [paste script]"
- **Gemini Free:** "Create a portfolio website HTML page showcasing my AWS DevOps project. Include: hero section with architecture diagram, tech stack icons, key achievements (% cost savings, deployment frequency), challenges overcome, lessons learned, GitHub link, demo video embed."

**Real-World Context:**
- **Why Demo Video?** Hiring managers don't have time to deploy your project. A 5-minute video showing: architecture, live application, deployment process, monitoring dashboard, cost analysis is compelling.
- **Why Blog Post?** Demonstrates communication skills (critical for DevOps). Write about: "How I Built a Production-Grade AWS ECS Application on a Free Tier Budget" or "5 FinOps Lessons from Deploying Microservices on AWS".
- **Why Interview Talking Points?** You'll be asked: "Tell me about a project you're proud of." Have a structured answer: problem, solution, challenges, results, lessons learned.

**Interview Questions You Should Prepare For:**
1. "Walk me through your AWS architecture."
2. "How did you handle secrets management?"
3. "What challenges did you face with ECS, and how did you solve them?"
4. "How do you optimize AWS costs?"
5. "How does your CI/CD pipeline work?"
6. "How would you debug a service that's failing health checks?"
7. "How would you scale this to 1 million users?"
8. "What security measures did you implement?"
9. "How do you monitor application health?"
10. "If you could rebuild this, what would you change?"

---

## 🤖 AI AGENT COORDINATION STRATEGY

### How to Use Your Three AI Tools

**ChatGPT Plus** (Best for: quick answers, code generation, troubleshooting)
- Syntax questions: "What's the Terraform syntax for..."
- Error debugging: "I'm getting this error: [paste]. What's wrong?"
- Code snippets: "Generate a Python FastAPI endpoint for..."
- Comparisons: "Compare X vs Y for..."

**Claude Pro** (Best for: architecture, complex reasoning, comprehensive code)
- Architecture review: "Review my entire Terraform setup and suggest improvements"
- Long-form code: "Create a complete ECS module with..."
- Best practices: "Review my IAM policies for security issues"
- Documentation: "Write a comprehensive guide for..."
- Interview prep: "Generate interview questions based on..."

**Gemini Free** (Best for: research, tables, quick references)
- Cost comparisons: "Create a cost comparison table of..."
- Service comparisons: "Compare AWS services..."
- Checklists: "Generate a security checklist for..."
- Quick templates: "Create a basic Terraform template for..."

**When to Use Which:**
```
Simple question → Gemini (fast, free)
Code debugging → ChatGPT (good at error messages)
Architecture decisions → Claude (best reasoning)
Long-form content → Claude (best quality)
Quick comparisons → Gemini (good tables)
Code generation → ChatGPT or Claude (both excellent)
Cost analysis → Claude (FinOps focus) + Gemini (tables)
```

**Multi-Agent Workflow Example:**
1. **Gemini:** "Create a comparison table of AWS load balancers"
2. **Claude:** "Based on this comparison, design an ALB setup for 3 microservices with cost optimization"
3. **ChatGPT:** "Generate the Terraform code for the ALB setup Claude designed"
4. **Claude:** "Review this Terraform code for security issues"

---

## 📚 LEARNING RESOURCES

### AWS Certification Prep (Aligned with This Project)

**This project covers these exam topics:**

**SAA-C03 (Solutions Architect Associate):**
- ✅ Domain 1: Design Resilient Architectures (VPC, Multi-AZ, ALB)
- ✅ Domain 2: High-Performing Architectures (ECS, Fargate, auto-scaling)
- ✅ Domain 3: Secure Applications (IAM, Security Groups, Secrets Manager)
- ✅ Domain 4: Cost-Optimized Architectures (Fargate Spot, rightsizing, monitoring)

**SOA-C02 (SysOps Administrator Associate):**
- ✅ Domain 1: Monitoring, Logging, and Remediation (CloudWatch, X-Ray)
- ✅ Domain 2: Reliability and Business Continuity (Auto-scaling, health checks)
- ✅ Domain 3: Deployment, Provisioning, and Automation (Terraform, CI/CD)
- ✅ Domain 4: Security and Compliance (IAM, secrets, VPC)
- ✅ Domain 5: Networking and Content Delivery (VPC, subnets, ALB)
- ✅ Domain 6: Cost and Performance Optimization (Cost Explorer, rightsizing)

**Study Plan:**
- Week 1-2: Build project + watch AWS Skill Builder videos
- Week 3: Build project + practice exams (Tutorials Dojo)
- Week 4: Finish project + final exam prep
- Schedule exam for Week 5

---

## 🎯 SUCCESS METRICS

### What "Done" Looks Like

**Technical Deliverables:**
- ✅ 3 microservices running on ECS Fargate
- ✅ Infrastructure fully defined in Terraform
- ✅ CI/CD pipeline deploying automatically
- ✅ Monitoring dashboard with key metrics
- ✅ Comprehensive documentation
- ✅ Security best practices implemented
- ✅ Cost under $40/month

**Portfolio Deliverables:**
- ✅ GitHub repository (public, clean commits)
- ✅ README with architecture diagram
- ✅ Demo video (5-10 minutes)
- ✅ Blog post or LinkedIn article
- ✅ Interview talking points document

**Knowledge Deliverables:**
- ✅ Can explain every architectural decision
- ✅ Can troubleshoot common issues
- ✅ Can answer interview questions confidently
- ✅ Understands cost implications of every choice
- ✅ Knows how this scales to production

---

## 🚨 COMMON PITFALLS & HOW TO AVOID

### Cost Overruns
**Problem:** AWS bill is $200 because you left resources running.
**Prevention:**
- Set billing alerts at $25, $35, $50
- Check Cost Explorer daily
- Use automated tear-down scripts
- Delete resources when not actively testing
- Use Fargate Spot for dev

### Terraform State Issues
**Problem:** Terraform state is corrupted or out of sync.
**Prevention:**
- Always use S3 backend with DynamoDB locking
- Never edit state manually
- Use terraform import for drift
- Keep state file in version control (encrypted)

### ECS Tasks Won't Start
**Problem:** Task definitions fail to launch, stuck in "pending".
**Common Causes:**
- IAM role missing permissions
- ECR image doesn't exist or wrong tag
- Not enough Fargate capacity (rare)
- Secrets Manager permissions missing
- Invalid task definition (CPU/memory combo)
**Solution:** Check CloudWatch Logs, ECS events, IAM policies

### Running Out of Time
**Problem:** Week 4 arrives and infrastructure barely works.
**Prevention:**
- Start simple (get 1 service working first)
- Don't over-engineer (no Redis, no Elasticsearch initially)
- Use AI tools effectively (don't struggle for hours)
- Document as you go (don't wait until end)
- Ask for help (Reddit, Discord, Stack Overflow)

---

## 🎤 INTERVIEW PREPARATION

### The STAR Method for Project Questions

**Situation:** "I wanted to learn AWS and DevOps to transition into a cloud role."

**Task:** "I decided to build a production-grade containerized application with complete CI/CD, monitoring, and cost optimization."

**Action:** "I architected a 3-tier microservices application using ECS Fargate, deployed with Terraform, automated with GitHub Actions, and monitored with CloudWatch. I implemented cost optimization strategies to stay within the free tier."

**Result:** "I successfully deployed a multi-service application with 99.9% uptime (simulated), automated deployments in under 10 minutes, and kept costs under $35/month. The project demonstrates my ability to design scalable, cost-effective cloud infrastructure."

### Key Talking Points

**Architecture:**
"I chose ECS Fargate over EKS because it's serverless, free-tier eligible, and doesn't require managing control plane ($73/month savings). For a small team or startup, Fargate provides excellent cost-performance balance. If we needed Kubernetes-specific features like custom schedulers or complex networking, I'd advocate for EKS."

**FinOps:**
"I implemented several cost optimization strategies: using Fargate Spot for dev (70% savings), rightsizing tasks based on actual usage, single ALB with path-based routing instead of multiple ALBs ($30/month savings), and automated tear-down schedules for non-production environments (70% savings). I set up Cost Explorer dashboards and budget alerts to track spend proactively."

**Security:**
"I implemented defense-in-depth: IAM roles with least privilege, secrets in AWS Secrets Manager, VPC with public/private subnet separation, security groups restricting traffic to only required ports, Docker image scanning in CI/CD, and VPC Flow Logs for audit trails. In production, I'd add AWS WAF, GuardDuty, and Config for additional layers."

**CI/CD:**
"My pipeline uses GitHub Actions with separate workflows for infrastructure (Terraform) and application (Docker). On every push, I run tests, build images, scan for vulnerabilities, push to ECR, and update ECS services. I implemented blue-green deployments for zero-downtime releases and automatic rollbacks on health check failures."

**Monitoring:**
"I use CloudWatch for metrics, logs, and dashboards. I set up alarms for high CPU, error rates, and cost anomalies. For distributed tracing, I integrated X-Ray to track requests across microservices. I created a runbook for common issues with diagnostic steps and resolution procedures."

---

## 🔄 DAILY SUPERVISOR CHECK-INS

### What to Ask Me Every Day

**Morning:**
1. "What is today's goal?"
2. "What blockers do you anticipate?"
3. "What will you need AI help with?"

**Before Starting Work:**
1. "Have you checked AWS Cost Explorer today?"
2. "What is your current spend?"
3. "Do you understand what you're building today and why?"

**When Stuck:**
1. "Have you checked CloudWatch Logs?"
2. "Have you asked ChatGPT/Claude/Gemini?"
3. "Have you looked at AWS documentation?"
4. "Have you searched Stack Overflow/Reddit?"
5. "Can you explain the error in your own words?"

**End of Day:**
1. "What did you accomplish?"
2. "What did you learn?"
3. "What's blocking you for tomorrow?"
4. "Did you document your progress?"
5. "What is your current AWS spend?"

---

## 📦 NEXT STEPS - START TODAY

### Day 1 Action Items (Do These Now)

1. **Set Up AWS Account**
   ```bash
   # Go to aws.amazon.com/free
   # Create account with credit card (won't be charged if you stay in free tier)
   # Enable MFA (multi-factor authentication)
   ```

2. **Set Up Billing Alerts**
   - Go to AWS Billing Dashboard
   - Create budget: $25, $35, $50
   - Set up email alerts

3. **Install Tools**
   ```bash
   # AWS CLI
   brew install awscli  # macOS
   # or
   curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
   unzip awscliv2.zip
   sudo ./aws/install

   # Terraform
   brew install terraform  # macOS
   # or
   wget https://releases.hashicorp.com/terraform/1.6.0/terraform_1.6.0_linux_amd64.zip
   unzip terraform_1.6.0_linux_amd64.zip
   sudo mv terraform /usr/local/bin/

   # Docker
   # Install Docker Desktop from docker.com

   # Verify installations
   aws --version
   terraform --version
   docker --version
   ```

4. **Create GitHub Repository**
   ```bash
   # Go to github.com
   # Create new repository: "aws-devops-ecommerce"
   # Clone locally
   git clone https://github.com/yourusername/aws-devops-ecommerce.git
   cd aws-devops-ecommerce
   ```

5. **Ask Your First AI Question**
   - Open ChatGPT Plus
   - Ask: "Explain the difference between ECS Fargate and EC2 for running containers. I'm learning DevOps and need to understand when to use each."
   - Read the answer carefully
   - Ask follow-up questions if unclear

---

## 🎓 SUPERVISOR NOTES

### My Role as Your Supervisor

**I will NOT:**
- Do the work for you
- Write all the code
- Make decisions for you

**I WILL:**
- Guide you step-by-step
- Explain the "why" behind decisions
- Show you how to use AI tools effectively
- Challenge you on cost implications
- Provide real-world context
- Review your work and suggest improvements
- Help you when you're stuck (after you've tried)

### The FinOps Mindset

After every decision, ask yourself:
1. **What does this cost?**
2. **What are the alternatives?**
3. **What would this cost at scale?**
4. **How would I optimize this in production?**
5. **What's the cost vs benefit trade-off?**

**Example:**
You want to enable AWS WAF.
- **Cost:** $5/month base + $1/million requests
- **Benefit:** Protection against common attacks
- **At scale:** Essential for production
- **For learning:** Document the configuration, don't enable
- **Interview answer:** "I'd enable WAF in production with managed rule groups for OWASP Top 10 protection, but for my learning project, I documented the setup to minimize costs while demonstrating knowledge."

This thinking is what separates good DevOps engineers from great ones.

---

## 🚀 YOU'RE READY - GO BUILD

You now have everything you need:
- ✅ Clear project scope
- ✅ Week-by-week plan
- ✅ Cost breakdown and FinOps strategy
- ✅ AI tool coordination strategy
- ✅ Real-world context for every decision
- ✅ Interview preparation framework

**Your homework for today:**
1. Set up AWS account + billing alerts (30 minutes)
2. Install tools (30 minutes)
3. Create GitHub repo (5 minutes)
4. Ask ChatGPT to explain ECS Fargate vs EC2 (15 minutes)
5. Read Week 1 Day 1-2 section again (10 minutes)

**Tomorrow:**
Come back and tell me:
- "I completed Day 1 setup"
- "My current AWS spend is $0"
- "My first blocker is: ___"

Then I'll guide you through Day 2.

---

## 📞 HOW TO WORK WITH ME

**When you come back each day, start with:**
1. "Today is Day X of Week Y"
2. "Yesterday I accomplished: ___"
3. "Today's goal: ___"
4. "My current AWS spend: $___"
5. "I'm blocked on: ___ (or no blockers)"

**I will respond with:**
1. Feedback on yesterday's work
2. Guidance for today's tasks
3. Real-world context
4. How to use your AI tools
5. FinOps questions to challenge you

**Remember:** The goal is not just to build a project. The goal is to **learn how to think like a Senior DevOps Engineer**.

That means:
- Always considering cost
- Understanding trade-offs
- Knowing alternatives
- Documenting decisions
- Thinking about scale
- Prioritizing security
- Automating everything

---

## 💪 FINAL MOTIVATION

**You have 1 month.** That's enough time to:
- Build an impressive project
- Learn AWS deeply
- Prepare for certification
- Create a portfolio
- Land interviews

**But only if you:**
- Start today (not tomorrow)
- Work consistently (2-4 hours/day)
- Ask for help when stuck (don't waste days)
- Document everything
- Stay within budget

**This project will demonstrate:**
- Infrastructure as Code (Terraform)
- Container orchestration (ECS)
- CI/CD automation (GitHub Actions)
- Cloud architecture (AWS)
- Cost optimization (FinOps)
- Security best practices
- Monitoring & observability

**Employers will see you as someone who:**
- Builds production-grade systems
- Thinks about costs
- Automates workflows
- Follows best practices
- Communicates effectively

**You're not just building a project. You're building a career.**

Now go set up that AWS account and billing alert. See you tomorrow for Day 2. 🚀

---

**Remember:** I'm your supervisor, not your co-worker. I guide, you execute. That's how you learn.

**First question to think about overnight:**
"What is the cost implication of running this architecture 24/7 for a month vs implementing automated tear-down schedules?"

Come back tomorrow with your answer, and we'll start building.