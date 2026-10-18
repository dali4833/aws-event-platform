variable "project" {
  description = "Project prefix for resource names"
  type        = string
}

variable "env" {
  description = "Environment name (staging, prod)"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "lambda_function_name" {
  description = "Name of the Lambda function to monitor"
  type        = string
}

variable "api_gateway_id" {
  description = "ID of the API Gateway to monitor"
  type        = string
}

variable "dynamodb_table_name" {
  description = "Name of the DynamoDB table"
  type        = string
}

variable "sqs_queue_name" {
  description = "Name of the main SQS queue"
  type        = string
}

variable "sqs_dlq_name" {
  description = "Name of the SQS dead-letter queue"
  type        = string
}

variable "sns_topic_arn" {
  description = "ARN of the SNS topic for alarm notifications"
  type        = string
}
