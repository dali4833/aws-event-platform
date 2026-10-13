# -----------------------------------------------------------------------------
# IAM role for Lambda
# -----------------------------------------------------------------------------
resource "aws_iam_role" "lambda" {
  name = "${var.project}-lambda-role-${var.env}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name        = "${var.project}-lambda-role-${var.env}"
    Project     = var.project
    Environment = var.env
    ManagedBy   = "terraform"
  }
}

# -----------------------------------------------------------------------------
# IAM policy — permissions for Lambda
# -----------------------------------------------------------------------------
resource "aws_iam_role_policy" "lambda" {
  name = "${var.project}-lambda-policy-${var.env}"
  role = aws_iam_role.lambda.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      },
      {
        Effect = "Allow"
        Action = [
          "dynamodb:PutItem",
          "dynamodb:GetItem",
          "dynamodb:UpdateItem",
          "dynamodb:Query"
        ]
        Resource = var.dynamodb_table_arn
      },
      {
        Effect = "Allow"
        Action = [
          "sqs:SendMessage",
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes"
        ]
        Resource = var.sqs_queue_arn
      },
      {
        Effect = "Allow"
        Action = [
          "sns:Publish"
        ]
        Resource = var.sns_topic_arn
      },
      {
        Effect = "Allow"
        Action = [
          "events:PutEvents"
        ]
        Resource = var.eventbridge_bus_arn
      }
    ]
  })
}

# -----------------------------------------------------------------------------
# Attach AWS-managed basic execution role (CloudWatch Logs)
# -----------------------------------------------------------------------------
resource "aws_iam_role_policy_attachment" "lambda_basic" {
  role       = aws_iam_role.lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# -----------------------------------------------------------------------------
# CloudWatch log group for Lambda
# -----------------------------------------------------------------------------
resource "aws_cloudwatch_log_group" "lambda" {
  name              = "/aws/lambda/${var.project}-producer-${var.env}"
  retention_in_days = 7

  tags = {
    Name        = "/aws/lambda/${var.project}-producer-${var.env}"
    Project     = var.project
    Environment = var.env
    ManagedBy   = "terraform"
  }
}
