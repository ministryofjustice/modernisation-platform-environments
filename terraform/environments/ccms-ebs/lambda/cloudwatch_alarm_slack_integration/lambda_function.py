"""
AWS Lambda function to pull CloudWatch Alarm or GuardDuty finding from SNS Topic and
publish into Slack.
"""

import json
import os
import logging
import io
import time
import tracemalloc
import urllib.request
from dataclasses import dataclass
from typing import Any, Dict, Optional, Union, cast
from datetime import datetime
import boto3
import pycurl
from botocore.exceptions import ClientError
from mypy_boto3_secretsmanager import SecretsManagerClient

logger = logging.getLogger()
logger.setLevel(logging.INFO)


@dataclass
class Config:
    """Configuration settings for the Lambda function."""

    @classmethod
    def from_env(cls) -> "Config":
        """Create configuration from environment variables."""
        return cls()


class ConfigValidator:
    """Validator class for configuration validation."""

    @staticmethod
    def validate_mandatory_fields(config_dict: Dict[str, Any], field_name: str) -> None:
        """Validate that all mandatory fields are present and non-empty."""
        # Always mandatory fields
        mandatory_fields = {
            "slack_channel_webhook": config_dict.get("slack_channel_webhook")
        }
        missing_fields = [name for name, value in mandatory_fields.items() if not value]
        if missing_fields:
            raise ValueError(
                f"Missing required {field_name} fields: {', '.join(missing_fields)}"
            )

    @staticmethod
    def get_mandatory_secret(secrets_data: Dict, key: str) -> str:
        """Extract and validate a mandatory field from secrets."""
        value = secrets_data.get(key)
        if not value or not isinstance(value, str):
            raise ValueError(
                f"{key} must be a non-empty string in secrets, got: {value}"
            )
        return value

    @staticmethod
    def get_optional_secret(secrets_data: Dict, key: str) -> Optional[str]:
        """Extract and validate an optional field from secrets."""
        value = secrets_data.get(key)
        if value is not None and not isinstance(value, str):
            raise ValueError(
                f"{key} must be a string in secrets, got: {type(value).__name__}"
            )
        return value if value else None

    @staticmethod
    def get_mandatory_env(env_data: Dict, key: str) -> str:
        """Extract and validate a mandatory field from environment."""
        value = env_data.get(key)
        if not value:
            raise ValueError(f"{key} environment variable is required")
        return value


@dataclass
class ValidateConfig:
    """Configuration with validation."""

    # Mandatory fields (no default values)
    slack_channel_webhook: str

    def __post_init__(self):
        """Validate configuration after initialization."""
        config_dict = {
            "slack_channel_webhook": self.slack_channel_webhook,
        }

        ConfigValidator.validate_mandatory_fields(config_dict, "configuration")

        logger.info("Configuration validated")


class SecretsManager:
    """Manager for retrieving configuration from AWS Secrets Manager."""

    def __init__(self):
        self.client = cast(SecretsManagerClient, boto3.client("secretsmanager"))
        logger.info("Initialized Secrets Manager client")

    def get_credentials(self, secret_name: str) -> Dict[str, Union[str, int, bool]]:
        """Retrieve and parse credentials from Secrets Manager."""
        try:
            logger.info(f"Retrieving secret: {secret_name}")
            response = self.client.get_secret_value(SecretId=secret_name)

            # Parse the secret string
            secret_data = json.loads(response["SecretString"])
            logger.info(
                f"Successfully retrieved credentials with {len(secret_data)} keys"
            )

            return secret_data

        except ClientError as e:
            error_code = e.response["Error"]["Code"]
            error_msg = f"Failed to retrieve secret {secret_name}: {error_code}"
            logger.error(error_msg)
            raise Exception(error_msg)
        except json.JSONDecodeError as e:
            error_msg = f"Failed to parse secret JSON: {e}"
            logger.error(error_msg)
            raise Exception(error_msg)


def parse_config_from_env_and_secrets(
    env_data: Dict[str, Optional[str]], secrets_data: Dict[str, Union[str, int, bool]]
) -> ValidateConfig:
    """
    Parse configuration from both environment variables and secrets data.

    This function combines non-sensitive configuration from environment variables
    with sensitive credentials from AWS Secrets Manager.
    """

    config = ValidateConfig(
        slack_channel_webhook=ConfigValidator.get_mandatory_secret(
            secrets_data, "slack_channel_webhook"
        ),
    )

    return config


