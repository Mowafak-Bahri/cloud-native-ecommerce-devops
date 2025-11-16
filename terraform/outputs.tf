output "alb_dns_name" {
  description = "Application Load Balancer DNS name."
  value       = module.ecs.alb_dns_name
}

output "ecr_repository_urls" {
  description = "Map of ECR repository URLs."
  value       = module.ecr.repository_urls
}

output "db_endpoint" {
  description = "PostgreSQL endpoint."
  value       = module.rds.db_endpoint
  sensitive   = true
}
