output "lambda_function_name" {
  description = "Name of the Lambda function"
  value       = aws_lambda_function.producer.function_name
}

output "lambda_function_arn" {
  description = "ARN of the Lambda function"
  value       = aws_lambda_function.producer.arn
}

output "api_endpoint" {
  description = "Base URL of the API Gateway"
  value       = aws_apigatewayv2_stage.default.invoke_url
}

output "api_id" {
  description = "API Gateway ID"
  value       = aws_apigatewayv2_api.main.id
}
