# -----------------------------------------------------------------------------
# Package the Lambda source code into a zip
# -----------------------------------------------------------------------------
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = var.source_dir
  output_path = "${path.module}/build/producer.zip"
}

# -----------------------------------------------------------------------------
# Lambda function
# -----------------------------------------------------------------------------
resource "aws_lambda_function" "producer" {
  function_name = "${var.project}-producer-${var.env}"
  description   = "Producer Lambda for ${var.project} ${var.env}"

  role          = var.lambda_role_arn
  handler       = "handler.handler"
  runtime       = "python3.12"
  architectures = ["arm64"]

  filename         = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  timeout     = 10
  memory_size = 256

  environment {
    variables = {
      TABLE_NAME     = var.table_name
      EVENT_BUS_NAME = var.event_bus_name
      LOG_LEVEL      = var.log_level
    }
  }

  tracing_config {
    mode = "Active"
  }

  tags = {
    Name        = "${var.project}-producer-${var.env}"
    Project     = var.project
    Environment = var.env
    ManagedBy   = "terraform"
  }
}



# -----------------------------------------------------------------------------
# API Gateway HTTP API
# -----------------------------------------------------------------------------
resource "aws_apigatewayv2_api" "main" {
  name          = "${var.project}-api-${var.env}"
  description   = "HTTP API for ${var.project} ${var.env}"
  protocol_type = "HTTP"

  cors_configuration {
    allow_origins = ["*"]
    allow_methods = ["POST", "OPTIONS"]
    allow_headers = ["content-type"]
    max_age       = 300
  }

  tags = {
    Name        = "${var.project}-api-${var.env}"
    Project     = var.project
    Environment = var.env
    ManagedBy   = "terraform"
  }
}

# -----------------------------------------------------------------------------
# API Gateway → Lambda integration
# -----------------------------------------------------------------------------
resource "aws_apigatewayv2_integration" "lambda" {
  api_id = aws_apigatewayv2_api.main.id

  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.producer.invoke_arn
  payload_format_version = "2.0"
}

# -----------------------------------------------------------------------------
# Route: POST /events
# -----------------------------------------------------------------------------
resource "aws_apigatewayv2_route" "post_events" {
  api_id    = aws_apigatewayv2_api.main.id
  route_key = "POST /events"
  target    = "integrations/${aws_apigatewayv2_integration.lambda.id}"
}

# -----------------------------------------------------------------------------
# Default stage (auto-deploy)
# -----------------------------------------------------------------------------
resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.main.id
  name        = "$default"
  auto_deploy = true

  tags = {
    Name        = "${var.project}-api-stage-${var.env}"
    Project     = var.project
    Environment = var.env
    ManagedBy   = "terraform"
  }
}

# -----------------------------------------------------------------------------
# Permission: allow API Gateway to invoke Lambda
# -----------------------------------------------------------------------------
resource "aws_lambda_permission" "apigw" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.producer.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.main.execution_arn}/*/*"
}
