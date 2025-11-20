import base64
import gzip
import io
import json
import logging
import os
import time
from datetime import datetime
from typing import Any, Dict, List, Optional, Tuple, Union, cast

import boto3
import pycurl
from botocore.exceptions import ClientError
from mypy_boto3_secretsmanager import SecretsManagerClient

logger = logging.getLogger()
logger.setLevel(logging.INFO)

MAX_MESSAGE_SIZE: int = 256 * 1024  # 256KB
SENSITIVE_KEYS: set = {"password", "secret", "authorization", "access_key"}
TIME_FORMATS: Tuple[Tuple[str, str], ...] = (
    ("timestamp", "%Y-%m-%dT%H:%M:%SZ"),
    ("time", "%Y-%m-%dT%H:%M:%S.%fZ"),
    ("@timestamp", "%Y-%m-%dT%H:%M:%S.%fZ"),
)


class ConfigValidator:
    """Validator class for configuration validation."""

    @staticmethod
    def validate_mandatory_fields(config_dict: Dict[str, Any], field_name: str) -> None:
        """Validate that all mandatory fields are present and non-empty."""
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


class NotificationService:
    """Service for sending notifications to Slack."""

    def __init__(self, webhook_url: str, function_name: str = "CCMS EBS Lambda"):
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
                        "footer": "CCMS EBS Lambda",
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


def lambda_handler(event: Dict[str, Any], context: Optional[Any]) -> Dict[str, Any]:
    """
    Main Lambda handler function.
    
    Process CloudWatch logs and send notifications to Slack using secrets from AWS Secrets Manager.
    
    Args:
        event: Lambda event data containing CloudWatch Logs
        context: Lambda context object

    Returns:
        Response dictionary with status and results
    """
    logger.info("Starting CloudWatch Logs notification to Slack")

    # Initialize notification service early with None as default
    notification_service: Optional[NotificationService] = None

    try:
        if not validate_event(event):
            logger.error("Invalid event structure")
            return {"statusCode": 400, "body": {"error": "Invalid event structure"}}

        # Load environment variables first (non-sensitive configuration)
        logger.info("Loading configuration from environment variables")
        env_config = {
            "SECRET_NAME": get_env_variable("SECRET_NAME", required=True)
        }

        # Retrieve sensitive credentials from Secrets Manager
        logger.info("Retrieving credentials from AWS Secrets Manager")
        secrets_manager = SecretsManager()
        secrets_data = secrets_manager.get_credentials(env_config["SECRET_NAME"])

        # Validate that required credentials are present
        required_secrets = ["slack_channel_webhook"]
        missing_secrets = [key for key in required_secrets if key not in secrets_data]
        if missing_secrets:
            raise ValueError(f"Missing required secrets: {', '.join(missing_secrets)}")

        # Extract and validate the webhook URL
        slack_webhook_url = ConfigValidator.get_mandatory_secret(secrets_data, "slack_channel_webhook")

        # Initialize notification service
        notification_service = NotificationService(
            slack_webhook_url, context.function_name if context else "CCMS EBS Lambda"
        )

        # Process log data
        log_data = process_log_data(event["awslogs"]["data"])
        if not log_data:
            logger.warning("No log data to process")
            return {"statusCode": 400, "body": {"error": "No log data to process"}}

        # Combine all log events into a single message
        combined_message = process_all_events(log_data.get("logEvents", []))
        
        if combined_message:
            notification_service.send_notification(
                "CloudWatch Logs Alert",
                combined_message,
                is_error=True
            )
            logger.info("Combined log notification sent successfully")
            return {"statusCode": 200, "body": {"message": "Notification sent"}}
        else:
            logger.warning("No log events to process")
            return {"statusCode": 200, "body": {"message": "No log events to process"}}

    except Exception as e:
        error_msg = f"Lambda execution failed: {str(e)}"
        logger.error(error_msg, exc_info=True)

        # Send error notification if notification service is available
        if notification_service is not None:
            try:
                notification_service.send_notification(
                    "Lambda Execution Failed", error_msg, is_error=True
                )
            except Exception as notification_error:
                logger.error(f"Failed to send error notification: {notification_error}")

        return {"statusCode": 500, "body": {"error": error_msg}}


def validate_event(event: Dict[str, Any]) -> bool:
    """Validate the structure of the incoming event."""
    return bool(event.get("awslogs") and event["awslogs"].get("data"))


