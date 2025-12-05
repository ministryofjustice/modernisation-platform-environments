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
sns_client = boto3.client("sns")

logger = logging.getLogger()
logger.setLevel(logging.INFO)


@dataclass
class Config:
    SNS_TOPIC_ARN: Optional[str] = None
    LOG_GROUP_NAME: Optional[str] = None

    @classmethod
    def from_env(cls) -> "Config":
        return cls(
            SNS_TOPIC_ARN=os.getenv("SNS_TOPIC_ARN"),
            LOG_GROUP_NAME=os.getenv("LOG_GROUP_NAME"),
        )


class ConfigValidator:
    @staticmethod
    def validate_mandatory_fields(config_dict: Dict[str, Any], field_name: str) -> None:
        mandatory_fields = {
            "slack_channel_webhook": config_dict.get("slack_channel_webhook")
        }
        missing_fields = [k for k, v in mandatory_fields.items() if not v]
        if missing_fields:
            raise ValueError(
                f"Missing required {field_name} fields: {', '.join(missing_fields)}"
            )

    @staticmethod
    def get_mandatory_secret(secrets_data: Dict, key: str) -> str:
        value = secrets_data.get(key)
        if not value or not isinstance(value, str):
            raise ValueError(f"{key} must be a non-empty string in secrets, got: {value}")
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
    SNS_TOPIC_ARN: str
    LOG_GROUP_NAME: str

    def __post_init__(self):
        ConfigValidator.validate_mandatory_fields(
            {"slack_channel_webhook": self.slack_channel_webhook},
            "configuration",
        )
        logger.info("Configuration validated")


class NotificationService:
    """Send notifications to Slack (critical outage style)."""

    def __init__(self, webhook_url: str, function_name: str = "CCMS SOA Quiesced Lambda"):
        if not webhook_url:
            raise ValueError("Slack webhook URL is required for notifications")

        self.webhook_url = webhook_url
        self.function_name = function_name
        logger.info("Slack notifications configured")

    def send_notification(self, title: str, message: str, is_error: bool = False) -> bool:
        curl = pycurl.Curl()

        try:
            # Always critical style (option B)
            emoji = ":rotating_light:"
            color = "danger"

            payload = {
                "attachments": [
                    {
                        "color": color,
                        "title": f"{emoji} [{self.function_name}] {title}",
                        "text": message,
                        "footer": "CCMS SOA EDN Quiesced Lambda",
                        "ts": int(time.time()),
                    }
                ]
            }

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
                raise Exception(f"HTTP error {http_code}")

            logger.info(f"Slack notification sent successfully: {title}")
            return True

        except Exception as e:
            logger.error(f"Failed to send Slack notification: {e}")
            return False
        finally:
            curl.close()


class SecretsManager:
    def __init__(self):
        self.client = cast(SecretsManagerClient, boto3.client("secretsmanager"))
        logger.info("Initialized Secrets Manager client")

    def get_credentials(self, secret_name: str) -> Dict[str, Union[str, int, bool]]:
        try:
            logger.info(f"Retrieving secret: {secret_name}")
            response = self.client.get_secret_value(SecretId=secret_name)
            secret_data = json.loads(response["SecretString"])
            logger.info(f"Successfully retrieved credentials with {len(secret_data)} keys")
            return secret_data
        except ClientError as e:
            error_code = e.response["Error"]["Code"]
            error_msg = f"Failed to retrieve secret {secret_name}: {error_code}"
            logger.error(error_msg)
            raise
        except json.JSONDecodeError as e:
            error_msg = f"Failed to parse secret JSON: {e}"
            logger.error(error_msg)
            raise


def get_env_variable(key: str, required: bool = True) -> Optional[str]:
    value = os.environ.get(key)

    if required and not value:
        raise ValueError(f"Required environment variable {key} is not set")

    if value:
        logger.info(f"Environment variable {key} is configured")
    else:
        logger.info(f"Environment variable {key} is not set")

    return value


