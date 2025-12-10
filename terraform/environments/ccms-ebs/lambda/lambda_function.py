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
import hashlib
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
    @staticmethod
    def validate_mandatory_fields(config_dict: Dict[str, Any], field_name: str) -> None:
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
        value = secrets_data.get(key)
        if not value or not isinstance(value, str):
            raise ValueError(
                f"{key} must be a non-empty string in secrets, got: {value}"
            )
        return value

    @staticmethod
    def get_optional_secret(secrets_data: Dict, key: str) -> Optional[str]:
        value = secrets_data.get(key)
        if value is not None and not isinstance(value, str):
            raise ValueError(
                f"{key} must be a string in secrets, got: {type(value).__name__}"
            )
        return value if value else None

    @staticmethod
    def get_mandatory_env(env_data: Dict, key: str) -> str:
        value = env_data.get(key)
        if not value:
            raise ValueError(f"{key} environment variable is required")
        return value


class SecretsManager:
    def __init__(self):
        self.client = cast(SecretsManagerClient, boto3.client("secretsmanager"))
        logger.info("Initialized Secrets Manager client")

    def get_credentials(self, secret_name: str) -> Dict[str, Union[str, int, bool]]:
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


def get_env_variable(key: str, required: bool = True) -> Optional[str]:
    value = os.environ.get(key)

    if required and not value:
        raise ValueError(f"Required environment variable {key} is not set")

    if value:
        logger.info(f"Environment variable {key} is configured")
    else:
        logger.info(f"Environment variable {key} is not set")

    return value


class NotificationService:
    def __init__(self, webhook_url: str, function_name: str = "CCMS EBS Lambda"):
        if not webhook_url:
            raise ValueError("Slack webhook URL is required for notifications")

        self.webhook_url = webhook_url
        self.function_name = function_name
        logger.info("Slack notifications configured")

    def send_notification(
        self, title: str, message: str, is_error: bool = False
    ) -> bool:
        curl = pycurl.Curl()

        try:
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


def lambda_handler(event: Dict[str, Any], context: Optional[Any]) -> Dict[str, Any]:
    logger.info("Starting CloudWatch Logs notification to Slack")

    notification_service: Optional[NotificationService] = None

    try:
        if not validate_event(event):
            logger.error("Invalid event structure")
            return {"statusCode": 400, "body": {"error": "Invalid event structure"}}

        logger.info("Loading configuration from environment variables")
        env_config = {
            "SECRET_NAME": get_env_variable("SECRET_NAME", required=True)
        }

        logger.info("Retrieving credentials from AWS Secrets Manager")
        secrets_manager = SecretsManager()
        secrets_data = secrets_manager.get_credentials(env_config["SECRET_NAME"])

        required_secrets = ["slack_channel_webhook"]
        missing_secrets = [key for key in required_secrets if key not in secrets_data]
        if missing_secrets:
            raise ValueError(f"Missing required secrets: {', '.join(missing_secrets)}")

        slack_webhook_url = ConfigValidator.get_mandatory_secret(secrets_data, "slack_channel_webhook")

        prefix_message = "Found credentials in environment variables."

        notification_service = NotificationService(
            slack_webhook_url, context.function_name if context else "CCMS EBS Lambda"
        )

        log_data = process_log_data(event["awslogs"]["data"])
        if not log_data:
            logger.warning("No log data to process")
            return {"statusCode": 400, "body": {"error": "No log data to process"}}

        combined_message, is_error = process_all_events(log_data.get("logEvents", []))
        
        if combined_message:

            final_message = prefix_message + "\n" + combined_message

            try:
                msg_hash = hashlib.sha256(final_message.encode("utf-8")).hexdigest()
                hash_file = "/tmp/last_notification_hash"
                previous_hash = None
                if os.path.exists(hash_file):
                    try:
                        with open(hash_file, "r") as fh:
                            previous_hash = fh.read().strip()
                    except Exception:
                        previous_hash = None

                if previous_hash == msg_hash:
                    logger.info("Duplicate notification detected; skipping send")
                    return {"statusCode": 200, "body": {"message": "Duplicate notification skipped"}}

                try:
                    with open(hash_file, "w") as fh:
                        fh.write(msg_hash)
                except Exception:
                    logger.debug("Failed to write notification hash; continuing without durable dedupe")

            except Exception:
                logger.debug("Notification dedupe check failed; proceeding to send")

            status_emoji = ":broken_heart:" if is_error else ":tada:"
            status_text = "Payment load lambda fail" if is_error else "Payment load lambda successful"
            title = f"{status_emoji} {status_text}"

            notification_service.send_notification(
                title,
                final_message,
                is_error=is_error
            )

            logger.info("Combined log notification sent successfully")
            return {"statusCode": 200, "body": {"message": "Notification sent"}}

        else:
            logger.warning("No log events to process")
            return {"statusCode": 200, "body": {"message": "No log events to process"}}

    except Exception as e:
        error_msg = f"Lambda execution failed: {str(e)}"
        logger.error(error_msg, exc_info=True)

        if notification_service is not None:
            try:
                notification_service.send_notification(
                    "Lambda Execution Failed", error_msg, is_error=True
                )
            except Exception as notification_error:
                logger.error(f"Failed to send error notification: {notification_error}")

        return {"statusCode": 500, "body": {"error": error_msg}}


