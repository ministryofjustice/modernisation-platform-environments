import base64
import json
import logging

logger = logging.getLogger()
logger.setLevel(logging.INFO)


def lambda_handler(event, context):
    for records in event["records"].values():
        for record in records:
            logger.info(
                "Consumed %s-%s-%s key=%s value=%s",
                record["topic"],
                record["partition"],
                record["offset"],
                base64.b64decode(record["key"]).decode("utf-8", errors="replace") if record.get("key") else None,
                base64.b64decode(record["value"]).decode("utf-8", errors="replace"),
            )
