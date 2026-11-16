import json
import logging
import os
from datetime import datetime, timedelta, timezone
from urllib import error, request

import boto3
from botocore.exceptions import ClientError

logger = logging.getLogger()
logger.setLevel(os.getenv("LOG_LEVEL", "INFO"))


def send_slack_notification(region, message):
    secret_name = os.environ["SLACK_WEBHOOK_SECRET_NAME"]
    secretsmanager = boto3.client("secretsmanager", region_name=region)

    try:
        secret_value = secretsmanager.get_secret_value(SecretId=secret_name)
        webhook_url = secret_value["SecretString"]
    except ClientError as exc:
        logger.error(
            "Failed to fetch Slack webhook secret %s: %s",
            secret_name,
            str(exc),
        )
        raise

    payload = json.dumps({"Message": message})
    req = request.Request(
        webhook_url,
        data=payload.encode("utf-8"),
        headers={"Content-Type": "application/json"},
        method="POST",
    )

    try:
        with request.urlopen(req, timeout=10) as response:  # nosec B310
            logger.info("Slack notification sent with status: %s", response.status)
    except error.URLError as exc:
        logger.error("Failed to send Slack notification: %s", str(exc))
        raise


def handler(event, context):  # pylint: disable=unused-argument

    land_bucket = os.environ["LAND_BUCKET"]
    region = os.environ["REGION"]
    days_back = int(os.getenv("DAYS_BACK", "1"))

    s3 = boto3.resource("s3", region_name=region)

    try:
        bucket = s3.Bucket(land_bucket)
        latest_modified = None
        latest_key = None

        for obj in bucket.objects.all():
            object_modified = obj.last_modified
            if latest_modified is None or object_modified > latest_modified:
                latest_modified = object_modified
                latest_key = obj.key

        if latest_modified is None or latest_key is None:
            send_slack_notification(
                region,
                f"No files found in bucket {land_bucket}.",
            )
            logger.warning("No files found in bucket %s", land_bucket)
            return

        expected_date = (datetime.now(timezone.utc) - timedelta(days=days_back)).date()
        latest_modified_date = latest_modified.astimezone(timezone.utc).date()

        if latest_modified_date != expected_date:
            send_slack_notification(
                region,
                (
                    f"Most recent file in {land_bucket} is {latest_key} with LastModified "
                    f"{latest_modified.isoformat()}, expected date {expected_date.isoformat()}."
                ),
            )
            logger.warning(
                "Latest object %s has LastModified %s, expected date %s",
                latest_key,
                latest_modified.isoformat(),
                expected_date.isoformat(),
            )
            return

        logger.info(
            "Latest object %s in %s is recent enough (LastModified %s).",
            latest_key,
            land_bucket,
            latest_modified.isoformat(),
        )

    except Exception as exc:
        logger.error("Error checking latest object in bucket: %s", str(exc))
        raise
