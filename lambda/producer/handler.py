"""
AWS Event Platform — Producer Lambda

Receives an HTTP POST from API Gateway, validates the payload,
stores the event in DynamoDB, and publishes it to EventBridge
for downstream routing.

Environment variables:
    TABLE_NAME         - DynamoDB table name
    EVENT_BUS_NAME     - EventBridge custom bus name
    LOG_LEVEL          - Logging level (default: INFO)
"""

import json
import os
import logging
import time
import uuid
from typing import Any, Dict

import boto3
from botocore.exceptions import ClientError



# -----------------------------------------------------------------------------
# Configuration
# -----------------------------------------------------------------------------
LOG_LEVEL = os.environ.get("LOG_LEVEL", "INFO")
TABLE_NAME = os.environ["TABLE_NAME"]
EVENT_BUS_NAME = os.environ["EVENT_BUS_NAME"]

logger = logging.getLogger()
logger.setLevel(LOG_LEVEL)

# Reuse clients across invocations (Lambda best practice)
dynamodb = boto3.client("dynamodb")
eventbridge = boto3.client("events")

# -----------------------------------------------------------------------------
# Helpers
# -----------------------------------------------------------------------------
def response(status_code: int, body: Dict[str, Any]) -> Dict[str, Any]:
    """Build a consistent API Gateway response."""
    return {
        "statusCode": status_code,
        "headers": {
            "Content-Type": "application/json",
            "Access-Control-Allow-Origin": "*",
        },
        "body": json.dumps(body),
    }


def validate_event(body: Dict[str, Any]) -> None:
    """Raise ValueError if the payload is invalid."""
    if not isinstance(body, dict):
        raise ValueError("Request body must be a JSON object")
    if "type" not in body:
        raise ValueError("Field 'type' is required")
    if not isinstance(body["type"], str):
        raise ValueError("Field 'type' must be a string")
    if body.get("payload") is not None and not isinstance(body["payload"], dict):
        raise ValueError("Field 'payload' must be a JSON object if provided")
	



# -----------------------------------------------------------------------------
# Handler
# -----------------------------------------------------------------------------
def handler(event: Dict[str, Any], context: Any) -> Dict[str, Any]:
    """
    Main entry point. Called by API Gateway on POST /events.
    """
    request_id = getattr(context, "aws_request_id", "unknown")
    logger.info("Processing request %s", request_id)

    # ---- 1. Parse the request body -----------------------------------------
    try:
        raw_body = event.get("body") or "{}"
        body = json.loads(raw_body)
    except json.JSONDecodeError:
        logger.warning("Invalid JSON in request body")
        return response(400, {"error": "Invalid JSON in request body"})

    # ---- 2. Validate the payload -------------------------------------------
    try:
        validate_event(body)
    except ValueError as exc:
        logger.warning("Validation failed: %s", exc)
        return response(400, {"error": str(exc)})

    # ---- 3. Enrich with server-side fields ---------------------------------
    event_id = body.get("event_id") or str(uuid.uuid4())
    timestamp = int(time.time())
    priority = body.get("priority", "normal")

    item = {
        "event_id": {"S": event_id},
        "timestamp": {"N": str(timestamp)},
        "type": {"S": body["type"]},
        "priority": {"S": priority},
        "payload": {"S": json.dumps(body.get("payload", {}))},
    }

    # ---- 4. Store in DynamoDB ----------------------------------------------
    try:
        dynamodb.put_item(TableName=TABLE_NAME, Item=item)
        logger.info("Stored event %s in DynamoDB", event_id)
    except ClientError as exc:
        logger.exception("Failed to write to DynamoDB")
        return response(500, {"error": "Storage failure"})

    # ---- 5. Publish to EventBridge -----------------------------------------
    try:
        eventbridge.put_events(
            Entries=[
                {
                    "Source": "awsevt.producer",
                    "DetailType": "event.created",
                    "Detail": json.dumps(
                        {
                            "event_id": event_id,
                            "type": body["type"],
                            "priority": priority,
                            "timestamp": timestamp,
                        }
                    ),
                    "EventBusName": EVENT_BUS_NAME,
                }
            ]
        )
        logger.info("Published event %s to EventBridge", event_id)
    except ClientError:
        # Storage already succeeded; log and continue.
        logger.exception("Failed to publish to EventBridge")

    # ---- 6. Respond --------------------------------------------------------
    return response(
        202,
        {
            "event_id": event_id,
            "timestamp": timestamp,
            "status": "accepted",
        },
    )
