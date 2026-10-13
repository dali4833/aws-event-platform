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

# -----------------------------------------------------------------------------
# Module: SNS
# -----------------------------------------------------------------------------
module "sns" {
  source = "../../modules/sns"

  project    = var.project
  env        = var.env
  topic_name = "notifications"
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
