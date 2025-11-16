variable "project_name" {
  type        = string
  description = "Project name for tagging."
}

variable "environment" {
  type        = string
  description = "Environment name."
}

variable "vpc_id" {
  type        = string
  description = "ID of the VPC."
}

variable "private_subnet_ids" {
  type        = list(string)
  description = "Private subnets for RDS."
}

variable "db_sg_id" {
  type        = string
  description = "Security group for the database."
}

variable "db_name" {
  type        = string
  description = "Database name."
  default     = "ecommerce"
}

variable "db_username" {
  type        = string
  description = "Master username."
}
