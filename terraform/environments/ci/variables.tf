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
  description = "Environment name for CI resources"
  type        = string
  default     = "ci"
}

variable "github_org" {
  description = "GitHub organization or username"
  type        = string
  default     = "dali4833"
}

variable "github_repo" {
  description = "GitHub repository name"
  type        = string
  default     = "aws-event-platform"
}

variable "allowed_branches" {
  description = "Branches allowed to assume the role"
  type        = list(string)
  default     = ["main"]
}
