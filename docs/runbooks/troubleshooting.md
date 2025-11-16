# Troubleshooting Guide

Each scenario below follows the format: **Symptoms → Diagnosis → Resolution → Prevention**. Run commands from the repo root unless specified.

---

## 1. ECS Tasks Keep Restarting

- **Symptoms:** Tasks enter `STOPPED` minutes after launch; ECS events show `Essential container in task exited`.
- **Diagnosis:**
  - Check service events: `aws ecs describe-services --cluster ecommerce-dev-cluster --services ecommerce-dev-product --query 'services[0].events[:5]'`.
  - Inspect CloudWatch logs `/ecs/<service>` for stack traces.
  - Verify task definition env vars/secrets: `aws ecs describe-task-definition --task-definition ecommerce-dev-product`.
- **Resolution:** Fix the root cause (missing DB connectivity, invalid env values, crashed container) and deploy a new task definition or rerun GitHub Actions deploy.
- **Prevention:** Add unit/integration tests, enforce Trivy scans, and enable ECS circuit breakers if using CodeDeploy.

## 2. Services Cannot Connect to Database

- **Symptoms:** API returns 503/500, logs show `ECONNREFUSED 5432` or `psycopg2.OperationalError`.
- **Diagnosis:**
  - Confirm RDS status: `aws rds describe-db-instances --db-instance-identifier ecommerce-dev-db --query 'DBInstances[0].DBInstanceStatus'`.
  - Validate security groups: ensure RDS SG allows inbound from ECS SG.
  - Ensure Secrets Manager credentials match: `aws secretsmanager get-secret-value --secret-id ecommerce/dev/database`.
  - Test connectivity from task: `aws ecs execute-command --cluster ... --task <id> --container product-service --command "nc -zv <db-host> 5432"`.
- **Resolution:** Reapply Terraform to fix SGs, rotate secrets if mismatched, or restart RDS if stuck.
- **Prevention:** Keep Terraform state authoritative; run automated smoke tests after deploy.

## 3. ALB Returns 503 Service Unavailable

- **Symptoms:** ALB health check fails; `/health` endpoint unreachable.
- **Diagnosis:**
  - Target health: `aws elbv2 describe-target-health --target-group-arn <tg-arn>`.
  - Confirm ECS tasks listening on correct port with `aws ecs list-tasks` + `describe-tasks`.
  - Review ALB access logs (if enabled) for 503 spikes.
- **Resolution:** Ensure tasks pass health checks (fix endpoints, warm-up DB), redeploy services, or scale out tasks.
- **Prevention:** Use health-check grace periods (already 60s) and implement synthetic checks post-deploy.

## 4. High Latency on API Calls

- **Symptoms:** Clients report slow responses; ALB TargetResponseTime grows.
- **Diagnosis:**
  - CloudWatch metrics: `aws cloudwatch get-metric-statistics --metric-name TargetResponseTime --namespace AWS/ApplicationELB ...`.
  - Review X-Ray traces via console or `aws xray get-service-graph`.
  - Check database slow queries using `SELECT * FROM pg_stat_activity`.
- **Resolution:** Increase Fargate task size, add read replicas or caching, tune SQL indexes, and profile traces to eliminate bottlenecks.
- **Prevention:** Implement autoscaling on CPU/memory and create CloudWatch alarms for latency thresholds.

## 5. Docker Image Build Fails

- **Symptoms:** `docker build` errors or GitHub Actions `deploy` workflow fails before Trivy.
- **Diagnosis:**
  - Inspect build logs locally or from Actions artifacts.
  - Validate Dockerfile syntax and dependency versions.
  - Ensure `.dockerignore` excludes node_modules/venv to keep context small.
- **Resolution:** Fix Dockerfile instructions, upgrade base images, or clean local cache.
- **Prevention:** Run `docker build` locally before pushing, and keep Dockerfiles minimal.

## 6. Terraform Apply Fails

- **Symptoms:** `terraform apply` exits non-zero, usually due to IAM/network conflicts.
- **Diagnosis:**
  - Run `terraform validate` to catch syntax errors.
  - Inspect `terraform.tfstate` lock or error details in CLI output.
  - Check AWS CloudTrail for denied operations.
- **Resolution:** Resolve drift manually (e.g., delete conflicting resources), re-run `terraform plan`, or unlock the state: `terraform force-unlock <lock-id>`.
- **Prevention:** Use remote backend with state locking, avoid out-of-band console changes, and rely on CI Terraform workflow.

## 7. Cost Spike Unexpectedly

- **Symptoms:** AWS Cost Anomaly alerts or budgets triggered.
- **Diagnosis:**
  - Cost Explorer: `aws ce get-cost-and-usage --time-period Start=$(date -I -d '7 days ago'),End=$(date -I) --granularity DAILY --metrics BlendedCost`.
  - Identify offending service (e.g., NAT data transfer, ALB, RDS).
  - Check CloudWatch `EstimatedCharges` alarm details.
- **Resolution:** Scale down idle ECS tasks, stop dev environments overnight, adjust log retention, or enable RDS stop/start schedules.
- **Prevention:** Set AWS Budgets with email/SNS alarms, review costs weekly, and clean up unused ECR images (lifecycle policy already in place).
