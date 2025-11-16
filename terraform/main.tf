terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.5"
    }
  }

  # backend "s3" {
  #   bucket         = "your-terraform-state-bucket"
  #   key            = "cloud-native-ecommerce/terraform.tfstate"
  #   region         = "us-east-1"
  #   dynamodb_table = "terraform-locks"
  #   encrypt        = true
  # }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  }
}

locals {
  log_group_names = {
    "product-service" = "/ecs/product-service"
    "order-service"   = "/ecs/order-service"
    "frontend"        = "/ecs/frontend"
  }
}

module "networking" {
  source      = "./modules/networking"
  project_name = var.project_name
  environment  = var.environment
  vpc_cidr     = var.vpc_cidr
}

module "ecr" {
  source       = "./modules/ecr"
  project_name = var.project_name
  environment  = var.environment
}

module "rds" {
  source             = "./modules/rds"
  project_name       = var.project_name
  environment        = var.environment
  vpc_id             = module.networking.vpc_id
  private_subnet_ids = module.networking.private_subnet_ids
  db_sg_id           = module.networking.db_sg_id
  db_name            = var.db_name
  db_username        = var.db_username
}

module "ecs" {
  source             = "./modules/ecs"
  project_name       = var.project_name
  environment        = var.environment
  vpc_id             = module.networking.vpc_id
  public_subnet_ids  = module.networking.public_subnet_ids
  private_subnet_ids = module.networking.private_subnet_ids
  alb_sg_id          = module.networking.alb_sg_id
  ecs_sg_id          = module.networking.ecs_sg_id
  repository_urls    = module.ecr.repository_urls
  db_endpoint        = module.rds.db_endpoint
  db_name            = module.rds.db_name
  db_username        = var.db_username
  db_secret_arn      = module.rds.secret_arn
  log_group_names    = local.log_group_names
}

module "monitoring" {
  source          = "./modules/monitoring"
  project_name    = var.project_name
  environment     = var.environment
  cluster_name    = module.ecs.cluster_name
  alb_arn         = module.ecs.alb_arn
  db_instance_id  = module.rds.db_instance_id
  log_group_names = local.log_group_names
  alarm_email     = var.alarm_email
}