class NotificationService:
    """Service for sending notifications to Slack."""

    def __init__(
        self,
        webhook_url: str,
        function_name: str = "CloudWatch/GuardDuty SNS Alarm to Lambda",
    ):
        if not webhook_url:
            raise ValueError("Slack webhook URL is required for notifications")

        self.webhook_url = webhook_url
        self.function_name = function_name
        logger.info("Slack notifications configured")

    def _post_to_slack(self, payload: Dict[str, Any]) -> bool:
        """Low-level method to POST a payload to Slack."""
        curl = pycurl.Curl()
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
                raise Exception(f"HTTP error {http_code}")

            logger.info("Slack notification sent successfully")
            return True
        except Exception as e:
            logger.error(f"Failed to send Slack notification: {e}")
            return False
        finally:
            curl.close()

    def send_notification(
        self,
        title: str,
        alarmdetails: Dict[str, Any],
        timestamp: str,
        is_error: bool = False,
    ) -> bool:
        """Send a notification to Slack for CloudWatch alarms."""
        logger.info("alarmdetailsinside:\n" + json.dumps(alarmdetails, indent=2))

        alarm_name = alarmdetails.get("AlarmName", "Unknown Alarm")
        region = alarmdetails.get("Region", "")
        alarm_state = alarmdetails.get("NewStateValue", "")
        reason = alarmdetails.get("NewStateReason", "")
        namespace = alarmdetails.get("Trigger", {}).get("Namespace", "")
        metric_name = alarmdetails.get("Trigger", {}).get("MetricName", "")
        dimensions = alarmdetails.get("Trigger", {}).get("Dimensions", [])
        alarmdescription = alarmdetails.get("AlarmDescription", "Alarm Description")

        dim_text = "\n".join([f"{d['name']} = {d['value']}" for d in dimensions])

        emoji = ":broken_heart:" if is_error else ":white_check_mark:"
        final_title = f"{emoji} | {title} | {alarm_name} | {region}"

        payload = {
            "blocks": [
                {
                    "type": "header",
                    "text": {
                        "type": "plain_text",
                        "text": f"{alarm_state} - {alarm_name}",
                    },
                },
                {
                    "type": "section",
                    "text": {"type": "mrkdwn", "text": f"*{final_title}*"},
                },
                {"type": "divider"},
                {
                    "type": "section",
                    "text": {"type": "mrkdwn", "text": f"*Reason:* {reason}"},
                },
                {
                    "type": "section",
                    "fields": [
                        {"type": "mrkdwn", "text": f"*Namespace:* {namespace}"},
                        {"type": "mrkdwn", "text": f"*Metric:* {metric_name}"},
                    ],
                },
                {
                    "type": "section",
                    "fields": [
                        {"type": "mrkdwn", "text": f"*Timestamp:* {timestamp}"},
                        {
                            "type": "mrkdwn",
                            "text": f"*Alarm Description:* {alarmdescription}",
                        },
                    ],
                },
                {
                    "type": "section",
                    "text": {
                        "type": "mrkdwn",
                        "text": f"*Resource Details:*\n{dim_text}",
                    },
                },
            ]
        }

        return self._post_to_slack(payload)

    def send_guardduty_notification(
        self, finding_event: Dict[str, Any], timestamp: str
    ) -> bool:
        """Send a notification to Slack for GuardDuty findings."""
        logger.info("guardduty_event:\n" + json.dumps(finding_event, indent=2))

        detail = finding_event.get("detail", {})
        title = detail.get("title", "GuardDuty Finding")
        finding_type = detail.get("type", "Unknown type")
        severity = detail.get("severity", "N/A")
        region = detail.get("region", finding_event.get("region", ""))
        account_id = detail.get("accountId", finding_event.get("account", ""))
        resource = detail.get("resource", {})
        detector_id = detail.get("detectorId", "")
        finding_id = detail.get("id", "")

        emoji = ":rotating_light:"
        header_text = f"{emoji} GuardDuty Finding - {title}"

        payload = {
            "blocks": [
                {
                    "type": "header",
                    "text": {"type": "plain_text", "text": header_text},
                },
                {
                    "type": "section",
                    "fields": [
                        {"type": "mrkdwn", "text": f"*Type:* {finding_type}"},
                        {"type": "mrkdwn", "text": f"*Severity:* {severity}"},
                        {"type": "mrkdwn", "text": f"*Region:* {region}"},
                        {"type": "mrkdwn", "text": f"*Account:* {account_id}"},
                    ],
                },
                {
                    "type": "section",
                    "fields": [
                        {"type": "mrkdwn", "text": f"*Detector ID:* {detector_id}"},
                        {"type": "mrkdwn", "text": f"*Finding ID:* {finding_id}"},
                    ],
                },
                {
                    "type": "section",
                    "text": {
                        "type": "mrkdwn",
                        "text": f"*Resource:* ```{json.dumps(resource, indent=2)}```",
                    },
                },
                {
                    "type": "context",
                    "elements": [
                        {"type": "mrkdwn", "text": f"*Timestamp:* {timestamp}"}
                    ],
                },
            ]
        }

        return self._post_to_slack(payload)


