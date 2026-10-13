variable "project" {
  description = "Project prefix for resource names"
  type        = string
}

variable "env" {
  description = "Environment name (staging, prod)"
  type        = string
}

variable "topic_name" {
  description = "Base name of the SNS topic"
  type        = string
  default     = "notifications"
}
