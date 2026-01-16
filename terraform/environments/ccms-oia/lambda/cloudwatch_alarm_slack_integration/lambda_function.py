"""
AWS Lambda function to pull CloudWatch Alarm from SNS Topic and
publish into Slack. This will also publish GuardDuty findings and S3 events into Slack.
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
            "slack_channel_webhook_s3": config_dict.get("slack_channel_webhook_s3"),
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
    slack_channel_webhook_s3: str

    def __post_init__(self):
        """Validate configuration after initialization."""
        config_dict = {
            "slack_channel_webhook": self.slack_channel_webhook,
            "slack_channel_webhook_guardduty": self.slack_channel_webhook_guardduty,
            "slack_channel_webhook_s3": self.slack_channel_webhook_s3,
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
        slack_channel_webhook_guardduty=ConfigValidator.get_mandatory_secret(
            secrets_data, "slack_channel_webhook_guardduty"
        ),
        slack_channel_webhook_s3=ConfigValidator.get_mandatory_secret(
            secrets_data, "slack_channel_webhook_s3"
        ),
    )

    return config


class NotificationService:
    """Service for sending notifications to Slack."""

    def __init__(self, webhook_url: str, function_name: str = "CloudWatch SNS Alarm to Lambda"):
        if not webhook_url:
            raise ValueError("Slack webhook URL is required for notifications")

        self.webhook_url = webhook_url
        self.function_name = function_name
        logger.info("Slack notifications configured")

    def send_notification(
        self, title: str, alarmdetails: dict, timestamp: str, type: str, is_error: bool = False
    ) -> bool:
        """Send a notification to Slack using the webhook."""
        curl = pycurl.Curl()
        logger.info("alarmdetailsinside:\n" + json.dumps(alarmdetails, indent=2))

        # ---------------- GuardDuty ----------------
        if type == "GuardDuty":
            severity = alarmdetails.get('detail', {}).get('severity', 'Unknown Severity')
            if isinstance(severity, (int, float)):
                if severity < 4.0:
                    emoji = ":large_blue_circle:"
                    strseverity = "Low"
                elif severity < 7.0:
                    emoji = ":large_orange_circle:"
                    strseverity = "Medium"
                elif severity < 9.0:
                    emoji = ":small_red_triangle:"
                    strseverity = "High"
                else:
                    emoji = ":broken_heart:"
                    strseverity = "Critical"
            else:
                emoji = ":grey_question:"
                strseverity = "Unknown"

            finding_type = alarmdetails.get('detail', {}).get('type', 'Unknown Finding')
            region = alarmdetails.get('detail', {}).get('region', 'Unknown Region')
            account_id = alarmdetails.get('detail', {}).get('accountId', 'Unknown Account')
            header = f"{emoji} | GuardDuty Finding | {region} | Account: {account_id}"
            title = alarmdetails.get('detail', {}).get('description', 'No Title Provided')
            threatcount = alarmdetails.get('detail', {}).get('service', {}).get('count', 'N/A')
            firstseennofmt = alarmdetails.get('detail', {}).get('service', {}).get('eventFirstSeen', 'N/A')
            lastseennofmt = alarmdetails.get('detail', {}).get('service', {}).get('eventLastSeen', 'N/A')

            firstseen = firstseennofmt
            lastseen = lastseennofmt
            try:
                if firstseennofmt != 'N/A':
                    dt_first = datetime.strptime(firstseennofmt, "%Y-%m-%dT%H:%M:%S.%fZ")
                    firstseen = dt_first.strftime("%a, %d %b %Y %H:%M:%S UTC")
            except Exception:
                pass

            try:
                if lastseennofmt != 'N/A':
                    dt_last = datetime.strptime(lastseennofmt, "%Y-%m-%dT%H:%M:%S.%fZ")
                    lastseen = dt_last.strftime("%a, %d %b %Y %H:%M:%S UTC")
            except Exception:
                pass

            payload = {
            "blocks": [
                {
                    "type": "header",
                    "text": {
                        "type": "plain_text",
                        "text": f"{header}"
                    }
                },
                {
                    "type": "section",
                    "text": {
                        "type": "mrkdwn",
                        "text": f"*Finding Type* - {finding_type}"
                    }
                },
                {
                    "type": "section",
                    "text": {
                        "type": "mrkdwn",
                        "text": "*Details*"
                    }
                },
                {
                    "type": "rich_text",
                    "elements": [
                        {
                            "type": "rich_text_preformatted",
                            "elements": [
                                {
                                    "type": "text",
                                    "text": f"{title}"
                                }
                            ]
                        }
                    ]
                },
                {
                    "type": "divider"
                },
                {
                    "type": "section",
                    "fields": [
                        {
                            "type": "mrkdwn",
                            "text": f"*FirstSeen:* {firstseen}"
                        },
                        {
                            "type": "mrkdwn",
                            "text": f"*LastSeen:* {lastseen}"
                        }
                    ]
                },
                {
                    "type": "section",
                    "fields": [
                        {
                            "type": "mrkdwn",
                            "text": f"*Severity:* {strseverity}"
                        },
                        {
                            "type": "mrkdwn",
                            "text": f"*Threat Count:* {threatcount}"
                        }
                    ]
                }
            ]
        }

        # ---------------- CloudWatch Alarm ----------------
        elif type == "CloudWatch Alarm":
            alarm_name = alarmdetails.get('AlarmName', 'Unknown Alarm')
            region = alarmdetails.get('Region', '')
            alarm_state = alarmdetails.get('NewStateValue', '')
            reason = alarmdetails.get('NewStateReason', '')
            namespace = alarmdetails.get('Trigger', {}).get('Namespace', '')
            metric_name = alarmdetails.get('Trigger', {}).get('MetricName', '')
            dimensions = alarmdetails.get('Trigger', {}).get('Dimensions', [])
            alarmdescription = alarmdetails.get('AlarmDescription', 'Alarm Description')

            dim_text = '\n'.join([f"{d['name']} = {d['value']}" for d in dimensions])
            emoji = ":broken_heart:" if is_error else ":white_check_mark:"
            color = "danger" if is_error else "good"
            title = f"{emoji} | {title} | {alarm_name} | {region}"

            payload = {
                "blocks": [
                    {
                        "type": "header",
                        "text": {"type": "plain_text", "text": f"{alarm_state} - {alarm_name}"}
                    },
                    {
                        "type": "section",
                        "text": {"type": "mrkdwn", "text": f"*{title}*"}
                    },
                    {
                        "type": "divider"
                    },
                    {
                        "type": "section",
                        "text": {"type": "mrkdwn", "text": f"*Reason:* {reason}"}
                    },
                    {
                        "type": "section",
                        "fields": [
                            {
                                "type": "mrkdwn",
                                "text": f"*Namespace:* {namespace}"
                            },
                            {
                                "type": "mrkdwn",
                                "text": f"*Metric:* {metric_name}"
                            }
                        ]
                    },
                    {
                        "type": "section",
                        "fields": [
                            {
                                "type": "mrkdwn",
                                "text": f"*Timestamp:* {timestamp}"
                            },
                            {
                                "type": "mrkdwn",
                                "text": f"*Alarm Description:* {alarmdescription}"
                            }
                        ]
                    },
                    {
                        "type": "section",
                        "text": {"type": "mrkdwn", "text": f"*Resource Details:*\n {dim_text}"}
                    }
                ]
            }

        elif type == "S3 Event":
            records = alarmdetails.get("Records", [])
            record = records[0] if records else {}

            s3_info = record.get("s3", {})
            bucket = s3_info.get("bucket", {})
            obj = s3_info.get("object", {})

            bucket_name = bucket.get("name", "Unknown Bucket")
            object_key = obj.get("key", "Unknown Key")
            object_size = obj.get("size", "Unknown Size")

            user_identity = record.get("userIdentity", {})
            principal_id = user_identity.get("principalId", "Unknown Principal")

            header = f":white_check_mark: S3 Object Uploaded on bucket {bucket_name}."

            payload = {
                "blocks": [
                    {
                        "type": "section",
                        "text": {"type": "mrkdwn", "text": header}
                    },
                    {
                        "type": "section",
                        "text": {
                            "type": "mrkdwn",
                            "text": (
                                "*Details*\n"
                                f" • *Object:* `s3://{bucket_name}/{object_key}`\n"
                                f" • *Size (bytes):* {object_size} bytes\n"
                                f" • *Principal:* {principal_id}\n"
                                f" • *Timestamp:* {timestamp}"
                            )
                        }
                    }
                ]
            }

        # ---------------- Fallback ----------------
        else:
            payload = {
                "blocks": [
                    {
                        "type": "section",
                        "text": {"type": "mrkdwn", "text": f"*{title}*"}
                    },
                    {
                        "type": "section",
                        "text": {"type": "mrkdwn", "text": f"```{json.dumps(alarmdetails, indent=2)}```"}
                    }
                ]
            }

        try:
            # Convert payload to JSON
            json_payload = json.dumps(payload)
            logger.info(f"Prepared Slack payload: {json_payload}")
            # Configure curl for HTTP POST with JSON
            curl.setopt(pycurl.URL, self.webhook_url)
            curl.setopt(pycurl.POST, 1)
            curl.setopt(pycurl.POSTFIELDS, json_payload)
            curl.setopt(pycurl.HTTPHEADER, ["Content-Type: application/json"])
            curl.setopt(pycurl.TIMEOUT, 10)

            # Buffer for response (though Slack webhook responses are minimal)
            response_buffer = io.BytesIO()
            curl.setopt(pycurl.WRITEDATA, response_buffer)

            # Send the notification
            curl.perform()

            # Check HTTP status code
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
    
    This function gets triggered by SNS Topic subscriptions to CloudWatch Alarms,
    GuardDuty findings and S3 events.
    """

    tracemalloc.start()

    notification_service = None
    formatted = datetime.utcnow().strftime("%a, %d %b %Y %H:%M:%S UTC")
    type = "Unknown"
    is_error = True

    # SNS message comes in event['Records'][0]['Sns']
    sns_message = event['Records'][0]['Sns']
    message_str = sns_message.get('Message', '{}')

    try:
        alarm_details = json.loads(message_str)
        logger.info("alarm_details:" + json.dumps(alarm_details, indent=2))

        # Detect source:
        # - GuardDuty / CloudWatch / EventBridge-style -> 'source'
        # - S3 via SNS -> Records[0].eventSource == 'aws:s3'
        source = alarm_details.get('source')
        if not source and "Records" in alarm_details:
            first_record = alarm_details["Records"][0]
            event_source = first_record.get("eventSource")
            if event_source == "aws:s3":
                source = "aws.s3"

        if not source:
            # Default to CloudWatch if nothing else matches
            source = "aws.cloudwatch"

        logger.info("source:" + str(source))

        env_config = {
            # Mandatory environment variables (currently none)
        }

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

        # Validate that required credentials are present
        required_secrets = [
            "slack_channel_webhook",
            "slack_channel_webhook_guardduty",
            "slack_channel_webhook_s3",
        ]
        missing_secrets = [key for key in required_secrets if key not in secrets_data]
        if missing_secrets:
            raise ValueError(f"Missing required secrets: {', '.join(missing_secrets)}")

        # Parse combined configuration
        logger.info("Parsing configuration from environment and secrets")
        config = parse_config_from_env_and_secrets(env_config, secrets_data)

        # ---------------- GuardDuty ----------------
        if source == "aws.guardduty":
            logger.info("GuardDuty finding detected in SNS message")
            logger.info("Starting Notification to Slack for GuardDuty Alarm via SNS Topic")

            timestamp_str = alarm_details.get('time')
            if timestamp_str:
                dt = datetime.strptime(timestamp_str, "%Y-%m-%dT%H:%M:%SZ")
                formatted = dt.strftime("%a, %d %b %Y %H:%M:%S UTC")

            channelconfig = config.slack_channel_webhook_guardduty
            alarmnotifiction = "GuardDuty Finding Notification"
            type = "GuardDuty"
            is_error = True  # usually "bad" findings

        # ---------------- S3 Event ----------------
        elif source == "aws.s3":
            logger.info("S3 event detected in SNS message")
            logger.info("Starting Notification to Slack for S3 Event via SNS Topic")

            # S3 time is in the record
            first_record = alarm_details["Records"][0]
            timestamp_str = first_record.get("eventTime")
            if timestamp_str:
                # Example: 2026-01-12T16:10:07.364Z
                try:
                    dt = datetime.strptime(timestamp_str, "%Y-%m-%dT%H:%M:%S.%fZ")
                except ValueError:
                    dt = datetime.strptime(timestamp_str, "%Y-%m-%dT%H:%M:%SZ")
                formatted = dt.strftime("%d %b %Y %H:%M:%S UTC")

            channelconfig = config.slack_channel_webhook_s3
            alarmnotifiction = "S3 Object Event Notification"
            type = "S3 Event"
            is_error = False   # S3 put is informational

        # ---------------- CloudWatch Alarm (default) ----------------
        else:
            logger.info("CloudWatch Alarm detected in SNS message")
            logger.info("Starting Notification to Slack for CloudWatch Alarm via SNS Topic")

            timestamp_str = sns_message.get('Timestamp')
            if timestamp_str:
                dt = datetime.strptime(timestamp_str, "%Y-%m-%dT%H:%M:%S.%fZ")
                formatted = dt.strftime("%a, %d %b %Y %H:%M:%S UTC")

            channelconfig = config.slack_channel_webhook
            alarmnotifiction = "CloudWatch Alarm Notification"
            type = "CloudWatch Alarm"

            new_state = alarm_details.get('NewStateValue', '')
            if new_state == "OK":
                is_error = False

        # Initialize services
        notification_service = NotificationService(
            channelconfig, context.function_name
        )

        notification_service.send_notification(
            alarmnotifiction,
            alarm_details,
            formatted,
            type,
            is_error
        )

        # Prepare response
        response = {
            "statusCode": 200,
            "body": {
                "message": "Successfully completed publishing notifications"
            },
        }

        logger.info(f"Lambda execution completed successfully: {response}")
        return response

    except Exception as e:
        error_msg = f"Lambda execution failed:\n{str(e)}"
        logger.error(error_msg, exc_info=True)

        # Send error notification if notification service is available
        if notification_service is not None:
            try:
                notification_service.send_notification(
                    "Lambda Execution Failed", {"error": error_msg}, formatted, type, is_error=True
                )
            except Exception as notification_error:
                logger.error(f"Failed to send error notification: {notification_error}")

        # Return error response
        return {"statusCode": 500, "body": {"error": error_msg}}
    finally:
        current, peak = tracemalloc.get_traced_memory()
        logger.info(
            f"Current memory usage: {current / 1024 / 1024:.2f} MB; Peak: {peak / 1024 / 1024:.2f} MB"
        )
        tracemalloc.stop()
