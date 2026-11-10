import base64
import json
import logging
import os

import boto3

logger = logging.getLogger()
logger.setLevel(logging.INFO)

sns = boto3.client("sns")
TOPIC_ARN = os.environ["SNS_TOPIC_ARN"]

MAX_PAYLOAD_CHARACTERS = 2000


def slack_escape(text):
    # Stops event content from creating Slack mentions or links
    return text.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")


def notification(record, name, payload):
    payload_text = json.dumps(payload, indent=2, sort_keys=True)
    if len(payload_text) > MAX_PAYLOAD_CHARACTERS:
        payload_text = payload_text[:MAX_PAYLOAD_CHARACTERS] + "\n... (truncated)"
    return {
        "version": "1.0",
        "source": "custom",
        "id": f"{record['topic']}-{record['partition']}-{record['offset']}",
        "content": {
            "textType": "client-markdown",
            "title": f"Event received: {slack_escape(name)}",
            "description": f"Payload:\n```{slack_escape(payload_text)}```",
        },
        "metadata": {"enableCustomActions": False},
    }


def lambda_handler(event, context):
    for records in event["records"].values():
        for record in records:
            try:
                message = json.loads(base64.b64decode(record["value"]))
                name, payload = message["name"], message["payload"]
            except (ValueError, KeyError, TypeError):
                # A message that can never be parsed must not block the partition
                logger.exception(
                    "Skipping malformed record %s-%s-%s",
                    record["topic"],
                    record["partition"],
                    record["offset"],
                )
                continue

            # An exception here makes Lambda retry the batch
            sns.publish(TopicArn=TOPIC_ARN, Message=json.dumps(notification(record, name, payload)))
            logger.info(
                "Sent event %s (%s-%s-%s) to Slack",
                name,
                record["topic"],
                record["partition"],
                record["offset"],
            )
