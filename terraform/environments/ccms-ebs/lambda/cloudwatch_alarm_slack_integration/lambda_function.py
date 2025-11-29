
import json
import os
import logging
import io
import time
import tracemalloc
import urllib.request
from dataclasses import dataclass
from typing import Any, Dict, Optional, Union, cast

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
        # Validate using the ConfigValidator
        config_dict = {
            "slack_channel_webhook": self.slack_channel_webhook,
        }

        ConfigValidator.validate_mandatory_fields(config_dict, "configuration")

        logger.info(f"Configuration validated")

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


    # Create config object with properly separated concerns
    config = ValidateConfig(
        # Connection settings from mixed sources
        slack_channel_webhook=ConfigValidator.get_mandatory_secret(secrets_data, "slack_channel_webhook"),

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
        self, title: str, message: str, is_error: bool = False
    ) -> bool:
        """Send a notification to Slack using the webhook."""
        curl = pycurl.Curl()

        try:
            # Prepare the Slack message with formatting
            emoji = ":broken_heart:" if is_error else ":white_check_mark:"
            color = "danger" if is_error else "good"

            payload = {
                "attachments": [
                    {
                        "color": color,
                        "title": f"{emoji} [{self.function_name}] {title}",
                        "text": message,
                        "footer": "CloudWatch Alarm via SNS/Lambda",
                        "ts": int(time.time()),
                    }
                ]
            }

            # Convert payload to JSON
            json_payload = json.dumps(payload)

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
    
    This function gets triggered by SNS Topic subscriptions to CloudWatch Alarms.
    It performs the following steps:
    1. Loading slack webhook from AWS Secrets Manager
    2. Pull the message from the SNS event
    3. Format the CloudWatch Alarm details
    4. Sending notifications about the results
    Args:
        event: Lambda event data (can override SECRET_NAME via 'secret_name' key)
        context: Lambda context object

    Returns:
        Response dictionary with status and results
    """
    tracemalloc.start()
    logger.info("Starting Notification to Slack for edrms document exceptions")
    slack_channel_webhook: str

    notification_service: Optional[NotificationService] = None

    # SNS message comes in event['Records'][0]['Sns']
    sns_message = event['Records'][0]['Sns']
    subject = sns_message.get('Subject', 'CloudWatch Alarm')
    message_str = sns_message.get('Message', '{}')

    # Parse the inner JSON message
    try:
        alarm_details = json.loads(message_str)
        env_config = {
            # Mandatory environment variables
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
        # Always require USER, HOST, and SLACK_WEBHOOK
        required_secrets = ["slack_channel_webhook"]
        missing_secrets = [key for key in required_secrets if key not in secrets_data]
        if missing_secrets:
            raise ValueError(f"Missing required secrets: {', '.join(missing_secrets)}")

        # Parse combined configuration
        logger.info("Parsing configuration from environment and secrets")
        config = parse_config_from_env_and_secrets(env_config, secrets_data)

         # Extract useful fields
        alarm_name = alarm_details.get('AlarmName', 'Unknown Alarm')
        new_state = alarm_details.get('NewStateValue', 'Unknown')
        reason = alarm_details.get('NewStateReason', '')
        region = alarm_details.get('Region', '')
        metric_name = alarm_details.get('Trigger', {}).get('MetricName', '')
        dimensions = alarm_details.get('Trigger', {}).get('Dimensions', [])

        # Format dimensions nicely
        dim_text = ', '.join([f"{d['name']}={d['value']}" for d in dimensions])

        # Build Slack message
        slack_message = {
            "text": f"*{subject}*\n"
                    f"Alarm: `{alarm_name}`\n"
                    f"State: `{new_state}`\n"
                    f"Region: `{region}`\n"
                    f"Metric: `{metric_name}`\n"
                    f"Dimensions: `{dim_text}`\n"
                    f"Reason: {reason}"
        }

        # Initialize services
        notification_service = NotificationService(
            config.slack_channel_webhook, context.function_name
        )
        result = f"CloudWatchAlarm:\n{slack_message}\n"
        notification_service.send_notification(
                    "CloudWatch Alarm Notification",
                    result, is_error=True
                )
        # Prepare response
        response = {
            "statusCode": 200,
            "body": {
                "message": f"Successfully completed publishing notifications for EdrmsDocumentException logs"
            },
        }

        logger.info(f"Lambda execution completed successfully: {response}")
        return response
    # except json.JSONDecodeError:
    #     alarm_details = {}
    except Exception as e:
        error_msg = f"Lambda execution failed:\n{str(e)}"
        logger.error(error_msg, exc_info=True)

        # Send error notification if notification service is available
        if notification_service is not None:
            try:
                notification_service.send_notification(
                    "Lambda Execution Failed", error_msg, is_error=True
                )
            except Exception as notification_error:
                logger.error(f"Failed to send error notification: {notification_error}")

        # Return error response
        return {"statusCode": 500, "body": {"error": error_msg}}
    finally:
        current, peak = tracemalloc.get_traced_memory()
        logger.info(f"Current memory usage: {current / 1024 / 1024:.2f} MB; Peak: {peak / 1024 / 1024:.2f} MB")
        tracemalloc.stop()
        


    # Send to Slack
    # req = urllib.request.Request(
    #     slack_webhook_url,
    #     data=json.dumps(slack_message).encode('utf-8'),
    #     headers={'Content-Type': 'application/json'}
    # )

    # try:
    #     with urllib.request.urlopen(req) as response:
    #         print(f"Slack response: {response.read().decode('utf-8')}")
    # except Exception as e:
    #     print(f"Error sending to Slack: {e}")

    # return {"status": "done"}
