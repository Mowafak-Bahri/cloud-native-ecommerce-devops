variable "project_name" {
  type        = string
  description = "Project name."
}

variable "environment" {
  type        = string
  description = "Environment name."
}

variable "vpc_id" {
  type        = string
  description = "VPC ID."
}

variable "public_subnet_ids" {
  type        = list(string)
  description = "Public subnets for ALB."
}

variable "private_subnet_ids" {
  type        = list(string)
  description = "Private subnets for ECS tasks."
}

variable "alb_sg_id" {
  type        = string
  description = "Security group for ALB."
}

variable "ecs_sg_id" {
  type        = string
  description = "Security group for ECS services."
}

variable "repository_urls" {
  type        = map(string)
  description = "ECR repository URLs for each service."
}

variable "db_endpoint" {
  type        = string
  description = "Database endpoint."
}

variable "db_name" {
  type        = string
  description = "Database name."
}

variable "db_username" {
  type        = string
  description = "Database username."
}

variable "db_secret_arn" {
  type        = string
  description = "Secrets Manager ARN storing DB credentials."
}

variable "log_group_names" {
  type        = map(string)
  description = "CloudWatch log group names per service."
}
