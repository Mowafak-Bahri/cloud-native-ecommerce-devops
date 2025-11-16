variable "aws_region" {
  description = "AWS region for all resources."
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Deployment environment name."
  type        = string
  default     = "dev"
}

variable "project_name" {
  description = "Project identifier."
  type        = string
  default     = "ecommerce"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC."
  type        = string
  default     = "10.0.0.0/16"
}

variable "db_name" {
  description = "Default PostgreSQL database name."
  type        = string
  default     = "ecommerce"
}

variable "db_username" {
  description = "Master PostgreSQL username."
  type        = string
  sensitive   = true
  default     = "admin"
}

variable "alarm_email" {
  description = "Email recipient for CloudWatch alarms."
  type        = string
  default     = ""
}