def validate_event(event: Dict[str, Any]) -> bool:
    return bool(event.get("awslogs") and event["awslogs"].get("data"))


def process_log_data(log_data: str) -> Optional[Dict[str, Any]]:
    try:
        decoded_data = base64.b64decode(log_data)
        decompressed_data = gzip.decompress(decoded_data)
        return json.loads(decompressed_data)
    except (ValueError, TypeError, gzip.BadGzipFile) as e:
        logger.error(f"Data processing error: {str(e)}")
    except json.JSONDecodeError as e:
        logger.error(f"JSON decode error: {str(e)}")
    return None


def process_all_events(log_events: List[Dict[str, Any]]) -> Tuple[Optional[str], bool]:
    if not log_events:
        logger.warning("No log events provided")
        return None, False

    message_parts: List[str] = []
    is_error = False

    for log_event in log_events:
        try:
            message = json.loads(log_event["message"])
            
            msg = next(
                (message[k] for k in ["message", "errorMessage"] if k in message),
                "No message content available"
            )
            
            if msg == "No message content available":
                logger.debug("No message content available, skipping this event")
                continue
            
            redact_sensitive_data(message)
            
            log_level = next(
                (message[k] for k in ["level", "log_level", "type", "severity"] if k in message),
                "UNKNOWN"
            )
            if log_level.upper() == "ERROR":
                is_error = True
                logger.info("Error log level detected")
            
            message_parts.append(msg)

        except (KeyError, json.JSONDecodeError) as e:
            logger.error(f"Event processing error: {str(e)}")
        except Exception as e:
            logger.error(f"Unexpected error processing event: {str(e)}")

    if not message_parts:
        logger.warning("No valid messages to consolidate")
        return None, is_error
    
    consolidated_message = "\n".join(message_parts)

    if len(consolidated_message) > MAX_MESSAGE_SIZE:
        consolidated_message = consolidated_message[:MAX_MESSAGE_SIZE - 100] + "\n...TRUNCATED DUE TO SIZE LIMIT..."
        logger.warning("Combined message truncated due to size limit")

    return (consolidated_message, is_error)


def parse_timestamp(message: Dict[str, Any]) -> Tuple[Optional[datetime], Optional[str]]:
    for key, fmt in TIME_FORMATS:
        if value := message.get(key):
            try:
                dt = datetime.strptime(value, fmt)
                return dt, dt.strftime("%Y-%m-%d %H:%M:%S")
            except ValueError:
                continue
    return None, None


def redact_sensitive_data(message: Dict[str, Any]) -> None:
    for key in SENSITIVE_KEYS:
        if key in message:
            message[key] = "**REDACTED**"


def format_event_details(message: Dict[str, Any], timestamp: str) -> str:
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
