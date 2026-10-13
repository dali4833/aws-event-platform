output "bus_name" {
  description = "EventBridge bus name"
  value       = aws_cloudwatch_event_bus.main.name
}

output "bus_arn" {
  description = "EventBridge bus ARN"
  value       = aws_cloudwatch_event_bus.main.arn
}

output "high_priority_rule_name" {
  description = "Rule name for high-priority events"
  value       = aws_cloudwatch_event_rule.high_priority.name
}

output "processing_rule_name" {
  description = "Rule name for processing events"
  value       = aws_cloudwatch_event_rule.processing.name
}
