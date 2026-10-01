import json
import os

import boto3
from botocore.config import Config
from worker import Store, process

CONFIG = json.loads(os.environ["CONFIG"])
AWS_CONFIG = Config(connect_timeout=3, read_timeout=5, retries={"max_attempts": 2})
SECRETS = boto3.client("secretsmanager", config=AWS_CONFIG)
STORE = Store(boto3.resource("dynamodb", config=AWS_CONFIG).Table(os.environ["IDEMPOTENCY_TABLE"]))


def lambda_handler(event, context):
    failures = []
    for record in event.get("Records", []):
        try:
            outcome = process(record, CONFIG, STORE, SECRETS)
            print(json.dumps({"outcome": outcome}))
        except Exception:
            # No exception text: SDK/HTTP exceptions can contain webhook credentials.
            print(json.dumps({"outcome": "failed"}))
            failures.append({"itemIdentifier": record["messageId"]})
    return {"batchItemFailures": failures}
