# -----------------------------------------------------------------------------
# GitHub OIDC Identity Provider
# -----------------------------------------------------------------------------
data "aws_caller_identity" "current" {}

resource "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"

  client_id_list = [
    "sts.amazonaws.com",
  ]

  # GitHub's OIDC thumbprint (root CA)
  # AWS now manages the thumbprint automatically — this is a fallback
  thumbprint_list = [
    "6938fd4d98bab03faadb97b34396831e3780aea1",
    "1c58a3a8518e8759bf075b76b750d4f2df264fcd",
  ]

  tags = {
    Name        = "${var.project}-github-oidc-${var.env}"
    Project     = var.project
    Environment = var.env
    ManagedBy   = "terraform"
  }
}



# -----------------------------------------------------------------------------
# IAM Role for GitHub Actions
# -----------------------------------------------------------------------------
resource "aws_iam_role" "github_actions" {
  name        = "${var.project}-github-actions-${var.env}"
  description = "Role assumed by GitHub Actions workflows for ${var.project} ${var.env}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = "sts:AssumeRoleWithWebIdentity"
        Principal = {
          Federated = aws_iam_openid_connect_provider.github.arn
        }
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }
          StringLike = {
            "token.actions.githubusercontent.com:sub" = [
              for branch in var.allowed_branches :
              "repo:${var.github_org}/${var.github_repo}:ref:refs/heads/${branch}"
            ]
          }
        }
      }
    ]
  })

  tags = {
    Name        = "${var.project}-github-actions-${var.env}"
    Project     = var.project
    Environment = var.env
    ManagedBy   = "terraform"
  }
}



# -----------------------------------------------------------------------------
# IAM Policy — permissions GitHub Actions needs
# -----------------------------------------------------------------------------
resource "aws_iam_role_policy" "github_actions" {
  name = "${var.project}-github-actions-policy-${var.env}"
  role = aws_iam_role.github_actions.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "TerraformStateAccess"
        Effect = "Allow"
        Action = [
          "s3:ListBucket",
          "s3:GetBucketVersioning",
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
        ]
        Resource = [
          "arn:aws:s3:::awsevt-tf-state-*",
          "arn:aws:s3:::awsevt-tf-state-*/*",
          "arn:aws:s3:::awsevt-artifacts-*",
          "arn:aws:s3:::awsevt-artifacts-*/*",
        ]
      },
      {
        Sid    = "TerraformStateLock"
        Effect = "Allow"
        Action = [
          "dynamodb:DescribeTable",
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:DeleteItem",
        ]
        Resource = "arn:aws:dynamodb:eu-west-1:${data.aws_caller_identity.current.account_id}:table/awsevt-tf-lock"
      },
      {
        Sid    = "ManageInfrastructure"
        Effect = "Allow"
        Action = [
          # VPC / EC2
          "ec2:*",
          # Lambda
          "lambda:*",
          # API Gateway
          "apigateway:*",
          "execute-api:*",
          # DynamoDB
          "dynamodb:*",
          # SQS
          "sqs:*",
          # SNS
          "sns:*",
          # EventBridge
          "events:*",
          # ECR
          "ecr:*",
          # IAM (limited)
          "iam:GetRole",
          "iam:GetRolePolicy",
          "iam:GetPolicy",
          "iam:GetPolicyVersion",
          "iam:ListRoles",
          "iam:ListRolePolicies",
          "iam:ListAttachedRolePolicies",
          "iam:ListPolicyVersions",
          "iam:PassRole",
          # CloudWatch
          "logs:*",
          "cloudwatch:*",
          # STS
          "sts:GetCallerIdentity",
          # Tagging
          "tag:GetResources",
        ]
        Resource = "*"
      },
    ]
  })
}
