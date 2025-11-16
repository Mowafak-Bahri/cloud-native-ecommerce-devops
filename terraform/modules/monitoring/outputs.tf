output "dashboard_name" {
  value = aws_cloudwatch_dashboard.platform.dashboard_name
}

output "log_group_arns" {
  value = { for key, lg in aws_cloudwatch_log_group.services : key => lg.arn }
}

output "sns_topic_arn" {
  value = aws_sns_topic.monitoring.arn
}