def parse_config_from_env_and_secrets(
    env_data: Dict[str, Optional[str]], secrets_data: Dict[str, Union[str, int, bool]]
) -> ValidateConfig:
    config = ValidateConfig(
        slack_channel_webhook=ConfigValidator.get_mandatory_secret(
            secrets_data, "slack_channel_webhook"
        ),
        SNS_TOPIC_ARN=ConfigValidator.get_mandatory_env(env_data, "SNS_TOPIC_ARN"),
        LOG_GROUP_NAME=ConfigValidator.get_mandatory_env(env_data, "LOG_GROUP_NAME"),
    )
    return config


def lambda_handler(event, context):
    """
    Triggered by CW Logs subscription filter on 'EDN is quiesced' log events.
    Sends a critical Slack alert with some surrounding context.
    """
    tracemalloc.start()
    logger.info("Starting Notification to Slack for CCMS SOA EDN quiesced")
    notification_service: Optional[NotificationService] = None

    try:
        # Env
        env_config = {
            "SNS_TOPIC_ARN": get_env_variable("SNS_TOPIC_ARN", required=True),
            "LOG_GROUP_NAME": get_env_variable("LOG_GROUP_NAME", required=True),
        }

        # Secret
        secret_name = os.environ.get("SECRET_NAME", event.get("secret_name"))
        if not secret_name or not isinstance(secret_name, str):
            raise ValueError("SECRET_NAME must be provided (env or event)")

        secrets_manager = SecretsManager()
        secrets_data = secrets_manager.get_credentials(secret_name)

        # Validate required secrets
        if "slack_channel_webhook" not in secrets_data:
            raise ValueError("Missing required secret: slack_channel_webhook")

        config = parse_config_from_env_and_secrets(env_config, secrets_data)

        # Slack
        notification_service = NotificationService(
            config.slack_channel_webhook, context.function_name
        )

        # Decode CW Logs payload
        compressed_payload = base64.b64decode(event["awslogs"]["data"])
        payload = gzip.decompress(compressed_payload)
        log_data = json.loads(payload)

        log_stream_name = log_data["logStream"]
        for log_event in log_data["logEvents"]:
            message = log_event["message"]
            timestamp = log_event["timestamp"]

            logger.info(
                f"Log Stream: {log_stream_name}, Timestamp: {timestamp}, Message: {message}"
            )

            # Optionally pull some neighbouring log lines
            try:
                response = logs_client.get_log_events(
                    logGroupName=config.LOG_GROUP_NAME,
                    logStreamName=log_stream_name,
                    startTime=timestamp,
                    limit=5,
                )
                log_lines = [e["message"] for e in response["events"]]
            except Exception as e:
                logger.error(f"Failed to fetch surrounding log events: {e}")
                log_lines = []

            result = (
                f"EDN has been reported as QUIESCED in CCMS SOA.\n\n"
                f"*Log stream*: {log_stream_name}\n"
                f"*Timestamp*: {timestamp}\n"
                f"*Message*: {message}\n\n"
                "Nearby log lines:\n" + "\n".join(log_lines)
            )

            notification_service.send_notification(
                "EDN is quiesced on CCMS SOA Managed",
                result,
                is_error=True,
            )

        response = {
            "statusCode": 200,
            "body": {"message": "Successfully published EDN quiesced notifications"},
        }
        logger.info(f"Lambda execution completed successfully: {response}")
        return response

    except Exception as e:
        error_msg = f"Lambda execution failed:\n{str(e)}"
        logger.error(error_msg, exc_info=True)

        if notification_service is not None:
            try:
                notification_service.send_notification(
                    "CCMS SOA EDN Quiesced Lambda Failed", error_msg, is_error=True
                )
            except Exception as notification_error:
                logger.error(f"Failed to send error notification: {notification_error}")

        return {"statusCode": 500, "body": {"error": error_msg}}

    finally:
        current, peak = tracemalloc.get_traced_memory()
        logger.info(
            f"Current memory usage: {current / 1024 / 1024:.2f} MB; "
            f"Peak: {peak / 1024 / 1024:.2f} MB"
        )
        tracemalloc.stop()
