variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "eu-west-1"
}

variable "project" {
  description = "Project prefix"
  type        = string
  default     = "awsevt"
}

variable "env" {
  description = "Environment name"
  type        = string
  default     = "staging"
}

variable "notification_email" {
  description = "Email for SNS notifications"
  type        = string
  default     = ""
}
