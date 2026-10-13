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
