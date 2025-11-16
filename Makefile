.PHONY: help local-up local-down local-clean local-logs local-test \
        tf-init tf-plan tf-apply tf-destroy deploy-all deploy-product \
        deploy-order deploy-frontend ecr-login cost-check setup-aws

AWS_REGION ?= us-east-1
AWS_ACCOUNT_ID := $(shell aws sts get-caller-identity --query Account --output text 2>/dev/null)
DOCKER_COMPOSE := $(shell docker compose version >/dev/null 2>&1 && echo "docker compose" || echo "docker-compose")

help:  ## Show this help message
	@echo 'Usage: make [target]'
	@echo ''
	@echo 'Available targets:'
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

# Local Development
local-up:  ## Start local services with docker-compose
	$(DOCKER_COMPOSE) up -d
	@echo "Services starting... Wait 30 seconds for initialization"

local-down:  ## Stop local services
	$(DOCKER_COMPOSE) down

local-clean:  ## Stop services and clean volumes
	$(DOCKER_COMPOSE) down -v
	@docker system prune -f

local-logs:  ## View logs from all services
	$(DOCKER_COMPOSE) logs -f

local-test:  ## Run local integration tests
	./scripts/test-local.sh

# AWS/Terraform
tf-init:  ## Initialize Terraform
	cd terraform && terraform init

tf-plan:  ## Run Terraform plan
	cd terraform && terraform plan

tf-apply:  ## Apply Terraform changes
	cd terraform && terraform apply

tf-destroy:  ## Destroy Terraform infrastructure
	cd terraform && terraform destroy

# Deployment
ecr-login:  ## Login to AWS ECR
	aws ecr get-login-password --region $(AWS_REGION) | \
		docker login --username AWS --password-stdin $(AWS_ACCOUNT_ID).dkr.ecr.$(AWS_REGION).amazonaws.com

deploy-all: ecr-login  ## Deploy all services to AWS
	./scripts/deploy.sh all

deploy-product: ecr-login  ## Deploy product-service only
	./scripts/deploy.sh product-service

deploy-order: ecr-login  ## Deploy order-service only
	./scripts/deploy.sh order-service

deploy-frontend: ecr-login  ## Deploy frontend only
	./scripts/deploy.sh frontend

# Utilities
cost-check:  ## Check AWS costs
	./scripts/cost-check.sh

setup-aws:  ## Setup AWS prerequisites
	./scripts/setup-aws.sh
