output "lambda_role_arn" {
  description = "ARN of the Lambda execution role"
  value       = aws_iam_role.lambda.arn
}

output "lambda_role_name" {
  description = "Name of the Lambda execution role"
  value       = aws_iam_role.lambda.name
}

output "lambda_log_group_name" {
  description = "CloudWatch log group for Lambda"
  value       = aws_cloudwatch_log_group.lambda.name
}
