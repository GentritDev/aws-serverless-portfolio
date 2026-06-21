"""
Visitor counter Lambda.

Handles GET /visitors from API Gateway (HTTP API, payload format 2.0).
Atomically increments a counter item in DynamoDB and returns the new total.

Environment variables:
    TABLE_NAME - DynamoDB table name (injected by Terraform)
"""
import json
import os
import logging

import boto3
from botocore.exceptions import ClientError

logger = logging.getLogger()
logger.setLevel(logging.INFO)

dynamodb = boto3.resource("dynamodb")
TABLE_NAME = os.environ.get("TABLE_NAME")
COUNTER_ID = "visitor_count"


def handler(event, context):
    logger.info("Received event: %s", json.dumps(event))

    if TABLE_NAME is None:
        return _response(500, {"error": "TABLE_NAME environment variable is not set"})

    table = dynamodb.Table(TABLE_NAME)

    try:
        result = table.update_item(
            Key={"id": COUNTER_ID},
            UpdateExpression="ADD #c :incr",
            ExpressionAttributeNames={"#c": "count"},
            ExpressionAttributeValues={":incr": 1},
            ReturnValues="UPDATED_NEW",
        )
        count = int(result["Attributes"]["count"])
        return _response(200, {"visitors": count})

    except ClientError as exc:
        logger.error("DynamoDB error: %s", exc, exc_info=True)
        return _response(500, {"error": "Could not update visitor count"})


def _response(status_code: int, body: dict):
    return {
        "statusCode": status_code,
        "headers": {
            "Content-Type": "application/json",
            "Access-Control-Allow-Origin": "*",
        },
        "body": json.dumps(body),
    }
