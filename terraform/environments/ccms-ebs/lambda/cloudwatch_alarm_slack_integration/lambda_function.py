"""
AWS Lambda function to pull CloudWatch Alarms and GuardDuty findings from SNS
and publish them into Slack (separate channels via different webhooks).
"""

import json
import os
import logging
import io
import tracemalloc
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
        mandatory_fields = {
            "slack_channel_webhook": config_dict.get("slack_channel_webhook"),
            "slack_channel_webhook_guardduty": config_dict.get("slack_channel_webhook_guardduty"),
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

    slack_channel_webhook: str
    slack_channel_webhook_guardduty: str

    def __post_init__(self) -> None:
        config_dict = {
            "slack_channel_webhook": self.slack_channel_webhook,
            "slack_channel_webhook_guardduty": self.slack_channel_webhook_guardduty,
        }
        ConfigValidator.validate_mandatory_fields(config_dict, "configuration")
        logger.info("Configuration validated")


class SecretsManager:
    """Manager for retrieving configuration from AWS Secrets Manager."""

    def __init__(self) -> None:
        self.client = cast(SecretsManagerClient, boto3.client("secretsmanager"))
        logger.info("Initialized Secrets Manager client")

    def get_credentials(self, secret_name: str) -> Dict[str, Union[str, int, bool]]:
        """Retrieve and parse credentials from Secrets Manager."""
        try:
            logger.info(f"Retrieving secret: {secret_name}")
            response = self.client.get_secret_value(SecretId=secret_name)

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
    """
    config = ValidateConfig(
        slack_channel_webhook=ConfigValidator.get_mandatory_secret(
            secrets_data, "slack_channel_webhook"
        ),
        slack_channel_webhook_guardduty=ConfigValidator.get_mandatory_secret(
            secrets_data, "slack_channel_webhook_guardduty"
        ),
    )
    return config


class NotificationService:
    """Service for sending notifications to Slack."""

    def __init__(
        self,
        webhook_url: str,
        function_name: str = "CloudWatch/GuardDuty SNS to Slack",
    ) -> None:
        if not webhook_url:
            raise ValueError("Slack webhook URL is required for notifications")

        self.webhook_url = webhook_url
        self.function_name = function_name
        logger.info("Slack notifications configured")

    def send_notification(
        self,
        title: str,
        alarmdetails: Dict[str, Any],
        timestamp: str,
        message_type: str,
        is_error: bool = False,
    ) -> bool:
        """Send a notification to Slack using the webhook."""
        curl = pycurl.Curl()
        logger.info("alarmdetailsinside:\n" + json.dumps(alarmdetails, indent=2))

        payload: Dict[str, Any]

        if message_type == "GuardDuty":
            detail = alarmdetails.get("detail", {})

            # Severity (defensive parsing)
            severity_raw = detail.get("severity", 0.0)
            try:
                severity_val = float(severity_raw)
            except (TypeError, ValueError):
                severity_val = 0.0

            if severity_val < 4.0:
                emoji = ":large_blue_circle:"
                strseverity = "Low"
            elif severity_val < 7.0:
                emoji = ":large_orange_circle:"
                strseverity = "Medium"
            elif severity_val < 9.0:
                emoji = ":small_red_triangle:"
                strseverity = "High"
            else:
                emoji = ":broken_heart:"
                strseverity = "Critical"

            finding_type = detail.get("type", "Unknown Finding")
            region = detail.get("region", "Unknown Region")
            account_id = detail.get("accountId", "Unknown Account")
            header = f"{emoji} | GuardDuty Finding | {region} | Account: {account_id}"
            finding_title = detail.get("title", "No Title Provided")

            service = detail.get("service", {})
            threatcount = service.get("count", "N/A")
            firstseennofmt = service.get("eventFirstSeen", "N/A")
            lastseennofmt = service.get("eventLastSeen", "N/A")

            firstseen = "N/A"
            lastseen = "N/A"

            if firstseennofmt != "N/A":
                try:
                    try:
                        dt_first = datetime.strptime(
                            firstseennofmt, "%Y-%m-%dT%H:%M:%S.%fZ"
                        )
                    except ValueError:
                        dt_first = datetime.strptime(
                            firstseennofmt, "%Y-%m-%dT%H:%M:%SZ"
                        )
                    firstseen = dt_first.strftime("%a, %d %b %Y %H:%M:%S UTC")
                except Exception:
                    firstseen = firstseennofmt

            if lastseennofmt != "N/A":
                try:
                    try:
                        dt_last = datetime.strptime(
                            lastseennofmt, "%Y-%m-%dT%H:%M:%S.%fZ"
                        )
                    except ValueError:
                        dt_last = datetime.strptime(
                            lastseennofmt, "%Y-%m-%dT%H:%M:%SZ"
                        )
                    lastseen = dt_last.strftime("%a, %d %b %Y %H:%M:%S UTC")
                except Exception:
                    lastseen = lastseennofmt

            # 🔹 S3 bucket name (if this is an S3 finding)
            bucket_name = None
            resource = detail.get("resource", {})
            if resource.get("resourceType") == "S3Bucket":
                s3_details = resource.get("s3BucketDetails") or []
                if isinstance(s3_details, list) and s3_details:
                    bucket_name = s3_details[0].get("name")

            payload = {
                "blocks": [
                    {
                        "type": "header",
                        "text": {"type": "plain_text", "text": header},
                    },
                    {
                        "type": "section",
                        "text": {
                            "type": "plain_text",
                            "text": f"Finding type - {finding_type}",
                        },
                    },
                    {
                        "type": "section",
                        "text": {
                            "type": "mrkdwn",
                            "text": f"*{finding_title}*",
                        },
                    },
                    {"type": "divider"},
                    {
                        "type": "section",
                        "fields": [
                            {
                                "type": "mrkdwn",
                                "text": f"*FirstSeen:* {firstseen}",
                            },
                            {
                                "type": "mrkdwn",
                                "text": f"*LastSeen:* {lastseen}",
                            },
                        ],
                    },
                    {
                        "type": "section",
                        "fields": [
                            {
                                "type": "mrkdwn",
                                "text": f"*Severity:* {strseverity}",
                            },
                            {
                                "type": "mrkdwn",
                                "text": f"*Threat Count:* {threatcount}",
                            },
                        ],
                    },
                ]
            }

            # Add bucket info if present
            if bucket_name:
                payload["blocks"].append(
                    {
                        "type": "section",
                        "fields": [
                            {
                                "type": "mrkdwn",
                                "text": f"*Bucket:* `{bucket_name}`",
                            }
                        ],
                    }
                )

        elif message_type == "CloudWatch Alarm":
            alarm_name = alarmdetails.get("AlarmName", "Unknown Alarm")
            region = alarmdetails.get("Region", "")
            alarm_state = alarmdetails.get("NewStateValue", "")
            reason = alarmdetails.get("NewStateReason", "")
            namespace = alarmdetails.get("Trigger", {}).get("Namespace", "")
            metric_name = alarmdetails.get("Trigger", {}).get("MetricName", "")
            dimensions = alarmdetails.get("Trigger", {}).get("Dimensions", [])
            alarmdescription = alarmdetails.get(
                "AlarmDescription", "Alarm Description"
            )

            dim_text = "\n".join([f"{d['name']} = {d['value']}" for d in dimensions])
            emoji = ":broken_heart:" if is_error else ":white_check_mark:"
            title_text = f"{emoji} | {title} | {alarm_name} | {region}"

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
                        "text": {"type": "mrkdwn", "text": f"*{title_text}*"},
                    },
                    {"type": "divider"},
                    {
                        "type": "section",
                        "text": {"type": "mrkdwn", "text": f"*Reason:* {reason}"},
                    },
                    {
                        "type": "section",
                        "fields": [
                            {
                                "type": "mrkdwn",
                                "text": f"*Namespace:* {namespace}",
                            },
                            {
                                "type": "mrkdwn",
                                "text": f"*Metric:* {metric_name}",
                            },
                        ],
                    },
                    {
                        "type": "section",
                        "fields": [
                            {
                                "type": "mrkdwn",
                                "text": f"*Timestamp:* {timestamp}",
                            },
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
                            "text": f"*Resource Details:*\n {dim_text}",
                        },
                    },
                ]
            }

        else:
            # Fallback for unknown types / error notifications
            payload = {
                "blocks": [
                    {
                        "type": "section",
                        "text": {
                            "type": "mrkdwn",
                            "text": f"*{title}*\n```{json.dumps(alarmdetails, indent=2)}```",
                        },
                    }
                ]
            }

        try:
            json_payload = json.dumps(payload)
            logger.info(f"Prepared Slack payload: {json_payload}")

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


def lambda_handler(event, context):
    """
    Main Lambda handler function.

    Triggered by SNS Topic subscriptions to:
      - CloudWatch Alarms (cw_alerts)
      - GuardDuty findings via EventBridge -> cw_alerts
    """
    tracemalloc.start()

    notification_service: Optional[NotificationService] = None
    # Safe defaults for error paths
    formatted = datetime.utcnow().strftime("%a, %d %b %Y %H:%M:%S UTC")
    message_type = "Unknown"
    is_error = True

    sns_message = event["Records"][0]["Sns"]
    message_str = sns_message.get("Message", "{}")

    try:
        alarm_details = json.loads(message_str)
        logger.info("alarm_details:\n" + json.dumps(alarm_details, indent=2))

        source = alarm_details.get("source", "aws.cloudwatch")
        logger.info("source: %s", source)

        env_config: Dict[str, Optional[str]] = {}

        # Get secret name from environment or event
        secret_name = os.environ.get("SECRET_NAME", event.get("secret_name"))
        if not secret_name:
            raise ValueError("SECRET_NAME not found in environment or event")
        if not isinstance(secret_name, str):
            raise ValueError(
                f"SECRET_NAME must be a string, got: {type(secret_name).__name__}"
            )

        logger.info("Retrieving credentials from AWS Secrets Manager")
        secrets_manager = SecretsManager()
        secrets_data = secrets_manager.get_credentials(secret_name)

        required_secrets = ["slack_channel_webhook", "slack_channel_webhook_guardduty"]
        missing_secrets = [key for key in required_secrets if key not in secrets_data]
        if missing_secrets:
            raise ValueError(f"Missing required secrets: {', '.join(missing_secrets)}")

        logger.info("Parsing configuration from environment and secrets")
        config = parse_config_from_env_and_secrets(env_config, secrets_data)

        if source == "aws.guardduty":
            logger.info("GuardDuty finding detected in SNS message")
            logger.info(
                "Starting Notification to Slack for GuardDuty Finding via SNS Topic"
            )

            timestamp_str = alarm_details.get("time")
            if timestamp_str:
                try:
                    dt = datetime.strptime(timestamp_str, "%Y-%m-%dT%H:%M:%SZ")
                    formatted = dt.strftime("%a, %d %b %Y %H:%M:%S UTC")
                except ValueError:
                    pass

            channelconfig = config.slack_channel_webhook_guardduty
            alarmnotification = "GuardDuty Finding Notification"
            message_type = "GuardDuty"

        else:
            logger.info("CloudWatch Alarm or other SNS message detected")
            logger.info(
                "Starting Notification to Slack for CloudWatch Alarm via SNS Topic"
            )

            timestamp_str = sns_message.get("Timestamp")
            if timestamp_str:
                try:
                    dt = datetime.strptime(
                        timestamp_str, "%Y-%m-%dT%H:%M:%S.%fZ"
                    )
                    formatted = dt.strftime("%a, %d %b %Y %H:%M:%S UTC")
                except ValueError:
                    try:
                        dt = datetime.strptime(
                            timestamp_str, "%Y-%m-%dT%H:%M:%SZ"
                        )
                        formatted = dt.strftime("%a, %d %b %Y %H:%M:%S UTC")
                    except ValueError:
                        pass

            channelconfig = config.slack_channel_webhook
            alarmnotification = "CloudWatch Alarm Notification"
            message_type = "CloudWatch Alarm"

            new_state = alarm_details.get("NewStateValue", "")
            if new_state == "OK":
                is_error = False

        notification_service = NotificationService(
            channelconfig, context.function_name
        )

        notification_service.send_notification(
            alarmnotification,
            alarm_details,
            formatted,
            message_type,
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

        if notification_service is not None:
            try:
                notification_service.send_notification(
                    "Lambda Execution Failed",
                    {"error": error_msg},
                    formatted,
                    "Error",
                    is_error=True,
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
