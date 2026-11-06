import json
import os

import boto3
from botocore.config import Config
from worker import Store, process
from retention import Retainer

CONFIG = json.loads(os.environ["CONFIG"])
AWS_CONFIG = Config(connect_timeout=3, read_timeout=5, retries={"max_attempts": 2})
SECRETS = boto3.client("secretsmanager", config=AWS_CONFIG)
SNS = boto3.client("sns", config=AWS_CONFIG)
STORE = Store(boto3.resource("dynamodb", config=AWS_CONFIG).Table(os.environ["IDEMPOTENCY_TABLE"]))


def publish_notification(topic_arn, payload):
    SNS.publish(TopicArn=topic_arn, Message=json.dumps(payload))


def lambda_handler(event, context):
    retainer = Retainer(boto3.client("s3", config=Config(signature_version="s3v4", connect_timeout=3,
                        read_timeout=45, retries={"max_attempts": 2})), STORE.table,
                        CONFIG["pickup_bucket"], CONFIG["pickup_kms_key"], context.get_remaining_time_in_millis)
    failures = []
    for record in event.get("Records", []):
        try:
            outcome = process(record, CONFIG, STORE, SECRETS, send=publish_notification, retainer=retainer)
            print(json.dumps({"outcome": outcome}))
        except Exception:
            # Avoid including file metadata or credentials from SDK exceptions in logs.
            print(json.dumps({"outcome": "failed"}))
            failures.append({"itemIdentifier": record["messageId"]})
    return {"batchItemFailures": failures}
