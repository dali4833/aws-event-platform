# -----------------------------------------------------------------------------
# Dead-letter queue (DLQ)
# -----------------------------------------------------------------------------
resource "aws_sqs_queue" "dlq" {
  name                      = "${var.project}-${var.queue_name}-dlq-${var.env}"
  message_retention_seconds = 1209600 # 14 days

  tags = {
    Name        = "${var.project}-${var.queue_name}-dlq-${var.env}"
    Project     = var.project
    Environment = var.env
    ManagedBy   = "terraform"
    Purpose     = "dead-letter"
  }
}

# -----------------------------------------------------------------------------
# Main SQS queue
# -----------------------------------------------------------------------------
resource "aws_sqs_queue" "main" {
  name                       = "${var.project}-${var.queue_name}-${var.env}"
  visibility_timeout_seconds = var.visibility_timeout_seconds
  message_retention_seconds  = var.message_retention_seconds

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.dlq.arn
    maxReceiveCount     = var.max_receive_count
  })

  tags = {
    Name        = "${var.project}-${var.queue_name}-${var.env}"
    Project     = var.project
    Environment = var.env
    ManagedBy   = "terraform"
  }
}
