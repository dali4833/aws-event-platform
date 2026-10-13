# AWS Event Platform

Serverless + Kubernetes event platform on AWS.

## Architecture
- **Serverless layer:** API Gateway + Lambda + DynamoDB + SQS + EventBridge
- **Kubernetes layer:** EKS + ArgoCD (GitOps) + Prometheus + Grafana
- **IaC:** Terraform (modular, staging + prod)
- **CI/CD:** GitHub Actions → ECR → ArgoCD

## Region
`eu-west-1` (Ireland)

## Status
Work in progress.
