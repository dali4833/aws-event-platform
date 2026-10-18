output "dashboard_name" {
  description = "CloudWatch dashboard name"
  value       = aws_cloudwatch_dashboard.main.dashboard_name
}

output "dashboard_url" {
  description = "Full URL to view the dashboard in AWS Console"
  value       = "https://${var.aws_region}.console.aws.amazon.com/cloudwatch/home?region=${var.aws_region}#dashboards:name=${aws_cloudwatch_dashboard.main.dashboard_name}"
}

output "alarm_names" {
  description = "List of CloudWatch alarm names"
  value = [
    aws_cloudwatch_metric_alarm.lambda_errors.alarm_name,
    aws_cloudwatch_metric_alarm.apigw_5xx.alarm_name,
    aws_cloudwatch_metric_alarm.dlq_messages.alarm_name,
    aws_cloudwatch_metric_alarm.lambda_slow.alarm_name,
    aws_cloudwatch_metric_alarm.sns_failures.alarm_name,
  ]
}
