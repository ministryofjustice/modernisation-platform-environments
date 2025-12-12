"""
Lambda Function: CCMS SOA EDN Quiesced Monitor
------------------------------------------------
Triggered by a CloudWatch Logs Subscription Filter when SOA logs contain:

    "QUIESCING this server due to upper mark DB allocated threshold..."

This Lambda sends a critical notification to Slack including:
- Triggering log event and timestamp
- Log stream source
- Nearby contextual log lines (before & after event)

Purpose:
- Notify support teams in real-time when EDN begins quiescing due to
  SOA DB space reaching critical thresholds in Managed servers.
"""

import os
import base64
import gzip
import json
import logging
import tracemalloc
import time
from dataclasses import dataclass
from typing import Any, Dict, Union, cast

import boto3
import urllib3
from botocore.exceptions import ClientError
from mypy_boto3_secretsmanager import SecretsManagerClient

logs_client = boto3.client("logs")
http = urllib3.PoolManager()

logger = logging.getLogger()
logger.setLevel(logging.INFO)


# ---------------------------------------------------------------------------
# CONFIG VALIDATION HELPERS
# ---------------------------------------------------------------------------
class ConfigValidator:
    @staticmethod
    def validate_mandatory_fields(config_dict: Dict[str, Any], field_name: str) -> None:
        missing_fields = [k for k, v in config_dict.items() if not v]
        if missing_fields:
            raise ValueError(
                f"Missing required {field_name} fields: {', '.join(missing_fields)}"
            )


# ---------------------------------------------------------------------------
# CONFIG DATA CLASS
# ---------------------------------------------------------------------------
@dataclass
class ValidateConfig:
    slack_channel_webhook: str
    LOG_GROUP_NAME: str

    def __post_init__(self):
        ConfigValidator.validate_mandatory_fields(
            {"slack_channel_webhook": self.slack_channel_webhook}, "configuration"
        )
        logger.info("Configuration validated")


# ---------------------------------------------------------------------------
# SLACK NOTIFICATION SERVICE
# ---------------------------------------------------------------------------
class NotificationService:
    def __init__(self, webhook_url: str, function_name: str):
        self.webhook_url = webhook_url
        self.function_name = function_name

    def send_notification(self, title: str, message: str, is_error: bool = False) -> bool:
        try:
            payload = json.dumps({
                "attachments": [
                    {
                        "color": "danger" if is_error else "good",
                        "title": f":rotating_light: [{self.function_name}] {title}",
                        "text": message,
                        "footer": "CCMS SOA EDN Quiesced Lambda",
                        "ts": int(time.time())
                    }
                ]
            })

            resp = http.request(
                "POST",
                self.webhook_url,
                body=payload,
                headers={"Content-Type": "application/json"}
            )

            if resp.status >= 400:
                raise Exception(f"Slack webhook error {resp.status}")

            return True

        except Exception as e:
            logger.error(f"Slack notification failed: {e}")
            return False


# ---------------------------------------------------------------------------
# SECRETS MANAGER FETCHER
# ---------------------------------------------------------------------------
class SecretsManager:
    def __init__(self):
        self.client = cast(SecretsManagerClient, boto3.client("secretsmanager"))

    def get_credentials(self, secret_name: str) -> Dict[str, Union[str, int, bool]]:
        response = self.client.get_secret_value(SecretId=secret_name)
        return json.loads(response["SecretString"])


# ---------------------------------------------------------------------------
# MAIN HANDLER
# ---------------------------------------------------------------------------
def lambda_handler(event, context):
    tracemalloc.start()
    logger.info("CCMS SOA EDN Quiesced Monitoring Lambda started")

    notification_service = None

    try:
        LOG_GROUP_NAME = os.environ["LOG_GROUP_NAME"]
        secret_name = os.environ["SECRET_NAME"]

        # Load Slack webhook secret
        secrets_data = SecretsManager().get_credentials(secret_name)
        config = ValidateConfig(
            slack_channel_webhook=secrets_data["slack_channel_webhook"],
            LOG_GROUP_NAME=LOG_GROUP_NAME
        )

        notification_service = NotificationService(
            config.slack_channel_webhook, context.function_name
        )

        # Decode CloudWatch Logs event
        compressed = base64.b64decode(event["awslogs"]["data"])
        payload = json.loads(gzip.decompress(compressed))
        log_stream_name = payload["logStream"]

        for log_event in payload["logEvents"]:
            message = log_event["message"]
            timestamp = log_event["timestamp"]

            # -------------------------------------------------------------------
            # FETCH NEARBY LOGS (before & after event)
            # -------------------------------------------------------------------
            window_ms = 30000  # 30 seconds around the triggering event

            response = logs_client.get_log_events(
                logGroupName=config.LOG_GROUP_NAME,
                logStreamName=log_stream_name,
                startTime=timestamp - window_ms,
                endTime=timestamp + window_ms,
                limit=20
            )

            nearby_logs = "\n".join(e["message"] for e in response["events"])

            # -------------------------------------------------------------------
            # BUILD MESSAGE
            # -------------------------------------------------------------------
            formatted_message = (
                "*DB Quiescing Detected in CCMS SOA*\n\n"
                f"*Log stream*: `{log_stream_name}`\n"
                f"*Timestamp*: `{timestamp}`\n"
                f"*Message Triggered*:\n```{message}```\n\n"
                "*Nearby logs:*\n```" + nearby_logs + "```"
            )

            # Send notification to Slack
            notification_service.send_notification(
                "EDN Quiescing Due to DB Threshold",
                formatted_message,
                is_error=True
            )

        return {"statusCode": 200}

    except Exception as e:
        logger.error(f"Lambda execution failed: {e}", exc_info=True)

        if notification_service:
            notification_service.send_notification(
                "Lambda Execution Failure", str(e), True
            )

        return {"statusCode": 500, "error": str(e)}

    finally:
        tracemalloc.stop()
