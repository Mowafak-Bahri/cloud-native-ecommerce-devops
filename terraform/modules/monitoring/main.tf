locals {
  tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
  }

  services = {
    product = {
      log_key     = "product-service"
      ecs_service = "${var.project_name}-${var.environment}-product"
      friendly    = "product-service"
    }
    order = {
      log_key     = "order-service"
      ecs_service = "${var.project_name}-${var.environment}-order"
      friendly    = "order-service"
    }
    frontend = {
      log_key     = "frontend"
      ecs_service = "${var.project_name}-${var.environment}-frontend"
      friendly    = "frontend"
    }
  }
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

locals {
  alb_name = replace(
    var.alb_arn,
    "arn:aws:elasticloadbalancing:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:loadbalancer/",
    ""
  )
}

resource "aws_cloudwatch_log_group" "services" {
  for_each          = var.log_group_names
  name              = each.value
  retention_in_days = 7
  tags              = merge(local.tags, { Service = each.key })
}

resource "aws_sns_topic" "monitoring" {
  name = "${var.project_name}-${var.environment}-alerts"
  tags = local.tags
}

resource "aws_sns_topic_subscription" "email" {
  count     = var.alarm_email == "" ? 0 : 1
  topic_arn = aws_sns_topic.monitoring.arn
  protocol  = "email"
  endpoint  = var.alarm_email
}

resource "aws_cloudwatch_dashboard" "platform" {
  dashboard_name = "${var.project_name}-${var.environment}-dashboard"

  dashboard_body = jsonencode({
    widgets = [
      {
        type = "metric"
        width = 12
        height = 6
        properties = {
          title = "ECS CPU Utilization"
          metrics = [
            ["AWS/ECS", "CPUUtilization", "ClusterName", var.cluster_name, "ServiceName", "${var.project_name}-${var.environment}-product"],
            [".", ".", ".", ".", "ServiceName", "${var.project_name}-${var.environment}-order"],
            [".", ".", ".", ".", "ServiceName", "${var.project_name}-${var.environment}-frontend"]
          ]
          period = 300
          stat   = "Average"
        }
      },
      {
        type = "metric"
        width = 12
        height = 6
        properties = {
          title = "ALB Requests and Latency"
          metrics = [
            ["AWS/ApplicationELB", "RequestCount", "LoadBalancer", local.alb_name],
            [".", "TargetResponseTime", ".", "."]
          ]
          period = 60
          stat   = "Average"
        }
      },
      {
        type = "metric"
        width = 12
        height = 6
        properties = {
          title = "RDS CPU & Connections"
          metrics = [
            ["AWS/RDS", "CPUUtilization", "DBInstanceIdentifier", var.db_instance_id],
            [".", "DatabaseConnections", ".", "."]
          ]
          period = 300
          stat   = "Average"
        }
      },
      {
        type = "metric"
        width = 12
        height = 6
        properties = {
          title = "Estimated Daily Cost"
          metrics = [
            ["AWS/Billing", "EstimatedCharges", "Currency", "USD"]
          ]
          period = 86400
          stat   = "Maximum"
        }
      }
    ]
  })
}

resource "aws_cloudwatch_metric_alarm" "ecs_cpu" {
  for_each = local.services

  alarm_name          = "${var.project_name}-${var.environment}-${each.value.friendly}-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "ECS service ${each.value.friendly} CPU utilization high"
  treat_missing_data  = "missing"
  alarm_actions       = [aws_sns_topic.monitoring.arn]

  dimensions = {
    ClusterName = var.cluster_name
    ServiceName = each.value.ecs_service
  }
}

resource "aws_cloudwatch_metric_alarm" "alb_5xx" {
  alarm_name          = "${var.project_name}-${var.environment}-alb-5xx"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "HTTPCode_Target_5XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = 300
  statistic           = "Sum"
  threshold           = 10
  alarm_description   = "ALB is returning elevated 5xx responses"
  treat_missing_data  = "notBreaching"
  alarm_actions       = [aws_sns_topic.monitoring.arn]

  dimensions = {
    LoadBalancer = local.alb_name
  }
}

resource "aws_cloudwatch_metric_alarm" "rds_cpu" {
  alarm_name          = "${var.project_name}-${var.environment}-rds-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "RDS CPU utilization high"
  treat_missing_data  = "notBreaching"
  alarm_actions       = [aws_sns_topic.monitoring.arn]

  dimensions = {
    DBInstanceIdentifier = var.db_instance_id
  }
}

resource "aws_cloudwatch_metric_alarm" "daily_cost" {
  alarm_name          = "${var.project_name}-${var.environment}-cost"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "EstimatedCharges"
  namespace           = "AWS/Billing"
  period              = 86400
  statistic           = "Maximum"
  threshold           = 3
  alarm_description   = "Estimated daily AWS spend exceeds $3"
  treat_missing_data  = "notBreaching"
  alarm_actions       = [aws_sns_topic.monitoring.arn]

  dimensions = {
    Currency = "USD"
  }
}
