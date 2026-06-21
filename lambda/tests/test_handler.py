"""
Unit tests for the visitor counter Lambda handler.
Run with: pytest lambda/tests/
"""
import os
import json
import importlib

import boto3
import pytest
from moto import mock_aws

TABLE_NAME = "test-visitor-table"


@pytest.fixture
def lambda_environment(monkeypatch):
    monkeypatch.setenv("TABLE_NAME", TABLE_NAME)
    monkeypatch.setenv("AWS_DEFAULT_REGION", "us-east-1")


@pytest.fixture
def dynamodb_table(lambda_environment):
    with mock_aws():
        client = boto3.client("dynamodb", region_name="us-east-1")
        client.create_table(
            TableName=TABLE_NAME,
            KeySchema=[{"AttributeName": "id", "KeyType": "HASH"}],
            AttributeDefinitions=[{"AttributeName": "id", "AttributeType": "S"}],
            BillingMode="PAY_PER_REQUEST",
        )
        yield client


def _reload_handler():
    """Re-import handler so it picks up the mocked boto3 resource."""
    import sys
    if "handler" in sys.modules:
        del sys.modules["handler"]
    sys.path.insert(0, os.path.join(os.path.dirname(__file__), "..", "src"))
    return importlib.import_module("handler")


def test_first_visit_returns_count_one(dynamodb_table):
    handler_module = _reload_handler()
    response = handler_module.handler({}, None)

    assert response["statusCode"] == 200
    body = json.loads(response["body"])
    assert body["visitors"] == 1


def test_count_increments_on_each_call(dynamodb_table):
    handler_module = _reload_handler()
    handler_module.handler({}, None)
    handler_module.handler({}, None)
    response = handler_module.handler({}, None)

    body = json.loads(response["body"])
    assert body["visitors"] == 3


def test_response_has_cors_header(dynamodb_table):
    handler_module = _reload_handler()
    response = handler_module.handler({}, None)

    assert response["headers"]["Access-Control-Allow-Origin"] == "*"


def test_missing_table_name_returns_500(monkeypatch):
    monkeypatch.delenv("TABLE_NAME", raising=False)
    handler_module = _reload_handler()
    response = handler_module.handler({}, None)

    assert response["statusCode"] == 500
