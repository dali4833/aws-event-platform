variable "project" {
  description = "Project prefix for resource names"
  type        = string
}

variable "env" {
  description = "Environment name (staging, prod)"
  type        = string
}

variable "repository_name" {
  description = "Base name of the ECR repository"
  type        = string
  default     = "app"
}
