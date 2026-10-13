# -----------------------------------------------------------------------------
# DynamoDB events table
# -----------------------------------------------------------------------------
resource "aws_dynamodb_table" "events" {
  name         = "${var.project}-${var.table_name}-${var.env}"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "event_id"
  range_key    = "timestamp"

  attribute {
    name = "event_id"
    type = "S"
  }

  attribute {
    name = "timestamp"
    type = "N"
  }

  point_in_time_recovery {
    enabled = true
  }

  server_side_encryption {
    enabled = true
  }

  tags = {
    Name        = "${var.project}-${var.table_name}-${var.env}"
    Project     = var.project
    Environment = var.env
    ManagedBy   = "terraform"
  }
}
