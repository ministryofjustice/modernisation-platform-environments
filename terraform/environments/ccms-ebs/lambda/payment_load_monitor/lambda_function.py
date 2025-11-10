import base64
import gzip
import json
import logging
import os
from datetime import datetime
from typing import Any, Dict, Optional, Tuple

import boto3

logger = logging.getLogger()
logger.setLevel(logging.INFO)

sns_client = boto3.client("sns")

SNS_TOPIC_ARN: str = os.getenv("SNS_TOPIC_ARN", "")
MAX_SNS_SIZE: int = 256 * 1024  # 256KB
SENSITIVE_KEYS: set = {"password", "secret", "authorization", "access_key"}
TIME_FORMATS: Tuple[Tuple[str, str], ...] = (
    ("timestamp", "%Y-%m-%dT%H:%M:%SZ"),
    ("time", "%Y-%m-%dT%H:%M:%S.%fZ"),
    ("@timestamp", "%Y-%m-%dT%H:%M:%S.%fZ"),
)


def lambda_handler(event: Dict[str, Any], context: Optional[Any]) -> None:
    """Process CloudWatch logs and send notifications via SNS."""

    if not validate_event(event):
        logger.error("Invalid event structure")
        return

    if not SNS_TOPIC_ARN:
        logger.error("SNS_TOPIC_ARN environment variable not set")
        return

    try:
        log_data = process_log_data(event["awslogs"]["data"])
        if not log_data:
            return

        for log_event in log_data.get("logEvents", []):
            process_single_event(log_event)

    except Exception as e:
        logger.error(f"Unhandled exception in Lambda handler: {str(e)}")
        raise


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


def process_single_event(log_event: Dict[str, Any]) -> None:
    """Process an individual log event."""
    try:
        message = json.loads(log_event["message"])
        redact_sensitive_data(message)
        dt, formatted_ts = parse_timestamp(message)

        if not formatted_ts:
            formatted_ts = datetime.utcnow().strftime("%Y-%m-%d %H:%M:%S")
            logger.warning("Using fallback timestamp")

        send_to_slack_via_sns(message, formatted_ts)

    except (KeyError, json.JSONDecodeError) as e:
        logger.error(f"Event processing error: {str(e)}")
    except Exception as e:
        logger.error(f"Unexpected error processing event: {str(e)}")


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


def send_to_slack_via_sns(message: Dict[str, Any], timestamp: str) -> None:
    """Construct and send notification payload to SNS."""
    try:
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

        payload = "\n".join(payload_lines)

        if len(payload) > MAX_SNS_SIZE:
            payload = payload[:MAX_SNS_SIZE - 100] + "\n...TRUNCATED DUE TO SIZE LIMIT..."

        response = sns_client.publish(
            TopicArn=SNS_TOPIC_ARN,
            Message=payload,
            Subject=f"AWS Log Alert - {lvl.upper()}",
        )
        logger.info(f"Message sent to SNS: {response['MessageId']}")

    except sns_client.exceptions.InvalidParameterException as e:
        logger.error(f"Invalid SNS parameters: {str(e)}")
    except sns_client.exceptions.NotFoundException:
        logger.error("SNS topic not found")
    except Exception as e:
        logger.error(f"Failed to send SNS message: {str(e)}")


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
                })
            }
        ]
    }

    compressed = gzip.compress(json.dumps(test_payload).encode())
    test_event = {
        "awslogs": {
            "data": base64.b64encode(compressed).decode()
        }
    }

    os.environ["SNS_TOPIC_ARN"] = "arn:aws:sns:us-east-1:123456789012:MyTopic"
    lambda_handler(test_event, None)