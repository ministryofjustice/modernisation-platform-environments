#This Lambda function processes CloudWatch log events from the payment upload Lambda.
#It extracts, cleans, and formats the logs—removing duplicates and sensitive data.
#Then it sends a single success or failure notification to Slack when the upload finishes.

import base64
import gzip
import json
import logging
import os
import time
import hashlib
from typing import Any, Dict, List, Optional, Tuple, Union, cast

import boto3
import pycurl
from mypy_boto3_secretsmanager import SecretsManagerClient

logger = logging.getLogger()
logger.setLevel(logging.INFO)

MAX_MESSAGE_SIZE: int = 256 * 1024
SENSITIVE_KEYS: set = {"password", "secret", "authorization", "access_key"}

CREDENTIAL_LINE = "Found credentials in environment variables."


class ConfigValidator:
    @staticmethod
    def get_mandatory_secret(secrets_data: Dict, key: str) -> str:
        value = secrets_data.get(key)
        if not value or not isinstance(value, str):
            raise ValueError(f"{key} must be a non-empty string in secrets")
        return value


class SecretsManager:
    def __init__(self):
        self.client = cast(SecretsManagerClient, boto3.client("secretsmanager"))

    def get_credentials(self, secret_name: str) -> Dict[str, Union[str, int, bool]]:
        response = self.client.get_secret_value(SecretId=secret_name)
        return json.loads(response["SecretString"])


def get_env_variable(key: str, required: bool = True) -> Optional[str]:
    value = os.environ.get(key)
    if required and not value:
        raise ValueError(f"Required environment variable {key} is not set")
    return value


class NotificationService:
    def __init__(self, webhook_url: str, function_name: str = "CCMS EBS Lambda"):
        self.webhook_url = webhook_url
        self.function_name = function_name

    def send_notification(self, title: str, message: str, is_error: bool = False) -> bool:
        curl = pycurl.Curl()
        try:
            emoji = ":broken_heart:" if is_error else ":tada:"
            color = "danger" if is_error else "good"

            payload = {
                "attachments": [
                    {
                        "color": color,
                        "title": f"{emoji} [{self.function_name}] {title}",
                        "text": "\n\n" + message,  
                        "footer": "CCMS EBS Lambda",
                        "ts": int(time.time()),
                    }
                ]
            }

            curl.setopt(pycurl.URL, self.webhook_url)
            curl.setopt(pycurl.POST, 1)
            curl.setopt(pycurl.POSTFIELDS, json.dumps(payload))
            curl.setopt(pycurl.HTTPHEADER, ["Content-Type: application/json"])
            curl.setopt(pycurl.TIMEOUT, 10)
            curl.perform()
            return True

        finally:
            curl.close()


def lambda_handler(event: Dict[str, Any], context: Optional[Any]) -> Dict[str, Any]:
    try:
        if not validate_event(event):
            return {"statusCode": 400, "body": {"error": "Invalid event structure"}}

        secret_name = get_env_variable("SECRET_NAME")
        secrets_manager = SecretsManager()
        secrets_data = secrets_manager.get_credentials(secret_name)
        slack_webhook_url = ConfigValidator.get_mandatory_secret(secrets_data, "slack_channel_webhook")

        notification_service = NotificationService(
            slack_webhook_url,
            context.function_name if context else "CCMS EBS Lambda"
        )

        log_data = process_log_data(event["awslogs"]["data"])
        if not log_data:
            return {"statusCode": 400, "body": {"error": "No log data to process"}}

        combined_logs, is_error = process_all_events(log_data.get("logEvents", []))
        if not combined_logs:
            return {"statusCode": 200, "body": {"message": "No log events to process"}}

        # Build final message
        final_message = f"Details:\n{CREDENTIAL_LINE}\n{combined_logs}"

        # Only send Slack when the upload is fully completed
        if "finish_upload_file" not in combined_logs:
            return {"statusCode": 200, "body": {"message": "Waiting for final log batch"}}

        # Dedupe based on full-message hash
        msg_hash = hashlib.sha256(final_message.encode("utf-8")).hexdigest()
        hash_file = "/tmp/last_notification_hash"

        if os.path.exists(hash_file):
            old_hash = open(hash_file).read().strip()
            if old_hash == msg_hash:
                return {"statusCode": 200, "body": {"message": "Duplicate notification skipped"}}

        with open(hash_file, "w") as f:
            f.write(msg_hash)

        status_text = "Payment load lambda fail" if is_error else "Payment load lambda successful"
        title = status_text

        notification_service.send_notification(title, final_message, is_error)

        return {"statusCode": 200, "body": {"message": "Notification sent"}}

    except Exception as e:
        return {"statusCode": 500, "body": {"error": str(e)}}


def validate_event(event: Dict[str, Any]) -> bool:
    return bool(event.get("awslogs") and event["awslogs"].get("data"))


def process_log_data(log_data: str) -> Optional[Dict[str, Any]]:
    try:
        decoded = base64.b64decode(log_data)
        decompressed = gzip.decompress(decoded)
        return json.loads(decompressed)
    except:
        return None


def process_all_events(log_events: List[Dict[str, Any]]) -> Tuple[Optional[str], bool]:
    if not log_events:
        return None, False

    message_parts = []
    is_error = False

    for ev in log_events:
        try:
            message = json.loads(ev["message"])
            msg = message.get("message") or message.get("errorMessage")
            if not msg:
                continue

            if msg.strip() == CREDENTIAL_LINE:
                continue

            redact_sensitive_data(message)

            level = (
                message.get("level")
                or message.get("log_level")
                or message.get("type")
                or message.get("severity")
                or "UNKNOWN"
            )

            if level.upper() == "ERROR":
                is_error = True

            message_parts.append(msg)
        except:
            continue

    if not message_parts:
        return None, is_error

    combined = "\n".join(message_parts)
    if len(combined) > MAX_MESSAGE_SIZE:
        combined = combined[:MAX_MESSAGE_SIZE - 100] + "\n...TRUNCATED..."

    return combined, is_error


def redact_sensitive_data(message: Dict[str, Any]) -> None:
    for key in SENSITIVE_KEYS:
        if key in message:
            message[key] = "**REDACTED**"