"""
Lambda Function: CCMS SOA EDN Quiesced Monitor
------------------------------------------------
This Lambda is triggered by a CloudWatch Logs Subscription Filter
whenever SOA logs contain a quiescing alert message such as:

    "QUIESCING this server due to upper mark DB allocated threshold..."

It sends a critical notification to Slack including:
- The triggering log line
- Timestamp and log stream source
- Nearby supporting log lines for context

Purpose:
- Provide real-time alerting to Support team when EDN becomes quiesced
  due to DB capacity thresholds being breached in SOA Managed servers.
"""


import io
import os
import base64
import gzip
import json
import logging
import tracemalloc
import time
from dataclasses import dataclass
from typing import Any, Dict, Optional, Union, cast

import boto3
import pycurl
from botocore.exceptions import ClientError
from mypy_boto3_secretsmanager import SecretsManagerClient

logs_client = boto3.client("logs")

logger = logging.getLogger()
logger.setLevel(logging.INFO)


class ConfigValidator:
    @staticmethod
    def validate_mandatory_fields(config_dict: Dict[str, Any], field_name: str) -> None:
        missing_fields = [k for k, v in config_dict.items() if not v]
        if missing_fields:
            raise ValueError(
                f"Missing required {field_name} fields: {', '.join(missing_fields)}"
            )

    @staticmethod
    def get_mandatory_secret(secrets_data: Dict, key: str) -> str:
        value = secrets_data.get(key)
        if not value or not isinstance(value, str):
            raise ValueError(f"{key} must be a non-empty string")
        return value

    @staticmethod
    def get_mandatory_env(env_data: Dict, key: str) -> str:
        value = env_data.get(key)
        if not value:
            raise ValueError(f"{key} environment variable is required")
        return value


@dataclass
class ValidateConfig:
    slack_channel_webhook: str
    LOG_GROUP_NAME: str

    def __post_init__(self):
        ConfigValidator.validate_mandatory_fields(
            {"slack_channel_webhook": self.slack_channel_webhook}, "configuration"
        )
        logger.info("Configuration validated")


class NotificationService:
    def __init__(self, webhook_url: str, function_name: str = "CCMS SOA Quiesced Lambda"):
        self.webhook_url = webhook_url
        self.function_name = function_name

    def send_notification(self, title: str, message: str, is_error: bool = False) -> bool:
        curl = pycurl.Curl()
        try:
            payload = {
                "attachments": [
                    {
                        "color": "danger",
                        "title": f":rotating_light: [{self.function_name}] {title}",
                        "text": message,
                        "footer": "CCMS SOA EDN Quiesced Lambda",
                        "ts": int(time.time())
                    }
                ]
            }
            curl.setopt(pycurl.URL, self.webhook_url)
            curl.setopt(pycurl.POST, 1)
            curl.setopt(pycurl.POSTFIELDS, json.dumps(payload))
            curl.setopt(pycurl.HTTPHEADER, ["Content-Type: application/json"])
            curl.setopt(pycurl.TIMEOUT, 10)
            curl.perform()
            if curl.getinfo(pycurl.RESPONSE_CODE) >= 400:
                raise Exception("Slack webhook returned error")
            return True
        except Exception as e:
            logger.error(f"Slack notification failed: {e}")
            return False
        finally:
            curl.close()


class SecretsManager:
    def __init__(self):
        self.client = cast(SecretsManagerClient, boto3.client("secretsmanager"))

    def get_credentials(self, secret_name: str) -> Dict[str, Union[str, int, bool]]:
        response = self.client.get_secret_value(SecretId=secret_name)
        return json.loads(response["SecretString"])


def get_env_variable(key: str, required: bool = True) -> Optional[str]:
    value = os.environ.get(key)
    if required and not value:
        raise ValueError(f"{key} must be set in Lambda environment")
    return value


def parse_config_from_env_and_secrets(
    env_data: Dict[str, Optional[str]],
    secrets_data: Dict[str, Union[str, int, bool]]
) -> ValidateConfig:

    return ValidateConfig(
        slack_channel_webhook=ConfigValidator.get_mandatory_secret(
            secrets_data, "slack_channel_webhook"
        ),
        LOG_GROUP_NAME=ConfigValidator.get_mandatory_env(env_data, "LOG_GROUP_NAME"),
    )


def lambda_handler(event, context):
    tracemalloc.start()
    logger.info("CCMS SOA EDN Quiesced Monitoring Lambda started")

    notification_service = None

    try:
        env_config = {
            "LOG_GROUP_NAME": get_env_variable("LOG_GROUP_NAME", required=True)
        }

        secret_name = os.environ.get("SECRET_NAME", event.get("secret_name"))
        if not secret_name:
            raise ValueError("SECRET_NAME is required in Lambda environment")

        secrets_data = SecretsManager().get_credentials(secret_name)
        config = parse_config_from_env_and_secrets(env_config, secrets_data)

        notification_service = NotificationService(
            config.slack_channel_webhook, context.function_name
        )

        compressed_payload = base64.b64decode(event["awslogs"]["data"])
        payload = json.loads(gzip.decompress(compressed_payload))
        log_stream_name = payload["logStream"]

        for log_event in payload["logEvents"]:
            message = log_event["message"]
            timestamp = log_event["timestamp"]

            response = logs_client.get_log_events(
                logGroupName=config.LOG_GROUP_NAME,
                logStreamName=log_stream_name,
                startTime=timestamp,
                limit=5
            )

            log_lines = [e["message"] for e in response["events"]]
            result = (
                f"EDN has been reported as QUIESCED in CCMS SOA.\n\n"
                f"*Log stream*: {log_stream_name}\n"
                f"*Timestamp*: {timestamp}\n"
                f"*Message*: {message}\n\n"
                "Nearby log lines:\n" + "\n".join(log_lines)
            )

            notification_service.send_notification(
                "🔥 EDN is quiesced on CCMS SOA Managed",
                result,
                is_error=True,
            )

        return {"statusCode": 200}

    except Exception as e:
        logger.error(f"Lambda execution failed: {e}", exc_info=True)
        if notification_service:
            notification_service.send_notification(
                "Lambda Error - CCMS SOA EDN Quiesced Monitor", str(e), True
            )
        return {"statusCode": 500, "error": str(e)}

    finally:
        tracemalloc.stop()
