locals {
  tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

resource "aws_db_subnet_group" "this" {
  name       = "${var.project_name}-${var.environment}-db-subnet"
  subnet_ids = var.private_subnet_ids
  tags       = merge(local.tags, { Name = "${var.project_name}-${var.environment}-db-subnet" })
}

resource "aws_db_parameter_group" "this" {
  name   = "${var.project_name}-${var.environment}-pg15"
  family = "postgres15"

  parameter {
    name  = "log_min_duration_statement"
    value = "500"
  }

  parameter {
    name  = "max_connections"
    value = "200"
  }

  tags = merge(local.tags, { Name = "${var.project_name}-${var.environment}-pg" })
}

resource "random_password" "db" {
  length           = 24
  special          = true
  override_characters = "!@#$%^&*()-_=+"
}

resource "aws_secretsmanager_secret" "db" {
  name = "${var.project_name}/${var.environment}/database"
  tags = local.tags
}

resource "aws_secretsmanager_secret_version" "db" {
  secret_id     = aws_secretsmanager_secret.db.id
  secret_string = jsonencode({ username = var.db_username, password = random_password.db.result })
}

resource "aws_db_instance" "this" {
  identifier              = "${var.project_name}-${var.environment}-db"
  engine                  = "postgres"
  engine_version          = "15.3"
  instance_class          = "db.t4g.micro"
  allocated_storage       = 20
  storage_type            = "gp3"
  storage_encrypted       = true
  db_subnet_group_name    = aws_db_subnet_group.this.name
  vpc_security_group_ids  = [var.db_sg_id]
  username                = var.db_username
  password                = random_password.db.result
  db_name                 = var.db_name
  backup_retention_period = 7
  skip_final_snapshot     = true
  multi_az                = false
  apply_immediately       = true
  parameter_group_name    = aws_db_parameter_group.this.name
  deletion_protection     = false
  publicly_accessible     = false
  tags                    = merge(local.tags, { Name = "${var.project_name}-${var.environment}-db" })
}
