output "github_actions_role_arn" {
  description = "ARN of the IAM role for GitHub Actions"
  value       = module.cicd.role_arn
}

output "github_actions_role_name" {
  description = "Name of the IAM role for GitHub Actions"
  value       = module.cicd.role_name
}

output "oidc_provider_arn" {
  description = "ARN of the GitHub OIDC provider"
  value       = module.cicd.oidc_provider_arn
}