def lambda_handler(event, context):
    """
    Main Lambda handler function.

    This function gets triggered by SNS Topic subscriptions to CloudWatch Alarms
    and GuardDuty findings (via EventBridge -> SNS).
    It performs the following steps:
    1. Load slack webhook from AWS Secrets Manager
    2. Pull the message from the SNS event
    3. Detect message type (CloudWatch vs GuardDuty)
    4. Format the details
    5. Send notifications to Slack
    """
    tracemalloc.start()
    logger.info(
        "Starting Notification to Slack for CloudWatch Alarm / GuardDuty via SNS Topic"
    )

    notification_service: Optional[NotificationService] = None

    # SNS message comes in event['Records'][0]['Sns']
    sns_message = event["Records"][0]["Sns"]
    message_str = sns_message.get("Message", "{}")
    timestamp_str = sns_message.get("Timestamp")

    if timestamp_str:
        try:
            dt = datetime.strptime(timestamp_str, "%Y-%m-%dT%H:%M:%S.%fZ")
        except ValueError:
            # Fallback if format differs slightly
            dt = datetime.utcnow()
        formatted_timestamp = dt.strftime("%a, %d %b %Y %H:%M:%S UTC")
    else:
        formatted_timestamp = datetime.utcnow().strftime(
            "%a, %d %b %Y %H:%M:%S UTC"
        )

    try:
        alarm_details = json.loads(message_str)

        # Detect message type (CloudWatch alarm vs GuardDuty finding)
        message_type = "cloudwatch_alarm"
        if alarm_details.get("source") == "aws.guardduty" or alarm_details.get(
            "detail-type"
        ) == "GuardDuty Finding":
            message_type = "guardduty_finding"

        env_config: Dict[str, Optional[str]] = {
            # add non-secret env vars here if needed
        }

        # Get secret name from environment or event
        secret_name = os.environ.get("SECRET_NAME", event.get("secret_name"))
        if not secret_name:
            raise ValueError("SECRET_NAME not found in environment or event")
        if not isinstance(secret_name, str):
            raise ValueError(
                f"SECRET_NAME must be a string, got: {type(secret_name).__name__}"
            )

        # Retrieve sensitive credentials from Secrets Manager
        logger.info("Retrieving credentials from AWS Secrets Manager")
        secrets_manager = SecretsManager()
        secrets_data = secrets_manager.get_credentials(secret_name)

        # Validate that required credentials are present
        required_secrets = ["slack_channel_webhook"]
        missing_secrets = [key for key in required_secrets if key not in secrets_data]
        if missing_secrets:
            raise ValueError(f"Missing required secrets: {', '.join(missing_secrets)}")

        # Parse combined configuration
        logger.info("Parsing configuration from environment and secrets")
        config = parse_config_from_env_and_secrets(env_config, secrets_data)

        # Initialize services
        notification_service = NotificationService(
            config.slack_channel_webhook, context.function_name
        )

        # Default behaviour assumes error if not explicit OK (CloudWatch case)
        new_state = alarm_details.get("NewStateValue", "")
        is_error = True
        if new_state == "OK":
            is_error = False

        # Route based on message type
        if message_type == "guardduty_finding":
            logger.info("Processing GuardDuty finding notification")
            notification_service.send_guardduty_notification(
                alarm_details,
                formatted_timestamp,
            )
        else:
            logger.info("Processing CloudWatch alarm notification")
            notification_service.send_notification(
                "CloudWatch Alarm Notification",
                alarm_details,
                formatted_timestamp,
                is_error,
            )

        response = {
            "statusCode": 200,
            "body": {
                "message": "Successfully completed publishing notifications for CloudWatch Alarm / GuardDuty"
            },
        }

        logger.info(f"Lambda execution completed successfully: {response}")
        return response

    except Exception as e:
        error_msg = f"Lambda execution failed:\n{str(e)}"
        logger.error(error_msg, exc_info=True)

        error_timestamp = datetime.utcnow().strftime("%a, %d %b %Y %H:%M:%S UTC")

        # Send error notification if notification service is available
        if notification_service is not None:
            try:
                notification_service.send_notification(
                    "Lambda Execution Failed",
                    {"error": error_msg},
                    error_timestamp,
                    is_error=True,
                )
            except Exception as notification_error:
                logger.error(
                    f"Failed to send error notification: {notification_error}"
                )

        return {"statusCode": 500, "body": {"error": error_msg}}
    finally:
        current, peak = tracemalloc.get_traced_memory()
        logger.info(
            f"Current memory usage: {current / 1024 / 1024:.2f} MB; "
            f"Peak: {peak / 1024 / 1024:.2f} MB"
        )
        tracemalloc.stop()
