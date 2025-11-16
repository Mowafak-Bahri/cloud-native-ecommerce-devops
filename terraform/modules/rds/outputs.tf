output "db_endpoint" {
  value = aws_db_instance.this.address
}

output "db_name" {
  value = var.db_name
}

output "secret_arn" {
  value = aws_secretsmanager_secret.db.arn
}

output "db_instance_id" {
  value = aws_db_instance.this.id
}
