variable "project" {
  description = "Project prefix for resource names"
  type        = string
}

variable "env" {
  description = "Environment name (staging, prod)"
  type        = string
}

variable "queue_name" {
  description = "Base name of the SQS queue"
  type        = string
  default     = "events"
}

variable "visibility_timeout_seconds" {
  description = "How long a consumer has to process a message"
  type        = number
  default     = 60
}

variable "message_retention_seconds" {
  description = "How long messages are kept (seconds)"
  type        = number
  default     = 345600 # 4 days
}

variable "max_receive_count" {
  description = "Retries before message goes to DLQ"
  type        = number
  default     = 3
}