def process_log_data(log_data: str) -> Optional[Dict[str, Any]]:
    """Process and decode the compressed log data."""
    try:
        decoded_data = base64.b64decode(log_data)
        decompressed_data = gzip.decompress(decoded_data)
        return json.loads(decompressed_data)
    except (ValueError, TypeError, gzip.BadGzipFile) as e:
        logger.error(f"Data processing error: {str(e)}")
    except json.JSONDecodeError as e:
        logger.error(f"JSON decode error: {str(e)}")
    return None


def process_all_events(log_events: List[Dict[str, Any]]) -> Optional[str]:
    """
    Process all log events and combine them into a single message variable.
    
    Args:
        log_events: List of log events from CloudWatch Logs
        
    Returns:
        Combined message as a single string, or None if no events processed
    """
    if not log_events:
        logger.warning("No log events provided")
        return None

    message_parts: List[str] = []

    for log_event in log_events:
        try:
            message = json.loads(log_event["message"])
            redact_sensitive_data(message)
            dt, formatted_ts = parse_timestamp(message)

            if not formatted_ts:
                formatted_ts = datetime.utcnow().strftime("%Y-%m-%d %H:%M:%S")
                logger.warning("Using fallback timestamp")

            # Format individual event details
            event_details = format_event_details(message, formatted_ts)
            message_parts.append(event_details)

        except (KeyError, json.JSONDecodeError) as e:
            logger.error(f"Event processing error: {str(e)}")
            message_parts.append(f"Error processing event: {str(e)}")
        except Exception as e:
            logger.error(f"Unexpected error processing event: {str(e)}")
            message_parts.append(f"Unexpected error: {str(e)}")

    # Combine all message parts into a single message with separators
    separator = "\n" + "=" * 50 + "\n"
    combined_message = separator + separator.join(message_parts)

    # Check size limit
    if len(combined_message) > MAX_MESSAGE_SIZE:
        combined_message = combined_message[:MAX_MESSAGE_SIZE - 100] + "\n...TRUNCATED DUE TO SIZE LIMIT..."
        logger.warning("Combined message truncated due to size limit")

    return combined_message if message_parts else None


def parse_timestamp(message: Dict[str, Any]) -> Tuple[Optional[datetime], Optional[str]]:
    """Parse timestamp from message using multiple possible formats."""
    for key, fmt in TIME_FORMATS:
        if value := message.get(key):
            try:
                dt = datetime.strptime(value, fmt)
                return dt, dt.strftime("%Y-%m-%d %H:%M:%S")
            except ValueError:
                continue
    return None, None


def redact_sensitive_data(message: Dict[str, Any]) -> None:
    """Redact sensitive keys in-place."""
    for key in SENSITIVE_KEYS:
        if key in message:
            message[key] = "**REDACTED**"


def format_event_details(message: Dict[str, Any], timestamp: str) -> str:
    """
    Format individual event details into a structured string.
    
    Args:
        message: The parsed log message
        timestamp: The formatted timestamp
        
    Returns:
        Formatted event details as a string
    """
    msg = next(
        (message[k] for k in ["message", "errorMessage"] if k in message),
        "No message content available"
    )
    lvl = next(
        (message[k] for k in ["level", "log_level", "type", "severity"] if k in message),
        "UNKNOWN"
    )

    payload_lines = [
        f"Date: {timestamp}",
        f"Level: {lvl.upper()}",
        f"Message: {msg}",
    ]

    if stack := message.get("stackTrace"):
        payload_lines.append(f"\nStack Trace:\n{json.dumps(stack, indent=2)}")

    payload_lines.extend([
        "\nRaw Log:",
        json.dumps(message, indent=2)
    ])

    return "\n".join(payload_lines)


if __name__ == "__main__":
    test_payload = {
        "logGroup": "/aws/lambda/test-function",
        "logStream": "2024/01/01/[LATEST]abc123",
        "logEvents": [
            {
                "message": json.dumps({
                    "time": "2024-10-16T13:19:11.191Z",
                    "type": "error",
                    "message": "Sample error message",
                    "secret": "should_be_redacted"
                }),
                "timestamp": 1697453951191
            },
            {
                "message": json.dumps({
                    "time": "2024-10-16T13:19:12.191Z",
                    "type": "warning",
                    "message": "Sample warning message",
                    "password": "should_also_be_redacted"
                }),
                "timestamp": 1697453952191
            }
        ]
    }

    compressed = gzip.compress(json.dumps(test_payload).encode())
    test_event = {
        "awslogs": {
            "data": base64.b64encode(compressed).decode()
        }
    }

    os.environ["SECRET_NAME"] = "ccms-ebs-slack-webhook"  # Replace with your actual secret name
    result = lambda_handler(test_event, None)
    print(f"Lambda result: {result}")