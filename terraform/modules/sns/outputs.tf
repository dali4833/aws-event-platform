output "topic_arn" {
  description = "SNS topic ARN"
  value       = aws_sns_topic.main.arn
}

output "topic_name" {
  description = "SNS topic name"
  value       = aws_sns_topic.main.name
}

output "subscription_arn" {
  description = "SNS email subscription ARN (empty if email disabled)"
  value       = length(aws_sns_topic_subscription.email) > 0 ? aws_sns_topic_subscription.email[0].arn : ""
}
