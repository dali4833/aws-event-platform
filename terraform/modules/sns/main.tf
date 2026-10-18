# -----------------------------------------------------------------------------
# SNS topic for notifications
# -----------------------------------------------------------------------------
resource "aws_sns_topic" "main" {
  name = "${var.project}-${var.topic_name}-${var.env}"

  tags = {
    Name        = "${var.project}-${var.topic_name}-${var.env}"
    Project     = var.project
    Environment = var.env
    ManagedBy   = "terraform"
  }
}


# -----------------------------------------------------------------------------
# Email subscription (only if email is provided)
# -----------------------------------------------------------------------------
resource "aws_sns_topic_subscription" "email" {
  count = var.notification_email != "" ? 1 : 0

  topic_arn = aws_sns_topic.main.arn
  protocol  = "email"
  endpoint  = var.notification_email
}


# -----------------------------------------------------------------------------
# SNS topic policy — allows EventBridge to publish
# -----------------------------------------------------------------------------
resource "aws_sns_topic_policy" "events_publish" {
  arn = aws_sns_topic.main.arn

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowEventBridgeToPublish"
        Effect = "Allow"
        Principal = {
          Service = "events.amazonaws.com"
        }
        Action   = "sns:Publish"
        Resource = aws_sns_topic.main.arn
      }
    ]
  })
}
