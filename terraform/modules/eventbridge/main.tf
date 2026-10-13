# -----------------------------------------------------------------------------
# EventBridge custom bus
# -----------------------------------------------------------------------------
resource "aws_cloudwatch_event_bus" "main" {
  name = "${var.project}-${var.bus_name}-${var.env}"

  tags = {
    Name        = "${var.project}-${var.bus_name}-${var.env}"
    Project     = var.project
    Environment = var.env
    ManagedBy   = "terraform"
  }
}

# -----------------------------------------------------------------------------
# Rule 1: high-priority events → SNS
# -----------------------------------------------------------------------------
resource "aws_cloudwatch_event_rule" "high_priority" {
  name           = "${var.project}-high-priority-${var.env}"
  description    = "Route high-priority events to SNS"
  event_bus_name = aws_cloudwatch_event_bus.main.name

  event_pattern = jsonencode({
    detail = {
      priority = ["high"]
    }
  })

  tags = {
    Name        = "${var.project}-high-priority-${var.env}"
    Project     = var.project
    Environment = var.env
    ManagedBy   = "terraform"
  }
}

resource "aws_cloudwatch_event_target" "high_priority_to_sns" {
  rule           = aws_cloudwatch_event_rule.high_priority.name
  event_bus_name = aws_cloudwatch_event_bus.main.name
  arn            = var.sns_topic_arn
}

# -----------------------------------------------------------------------------
# Rule 2: processing_required events → SQS
# -----------------------------------------------------------------------------
resource "aws_cloudwatch_event_rule" "processing" {
  name           = "${var.project}-processing-${var.env}"
  description    = "Route processing events to SQS"
  event_bus_name = aws_cloudwatch_event_bus.main.name

  event_pattern = jsonencode({
    detail = {
      type = ["processing_required"]
    }
  })

  tags = {
    Name        = "${var.project}-processing-${var.env}"
    Project     = var.project
    Environment = var.env
    ManagedBy   = "terraform"
  }
}

resource "aws_cloudwatch_event_target" "processing_to_sqs" {
  rule           = aws_cloudwatch_event_rule.processing.name
  event_bus_name = aws_cloudwatch_event_bus.main.name
  arn            = var.sqs_queue_arn
}
