# -----------------------------------------------------------------------------
# Aggregated outputs from all modules
# -----------------------------------------------------------------------------

# VPC
output "vpc_id" {
  value = module.vpc.vpc_id
}

output "public_subnet_ids" {
  value = module.vpc.public_subnet_ids
}

output "security_group_id" {
  value = module.vpc.security_group_id
}

# ECR
output "ecr_repository_url" {
  value = module.ecr.repository_url
}

output "ecr_repository_name" {
  value = module.ecr.repository_name
}

# DynamoDB
output "dynamodb_table_name" {
  value = module.dynamodb.table_name
}

output "dynamodb_table_arn" {
  value = module.dynamodb.table_arn
}

# SQS
output "sqs_queue_url" {
  value = module.sqs.queue_url
}

output "sqs_queue_arn" {
  value = module.sqs.queue_arn
}

output "sqs_dlq_url" {
  value = module.sqs.dlq_url
}

# SNS
output "sns_topic_arn" {
  value = module.sns.topic_arn
}

# EventBridge
output "eventbridge_bus_name" {
  value = module.eventbridge.bus_name
}

output "eventbridge_bus_arn" {
  value = module.eventbridge.bus_arn
}

# IAM
output "lambda_role_arn" {
  value = module.iam.lambda_role_arn
}

output "lambda_log_group_name" {
  value = module.iam.lambda_log_group_name
}


# Lambda + API Gateway
output "lambda_function_name" {
  value = module.lambda.lambda_function_name
}

output "lambda_function_arn" {
  value = module.lambda.lambda_function_arn
}

output "api_endpoint" {
  value = module.lambda.api_endpoint
}




# Monitoring
output "dashboard_url" {
  description = "URL to view the CloudWatch dashboard"
  value       = module.monitoring.dashboard_url
}

output "alarm_names" {
  description = "List of CloudWatch alarm names"
  value       = module.monitoring.alarm_names
}
