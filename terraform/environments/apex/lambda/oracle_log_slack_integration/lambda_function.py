"""
AWS Lambda function to process CloudWatch Logs subscription events for Oracle ORA- errors
and publish the matching messages into Slack.
"""

import base64
import gzip
import io
import json
import logging
import os
import re
from typing import Any, Dict, Union
from urllib.parse import quote_plus

logger = logging.getLogger()
logger.setLevel(logging.INFO)

try:
    import boto3
    from botocore.exceptions import ClientError
except ImportError:  # pragma: no cover - exercised in lightweight test environments
    boto3 = None
    ClientError = Exception

try:
    import pycurl
except ImportError:  # pragma: no cover - exercised in lightweight test environments
    pycurl = None


class SecretsManager:
    """Retrieve secrets from AWS Secrets Manager."""

    def __init__(self):
        if boto3 is None:
            raise RuntimeError("boto3 is required to use SecretsManager")
        self.client = boto3.client("secretsmanager")
        logger.info("Initialized Secrets Manager client")

    def get_credentials(self, secret_name: str) -> Dict[str, Union[str, int, bool]]:
        """Retrieve and parse credentials from Secrets Manager."""
        try:
            response = self.client.get_secret_value(SecretId=secret_name)
            return json.loads(response["SecretString"])
        except ClientError as e:
            error_code = e.response["Error"]["Code"]
            raise RuntimeError(f"Failed to retrieve secret {secret_name}: {error_code}") from e
        except json.JSONDecodeError as e:
            raise RuntimeError(f"Failed to parse secret JSON: {e}") from e


def decode_cloudwatch_logs_payload(encoded_data: str) -> Dict[str, Any]:
    """Decode CloudWatch Logs payload from AWS Logs subscription format."""
    decoded_bytes = base64.b64decode(encoded_data)
    with gzip.GzipFile(fileobj=io.BytesIO(decoded_bytes)) as gzip_file:
        payload = gzip_file.read()
    return json.loads(payload)


def extract_ora_events_from_log_payload(log_payload: Dict[str, Any]) -> list[Dict[str, Any]]:
    """Extract ORA-XXXXX events from decoded CloudWatch Logs payload."""
    events: list[Dict[str, Any]] = []
    ora_pattern = re.compile(r"(ORA-\d{5})", re.IGNORECASE)

    for log_event in log_payload.get("logEvents", []):
        message = log_event.get("message", "")
        matched_codes = ora_pattern.findall(message)
        if matched_codes:
            cleaned_message = re.sub(r"\s+", " ", message).strip()
            events.append(
                {
                    "timestamp": log_event.get("timestamp"),
                    "logStream": log_payload.get("logStream", ""),
                    "message": cleaned_message,
                    "codes": matched_codes,
                }
            )

    return events


class NotificationService:
    """Send Oracle log notifications to Slack."""

    def __init__(self, webhook_url: str, environment_name: str = "Unknown"):
        if not webhook_url:
            raise ValueError("Slack webhook URL is required for notifications")
        self.webhook_url = webhook_url
        self.environment_name = environment_name or "Unknown"

    def send_notification(self, alarmdetails: Dict[str, Any]) -> bool:
        """Send a Slack notification for Oracle log events."""
        if pycurl is None:
            raise RuntimeError("pycurl is required to send Slack notifications")

        curl = pycurl.Curl()
        log_group = alarmdetails.get("logGroup", "Unknown Log Group")
        log_stream = alarmdetails.get("logStream", "Unknown Log Stream")
        matched_events = alarmdetails.get("matchedEvents", [])
        region = os.environ.get("AWS_REGION", "eu-west-2")

        escaped_group = quote_plus(log_group)
        escaped_stream = quote_plus(log_stream)
        log_stream_url = (
            f"https://console.aws.amazon.com/cloudwatch/home?region={region}"
            f"#logsV2:log-groups/log-group/{escaped_group}/log-events/{escaped_stream}"
        )

        blocks = [
            {
                "type": "header",
                "text": {
                    "type": "plain_text",
                    "text": f":warning: Oracle Alert Log Events Detected [{self.environment_name}]",
                },
            },
            {
                "type": "section",
                "text": {
                    "type": "mrkdwn",
                    "text": (
                        f"*Environment:* {self.environment_name}\n"
                        f"*Log Group:* {log_group}\n"
                        f"*Log Stream:* <{log_stream_url}|{log_stream}>\n"
                        f"*Matched Events:* {len(matched_events)}"
                    ),
                },
            },
        ]

        for event in matched_events:
            codes = ", ".join(event.get("codes", []))
            message = event.get("message", "")
            blocks.extend(
                [
                    {"type": "divider"},
                    {"type": "section", "text": {"type": "mrkdwn", "text": f"*ORA Code(s):* {codes}"}},
                    {"type": "section", "text": {"type": "mrkdwn", "text": f"```{message}```"}},
                ]
            )

        payload = {"blocks": blocks}
        try:
            json_payload = json.dumps(payload)
            curl.setopt(pycurl.URL, self.webhook_url)
            curl.setopt(pycurl.POST, 1)
            curl.setopt(pycurl.POSTFIELDS, json_payload)
            curl.setopt(pycurl.HTTPHEADER, ["Content-Type: application/json"])
            curl.setopt(pycurl.TIMEOUT, 10)
            response_buffer = io.BytesIO()
            curl.setopt(pycurl.WRITEDATA, response_buffer)
            curl.perform()
            http_code = curl.getinfo(pycurl.RESPONSE_CODE)
            if http_code >= 400:
                raise RuntimeError(f"HTTP error {http_code}")
            return True
        except Exception as exc:
            logger.error("Failed to send Slack notification: %s", exc)
            return False
        finally:
            curl.close()


def lambda_handler(event, context):
    """Main Lambda handler."""
    if "awslogs" not in event:
        logger.warning("Ignoring non-CloudWatch Logs event")
        return {"statusCode": 200, "body": {"message": "No CloudWatch Logs payload"}}

    secret_name = os.environ.get("SECRET_NAME")
    if not secret_name:
        raise ValueError("SECRET_NAME environment variable is required")

    environment_name = os.environ.get("ENVIRONMENT", "Unknown")

    secrets_manager = SecretsManager()
    secrets_data = secrets_manager.get_credentials(secret_name)
    slack_webhook = secrets_data.get("slack_channel_webhook")
    if not isinstance(slack_webhook, str) or not slack_webhook:
        raise ValueError("slack_channel_webhook secret is required")

    log_payload = decode_cloudwatch_logs_payload(event["awslogs"]["data"])
    matched_events = extract_ora_events_from_log_payload(log_payload)
    if not matched_events:
        logger.info("No ORA-XXXX events found in CloudWatch Logs payload")
        return {"statusCode": 200, "body": {"message": "No ORA-XXXX events found"}}

    notification_service = NotificationService(slack_webhook, environment_name)
    notification_service.send_notification(
        {
            "logGroup": log_payload.get("logGroup", ""),
            "logStream": log_payload.get("logStream", ""),
            "matchedEvents": matched_events,
        }
    )

    return {"statusCode": 200, "body": {"message": "Successfully published CloudWatch Logs notification"}}
