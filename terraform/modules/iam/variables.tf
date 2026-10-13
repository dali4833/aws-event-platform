variable "project" {
  description = "Project prefix for resource names"
  type        = string
}

variable "env" {
  description = "Environment name (staging, prod)"
  type        = string
}

variable "dynamodb_table_arn" {
  description = "ARN of the DynamoDB events table"
  type        = string
}

variable "sqs_queue_arn" {
  description = "ARN of the SQS main queue"
  type        = string
}

variable "sns_topic_arn" {
  description = "ARN of the SNS topic"
  type        = string
}

variable "eventbridge_bus_arn" {
  description = "ARN of the EventBridge custom bus"
  type        = string
}
