# -----------------------------------------------------------------------------
# CloudWatch Dashboard
# -----------------------------------------------------------------------------
resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "${var.project}-${var.env}"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6
        properties = {
          title  = "Lambda — Invocations & Errors"
          region = var.aws_region
          metrics = [
            ["AWS/Lambda", "Invocations", "FunctionName", var.lambda_function_name, { stat = "Sum", label = "Invocations" }],
            [".", "Errors", ".", ".", { stat = "Sum", label = "Errors", color = "#d62728" }],
            [".", "Throttles", ".", ".", { stat = "Sum", label = "Throttles", color = "#ff7f0e" }],
          ]
          view   = "timeSeries"
          period = 300
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 0
        width  = 12
        height = 6
        properties = {
          title  = "Lambda — Duration p50 / p99"
          region = var.aws_region
          metrics = [
            ["AWS/Lambda", "Duration", "FunctionName", var.lambda_function_name, { stat = "p50", label = "p50" }],
            [".", ".", ".", ".", { stat = "p99", label = "p99" }],
          ]
          view   = "timeSeries"
          period = 300
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 6
        width  = 12
        height = 6
        properties = {
          title  = "API Gateway — Requests & Errors"
          region = var.aws_region
          metrics = [
            ["AWS/ApiGateway", "Count", "ApiId", var.api_gateway_id, { stat = "Sum", label = "Total" }],
            [".", "4xx", ".", ".", { stat = "Sum", label = "4xx", color = "#ff7f0e" }],
            [".", "5xx", ".", ".", { stat = "Sum", label = "5xx", color = "#d62728" }],
          ]
          view   = "timeSeries"
          period = 300
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 6
        width  = 12
        height = 6
        properties = {
          title  = "DynamoDB — Consumed Capacity"
          region = var.aws_region
          metrics = [
            ["AWS/DynamoDB", "ConsumedReadCapacityUnits", "TableName", var.dynamodb_table_name, { stat = "Sum" }],
            [".", "ConsumedWriteCapacityUnits", ".", ".", { stat = "Sum" }],
          ]
          view   = "timeSeries"
          period = 300
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 12
        width  = 12
        height = 6
        properties = {
          title  = "SQS — Queue Depth & DLQ"
          region = var.aws_region
          metrics = [
            ["AWS/SQS", "ApproximateNumberOfMessagesVisible", "QueueName", var.sqs_queue_name, { stat = "Average", label = "Main Queue" }],
            [".", ".", ".", var.sqs_dlq_name, { stat = "Average", label = "DLQ", color = "#d62728" }],
          ]
          view   = "timeSeries"
          period = 300
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 12
        width  = 12
        height = 6
        properties = {
          title  = "SNS — Published & Failed"
          region = var.aws_region
          metrics = [
            ["AWS/SNS", "NumberOfMessagesPublished", "TopicName", replace(var.sns_topic_arn, "/^.*:/", ""), { stat = "Sum", label = "Published" }],
            [".", "NumberOfNotificationsFailed", ".", ".", { stat = "Sum", label = "Failed", color = "#d62728" }],
          ]
          view   = "timeSeries"
          period = 300
        }
      },
    ]
  })
}

# -----------------------------------------------------------------------------
# Alarm 1: Lambda errors
# -----------------------------------------------------------------------------
resource "aws_cloudwatch_metric_alarm" "lambda_errors" {
  alarm_name          = "${var.project}-${var.env}-lambda-errors"
  alarm_description   = "Lambda has more than 5 errors in 5 minutes"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  threshold           = 5
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = 300
  statistic           = "Sum"

  dimensions = {
    FunctionName = var.lambda_function_name
  }

  alarm_actions = [var.sns_topic_arn]
  ok_actions    = [var.sns_topic_arn]

  treat_missing_data = "notBreaching"

  tags = {
    Name        = "${var.project}-${var.env}-lambda-errors"
    Project     = var.project
    Environment = var.env
    ManagedBy   = "terraform"
  }
}

# -----------------------------------------------------------------------------
# Alarm 2: API Gateway 5xx
# -----------------------------------------------------------------------------
resource "aws_cloudwatch_metric_alarm" "apigw_5xx" {
  alarm_name          = "${var.project}-${var.env}-apigw-5xx"
  alarm_description   = "API Gateway has more than 10 server errors in 5 minutes"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  threshold           = 10
  metric_name         = "5xx"
  namespace           = "AWS/ApiGateway"
  period              = 300
  statistic           = "Sum"

  dimensions = {
    ApiId = var.api_gateway_id
  }

  alarm_actions = [var.sns_topic_arn]
  ok_actions    = [var.sns_topic_arn]

  treat_missing_data = "notBreaching"

  tags = {
    Name        = "${var.project}-${var.env}-apigw-5xx"
    Project     = var.project
    Environment = var.env
    ManagedBy   = "terraform"
  }
}

# -----------------------------------------------------------------------------
# Alarm 3: DLQ has messages
# -----------------------------------------------------------------------------
resource "aws_cloudwatch_metric_alarm" "dlq_messages" {
  alarm_name          = "${var.project}-${var.env}-dlq-messages"
  alarm_description   = "Dead-letter queue has messages"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  threshold           = 0
  metric_name         = "ApproximateNumberOfMessagesVisible"
  namespace           = "AWS/SQS"
  period              = 300
  statistic           = "Average"

  dimensions = {
    QueueName = var.sqs_dlq_name
  }

  alarm_actions = [var.sns_topic_arn]
  ok_actions    = [var.sns_topic_arn]

  treat_missing_data = "notBreaching"

  tags = {
    Name        = "${var.project}-${var.env}-dlq-messages"
    Project     = var.project
    Environment = var.env
    ManagedBy   = "terraform"
  }
}

# -----------------------------------------------------------------------------
# Alarm 4: Lambda duration p99 > 5s
# -----------------------------------------------------------------------------
resource "aws_cloudwatch_metric_alarm" "lambda_slow" {
  alarm_name          = "${var.project}-${var.env}-lambda-slow"
  alarm_description   = "Lambda p99 duration is over 5 seconds"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  threshold           = 5000
  metric_name         = "Duration"
  namespace           = "AWS/Lambda"
  period              = 300
  extended_statistic  = "p99"

  dimensions = {
    FunctionName = var.lambda_function_name
  }

  alarm_actions = [var.sns_topic_arn]
  ok_actions    = [var.sns_topic_arn]

  treat_missing_data = "notBreaching"

  tags = {
    Name        = "${var.project}-${var.env}-lambda-slow"
    Project     = var.project
    Environment = var.env
    ManagedBy   = "terraform"
  }
}

# -----------------------------------------------------------------------------
# Alarm 5: SNS delivery failures
# -----------------------------------------------------------------------------
resource "aws_cloudwatch_metric_alarm" "sns_failures" {
  alarm_name          = "${var.project}-${var.env}-sns-failures"
  alarm_description   = "SNS has failed to deliver notifications"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  threshold           = 0
  metric_name         = "NumberOfNotificationsFailed"
  namespace           = "AWS/SNS"
  period              = 300
  statistic           = "Sum"

  dimensions = {
    TopicName = replace(var.sns_topic_arn, "/^.*:/", "")
  }

  alarm_actions = [var.sns_topic_arn]
  ok_actions    = [var.sns_topic_arn]

  treat_missing_data = "notBreaching"

  tags = {
    Name        = "${var.project}-${var.env}-sns-failures"
    Project     = var.project
    Environment = var.env
    ManagedBy   = "terraform"
  }
}
