#This lambda has been created to handle notification to slack channel on EdrmsDocumentException
# import sys
# import os
# sys.path.append(os.path.join(os.path.dirname(__file__), "python"))

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

logs_client = boto3.client('logs')
sns_client = boto3.client('sns')    

logger = logging.getLogger()
logger.setLevel(logging.INFO)

@dataclass
class Config:
    """Configuration settings for the Lambda function."""    
    SNS_TOPIC_ARN: Optional[str] = None
    LOG_GROUP_NAME: Optional[str] = None

    @classmethod
    def from_env(cls) -> "Config":
        """Create configuration from environment variables."""
        return cls(
            SNS_TOPIC_ARN=os.getenv("SNS_TOPIC_ARN"),
            LOG_GROUP_NAME=os.getenv("LOG_GROUP_NAME")
        )

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
    SNS_TOPIC_ARN: str
    LOG_GROUP_NAME: str

    def __post_init__(self):
        """Validate configuration after initialization."""
        # Validate using the ConfigValidator
        config_dict = {
            "slack_channel_webhook": self.slack_channel_webhook,
        }

        ConfigValidator.validate_mandatory_fields(config_dict, "configuration")

        logger.info(f"Configuration validated")

class NotificationService:
    """Service for sending notifications to Slack."""

    def __init__(self, webhook_url: str, function_name: str = "EDRMS Document Exception Lambda"):
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
                        "footer": "EDRMS Document Exception Lambda",
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

def get_env_variable(key: str, required: bool = True) -> Optional[str]:
    """
    Get an environment variable with proper validation.

    Args:
        key: The environment variable name
        required: Whether this variable is mandatory

    Returns:
        The value if found, None if not required and not found

    Raises:
        ValueError if required but not found
    """
    value = os.environ.get(key)

    if required and not value:
        raise ValueError(f"Required environment variable {key} is not set")

    # Log the presence of the variable (but not its value for security)
    if value:
        logger.info(f"Environment variable {key} is configured")
    else:
        logger.info(f"Environment variable {key} is not set")

    return value

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
        SNS_TOPIC_ARN=ConfigValidator.get_mandatory_env(env_data, "SNS_TOPIC_ARN"),
        LOG_GROUP_NAME=ConfigValidator.get_mandatory_env(env_data, "LOG_GROUP_NAME"),

    )

    return config

def lambda_handler(event, context):
    """
    Main Lambda handler function. 
    
     This function gets triggered by CloudWatch Logs subscription filter for EdrmsDocumentException logs:
    1. Loading configuration from both environment variables and AWS Secrets Manager
    2. Loading and parsing log data from CloudWatch Logs
    3. Accumulate log lines related to EdrmsDocumentException
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

    # Initialize notification service early with None as default
    notification_service: Optional[NotificationService] = None

    try:
        # Load environment variables first (non-sensitive configuration)
        logger.info("Loading configuration from environment variables")
        env_config = {
            # Mandatory environment variables
            "SNS_TOPIC_ARN": get_env_variable("SNS_TOPIC_ARN", required=True),
            "LOG_GROUP_NAME": get_env_variable("LOG_GROUP_NAME", required=True)
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

        # Initialize services
        notification_service = NotificationService(
            config.slack_channel_webhook, context.function_name
        )
        
        # Decode and decompress the log data
        compressed_payload = base64.b64decode(event['awslogs']['data'])
        payload = gzip.decompress(compressed_payload)
        log_data = json.loads(payload)

        log_stream_name = log_data['logStream']
        for log_event in log_data['logEvents']:
            exceptionmessage = log_event['message']
            timestamp = log_event['timestamp']
            
            logger.info(f"Log Stream: {log_stream_name}, Timestamp: {timestamp}, Message: {exceptionmessage}")
            response = logs_client.get_log_events(
                logGroupName=config.LOG_GROUP_NAME,
                logStreamName=log_stream_name,
                startTime=timestamp,
                limit=5
            )

            log_lines = [e['message'] for e in response['events']]
            result = f"EXCEPTION LOGS:\n{exceptionmessage}\n" + "\n".join(log_lines)
            notification_service.send_notification(
                        "EDRMS Document Exception",
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
