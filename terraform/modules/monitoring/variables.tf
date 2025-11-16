variable "project_name" {
  type        = string
  description = "Project identifier."
}

variable "environment" {
  type        = string
  description = "Environment name."
}

variable "cluster_name" {
  type        = string
  description = "ECS cluster name."
}

variable "alb_arn" {
  type        = string
  description = "Application Load Balancer ARN."
}

variable "db_instance_id" {
  type        = string
  description = "RDS instance identifier."
}

variable "log_group_names" {
  type        = map(string)
  description = "Log group names per service."
}

variable "alarm_email" {
  type        = string
  description = "Email for SNS alarm notifications."
  default     = ""
}
