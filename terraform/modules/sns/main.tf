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
