variable "project" {
  description = "Project prefix for resource names"
  type        = string
}

variable "env" {
  description = "Environment name (staging, prod)"
  type        = string
}

variable "bus_name" {
  description = "Base name of the EventBridge bus"
  type        = string
  default     = "bus"
}

variable "sns_topic_arn" {
  description = "ARN of the SNS topic for high-priority notifications"
  type        = string
}

variable "sqs_queue_arn" {
  description = "ARN of the SQS queue for processing events"
  type        = string
}
