variable "project" {
  description = "Project prefix for resource names"
  type        = string
}

variable "env" {
  description = "Environment name (staging, prod)"
  type        = string
}

variable "table_name" {
  description = "Base name of the DynamoDB table"
  type        = string
  default     = "events"
}
