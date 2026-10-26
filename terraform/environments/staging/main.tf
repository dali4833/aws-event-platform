# -----------------------------------------------------------------------------
# Provider
# -----------------------------------------------------------------------------
provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = var.project
      Environment = var.env
      ManagedBy   = "terraform"
    }
  }
}

# -----------------------------------------------------------------------------
# Data source — current AWS account
# -----------------------------------------------------------------------------
data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

# -----------------------------------------------------------------------------
# Module: VPC
# -----------------------------------------------------------------------------
module "vpc" {
  source = "../../modules/vpc"

  project  = var.project
  env      = var.env
  region   = var.aws_region
  vpc_cidr = "10.1.0.0/16"
  public_subnet_cidrs = [
    "10.1.1.0/24",
    "10.1.2.0/24",
  ]
  availability_zones = [
    "eu-west-1a",
    "eu-west-1b",
  ]
}

# -----------------------------------------------------------------------------
# Module: ECR
# -----------------------------------------------------------------------------
module "ecr" {
  source = "../../modules/ecr"

  project         = var.project
  env             = var.env
  repository_name = "app"
}

# -----------------------------------------------------------------------------
# Module: DynamoDB
# -----------------------------------------------------------------------------
module "dynamodb" {
  source = "../../modules/dynamodb"

  project    = var.project
  env        = var.env
  table_name = "events"
}

# -----------------------------------------------------------------------------
# Module: SQS
# -----------------------------------------------------------------------------
module "sqs" {
  source = "../../modules/sqs"

  project    = var.project
  env        = var.env
  queue_name = "events"
}

module "sns" {
  source = "../../modules/sns"

  project            = var.project
  env                = var.env
  topic_name         = "notifications"
  notification_email = var.notification_email
}

# -----------------------------------------------------------------------------
# Module: EventBridge
# (depends on SQS and SNS — passes their ARNs)
# -----------------------------------------------------------------------------
module "eventbridge" {
  source = "../../modules/eventbridge"

  project       = var.project
  env           = var.env
  bus_name      = "bus"
  sns_topic_arn = module.sns.topic_arn
  sqs_queue_arn = module.sqs.queue_arn
}

# -----------------------------------------------------------------------------
# Module: IAM
# (depends on DynamoDB, SQS, SNS, EventBridge — passes their ARNs)
# -----------------------------------------------------------------------------
module "iam" {
  source = "../../modules/iam"

  project             = var.project
  env                 = var.env
  dynamodb_table_arn  = module.dynamodb.table_arn
  sqs_queue_arn       = module.sqs.queue_arn
  sns_topic_arn       = module.sns.topic_arn
  eventbridge_bus_arn = module.eventbridge.bus_arn
}



# -----------------------------------------------------------------------------
# Module: Lambda + API Gateway
# -----------------------------------------------------------------------------
module "lambda" {
  source = "../../modules/lambda"

  project         = var.project
  env             = var.env
  lambda_role_arn = module.iam.lambda_role_arn
  table_name      = module.dynamodb.table_name
  event_bus_name  = module.eventbridge.bus_name
  source_dir      = "${path.root}/../../../lambda/producer"
  log_level       = "INFO"
}


# -----------------------------------------------------------------------------
# Module: Monitoring (CloudWatch dashboard + alarms)
# -----------------------------------------------------------------------------
module "monitoring" {
  source = "../../modules/monitoring"

  project              = var.project
  env                  = var.env
  aws_region           = var.aws_region
  lambda_function_name = module.lambda.lambda_function_name
  api_gateway_id       = module.lambda.api_id
  dynamodb_table_name  = module.dynamodb.table_name
  sqs_queue_name       = module.sqs.queue_name
  sqs_dlq_name         = module.sqs.dlq_name
  sns_topic_arn        = module.sns.topic_arn
}



# -----------------------------------------------------------------------------
# Module: eks
# -----------------------------------------------------------------------------
module "eks" {
  source = "../../modules/eks"

  cluster_name    = "awsevt-eks-staging"
  cluster_version = "1.30"
  vpc_id          = module.vpc.vpc_id
  subnet_ids      = module.vpc.public_subnet_ids

  node_instance_type = "t3.medium" # ← was t3.small
  desired_size       = 2           # ← was 1
  min_size           = 1
  max_size           = 3
}

# -----------------------------------------------------------------------------
# Module: Allow terraform-admin user to access the EKS cluster
# -----------------------------------------------------------------------------

resource "aws_eks_access_entry" "terraform_admin" {
  cluster_name  = module.eks.cluster_name
  principal_arn = "arn:aws:iam::008692858099:user/terraform-admin"
  type          = "STANDARD"

  depends_on = [module.eks]
}

resource "aws_eks_access_policy_association" "terraform_admin" {
  cluster_name  = module.eks.cluster_name
  principal_arn = "arn:aws:iam::008692858099:user/terraform-admin"
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"

  access_scope {
    type = "cluster"
  }

  depends_on = [aws_eks_access_entry.terraform_admin]
}


# CI/CD pipeline trigger — 2026-10-16T21:10:18Z

# Retrigger after immutable subject fix 20261016-214019

# Retrigger after tfvars fix 20261016-214227
# Trigger EKS apply
