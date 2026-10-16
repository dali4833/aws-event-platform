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
  # AWS now manages the thumbprint automatically for well-known providers
  thumbprint_list = [
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
        Sid    = "GitHubActionsOIDC"
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
            "token.actions.githubusercontent.com:sub" = concat(
              # Immutable format (with numeric IDs) — current GitHub default
              [
                for branch in var.allowed_branches :
                "repo:${var.github_org}@*/${var.github_repo}@*:ref:refs/heads/${branch}"
              ],
              [
                "repo:${var.github_org}@*/${var.github_repo}@*:pull_request"
              ],
              [
                "repo:${var.github_org}@*/${var.github_repo}@*:environment:*"
              ],
              # Legacy format (without numeric IDs)
              [
                for branch in var.allowed_branches :
                "repo:${var.github_org}/${var.github_repo}:ref:refs/heads/${branch}"
              ],
              [
                "repo:${var.github_org}/${var.github_repo}:pull_request"
              ],
              [
                "repo:${var.github_org}/${var.github_repo}:environment:*"
              ]
            )
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
          "ec2:*",
          "lambda:*",
          "apigateway:*",
          "execute-api:*",
          "dynamodb:*",
          "sqs:*",
          "sns:*",
          "events:*",
          "ecr:*",
          "iam:GetRole",
          "iam:GetRolePolicy",
          "iam:GetPolicy",
          "iam:GetPolicyVersion",
          "iam:ListRoles",
          "iam:ListRolePolicies",
          "iam:ListAttachedRolePolicies",
          "iam:ListPolicyVersions",
          "iam:PassRole",
          "logs:*",
          "cloudwatch:*",
          "sts:GetCallerIdentity",
          "tag:GetResources",
        ]
        Resource = "*"
      },
    ]
  })
}
