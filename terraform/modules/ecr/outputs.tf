output "repository_urls" {
  description = "Map of service name to repository URL."
  value = { for name, repo in aws_ecr_repository.services : name => repo.repository_url }
}
