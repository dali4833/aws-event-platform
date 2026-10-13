output "topic_arn" {
  description = "SNS topic ARN"
  value       = aws_sns_topic.main.arn
}

output "topic_name" {
  description = "SNS topic name"
  value       = aws_sns_topic.main.name
}
