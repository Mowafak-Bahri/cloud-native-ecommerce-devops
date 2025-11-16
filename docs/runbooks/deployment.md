# Deployment Runbook

## 1. Prerequisites

- AWS account with IAM permissions for VPC, ECS, ECR, RDS, IAM, CloudWatch, and Secrets Manager.
- AWS CLI v2 and Terraform >= 1.5 installed locally.
- Docker Engine + Compose plugin.
- Git, Node.js 18+, and Python 3.11 (for local testing).
- Access to GitHub repository with configured secrets: `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`.

## 2. Initial Setup

```bash
git clone https://github.com/Mowafak-Bahri/cloud-native-ecommerce-devops.git
cd cloud-native-ecommerce-devops
aws configure # set region + credentials
```

Create S3 bucket and DynamoDB table for Terraform state (optional but recommended):

```bash
aws s3 mb s3://my-tf-state-bucket
aws dynamodb create-table \
  --table-name terraform-locks \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST
```

Uncomment and update the backend block in `terraform/main.tf` to match the bucket/table names.

## 3. Local Testing

```bash
docker compose build
docker compose up -d

# Health checks
curl http://localhost:8000/health
curl http://localhost:8001/health
curl http://localhost:3000/health

# Sample API calls
curl http://localhost:8000/products
curl -X POST http://localhost:8001/orders \
  -H "Content-Type: application/json" \
  -d '{"product_id": 1, "quantity": 2}'
```

Shut everything down when finished:

```bash
docker compose down
```

## 4. Deploy Infrastructure (Terraform)

```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars   # customize values
terraform init
terraform fmt
terraform validate
terraform plan -out=tfplan
terraform apply tfplan
```

Outputs include the ALB DNS name, repository URLs, and database endpoint. Keep them handy for application configuration.

## 5. Build and Push Docker Images

```bash
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin <account-id>.dkr.ecr.us-east-1.amazonaws.com

for svc in product-service order-service frontend; do
  REPO="ecommerce-dev-$svc"
  docker build -t $REPO:latest ./services/$svc
  docker tag $REPO:latest <account-id>.dkr.ecr.us-east-1.amazonaws.com/$REPO:latest
  docker push <account-id>.dkr.ecr.us-east-1.amazonaws.com/$REPO:latest
done
```

(GitHub Actions `deploy.yml` automates this upon merging to `main`.)

## 6. Deploy Services to ECS

Terraform already provisions task definitions and services. To roll out new images manually:

```bash
aws ecs update-service \
  --cluster ecommerce-dev-cluster \
  --service ecommerce-dev-product \
  --force-new-deployment
# repeat for order and frontend services
```

GitHub Actions workflow performs the build, Trivy scan, push, task-definition update, and ECS deploy automatically when changes land on `main`.

## 7. Verify Deployment

```bash
ALB_DNS=$(terraform output -raw alb_dns_name)
curl http://$ALB_DNS/products
curl http://$ALB_DNS/orders
curl http://$ALB_DNS/
```

Check ECS service health:

```bash
aws ecs describe-services --cluster ecommerce-dev-cluster \
  --services ecommerce-dev-product ecommerce-dev-order ecommerce-dev-frontend
```

Validate CloudWatch dashboards/alarms and ensure SNS notifications work by triggering a test alarm (`aws sns publish`).

## 8. Post-Deployment Checklist

- [ ] All services show healthy tasks in ECS.
- [ ] ALB target groups report 100% healthy targets.
- [ ] CloudWatch dashboard populates metrics and X-Ray traces appear.
- [ ] Secrets Manager contains the generated DB credentials.
- [ ] GitHub Actions runs succeeded (Terraform + deploy).
- [ ] Update status page and notify stakeholders.

## 9. Rollback Procedure

1. Identify the last known-good ECR image tag (from Git history or ECR console).
2. Register a new task definition revision pointing to the stable image.
3. Run `aws ecs update-service --cluster ecommerce-dev-cluster --service <svc> --task-definition <stable-arn> --force-new-deployment`.
4. If infrastructure changes caused the incident, run `terraform apply` with the previous `tfplan` or `terraform state` rollback (last resort).

## 10. Troubleshooting Highlights

- Check `docker logs` locally or CloudWatch log groups (`/ecs/<service>`) for stack traces.
- Use `aws ecs execute-command` to open a shell into running tasks for live debugging.
- Confirm networking paths: ALB SG -> ECS SG (ports 8000-8002) -> DB SG (5432).
- Re-run `terraform plan` to ensure infra drift has not occurred.
- See `docs/runbooks/troubleshooting.md` for deep dives into recurring issues.
