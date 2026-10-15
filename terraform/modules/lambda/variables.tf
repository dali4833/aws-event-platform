variable "project" {
  description = "Project prefix for resource names"
  type        = string
}

variable "env" {
  description = "Environment name (staging, prod)"
  type        = string
}

variable "lambda_role_arn" {
  description = "ARN of the IAM role for the Lambda function"
  type        = string
}

variable "table_name" {
  description = "DynamoDB table name"
  type        = string
}

variable "event_bus_name" {
  description = "EventBridge custom bus name"
  type        = string
}

variable "source_dir" {
  description = "Path to the Lambda source code directory"
  type        = string
}

variable "log_level" {
  description = "Log level for the Lambda function"
  type        = string
  default     = "INFO"
}
