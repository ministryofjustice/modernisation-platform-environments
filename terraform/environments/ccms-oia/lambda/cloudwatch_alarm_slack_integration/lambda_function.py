"""
AWS Lambda function to process CloudWatch Alarms and GuardDuty findings from SNS Topic
and publish notifications to Slack channels. Sends GuardDuty findings to a dedicated
security channel and CloudWatch alarms to the standard monitoring channel.

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
    slack_channel_webhook_guardduty: str

    def __post_init__(self):
        """Validate configuration after initialization."""
        # Validate using the ConfigValidator
        config_dict = {
            "slack_channel_webhook": self.slack_channel_webhook,
            "slack_channel_webhook_guardduty": self.slack_channel_webhook_guardduty,
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
        slack_channel_webhook_guardduty=ConfigValidator.get_mandatory_secret(secrets_data, "slack_channel_webhook_guardduty"),

    )

    return config


class NotificationService:
    """Service for sending notifications to Slack."""

    def __init__(self, webhook_url: str, function_name: str = "CloudWatch SNS Alarm to Lambda"):
        if not webhook_url:
            raise ValueError("Slack webhook URL is required for notifications")

        self.webhook_url = webhook_url
        self.function_name = function_name
        # Log masked webhook URL for debugging
        masked_url = webhook_url[:30] + "..." if len(webhook_url) > 30 else "[SHORT_URL]"
        logger.info(f"Slack notifications configured with webhook: {masked_url}")

    @staticmethod
    def format_timestamp(timestamp_str: Optional[str]) -> str:
        """Format ISO timestamp to readable format."""
        if not timestamp_str:
            return datetime.utcnow().strftime("%a, %d %b %Y %H:%M:%S UTC")
        try:
            dt = datetime.strptime(timestamp_str, "%Y-%m-%dT%H:%M:%S.%fZ")
            return dt.strftime("%a, %d %b %Y %H:%M:%S UTC")
        except ValueError:
            # Try alternative format without microseconds
            try:
                dt = datetime.strptime(timestamp_str, "%Y-%m-%dT%H:%M:%SZ")
                return dt.strftime("%a, %d %b %Y %H:%M:%S UTC")
            except ValueError:
                logger.warning(f"Unable to parse timestamp: {timestamp_str}")
                return timestamp_str

    def send_notification(
        self, title: str, alarm_details: Dict[str, Any], timestamp: str, notification_type: str, is_error: bool = False
    ) -> bool:
        """Send a notification to Slack using the webhook."""
        logger.info(f"=== Starting notification preparation ===")
        logger.info(f"Notification type: {notification_type}")
        logger.info(f"Title: {title}")
        logger.info(f"Timestamp: {timestamp}")
        logger.info(f"Is Error: {is_error}")
        logger.info(f"Alarm details keys: {list(alarm_details.keys())}")
        
        try:
            if notification_type == "GuardDuty":
                logger.info("Building GuardDuty payload...")
                payload = self._build_guardduty_payload(alarm_details, title, timestamp)
            elif notification_type == "CloudWatch Alarm":
                logger.info("Building CloudWatch payload...")
                payload = self._build_cloudwatch_payload(alarm_details, title, timestamp, is_error)
            else:
                raise ValueError(f"Unsupported notification type: {notification_type}")
            
            logger.info(f"Payload built successfully with {len(payload.get('blocks', []))} blocks")
            logger.info(f"Payload preview: {json.dumps(payload, indent=2)[:500]}...")
            
            return self._send_to_slack(payload, title)
        except Exception as e:
            logger.error(f"Error building notification payload: {e}", exc_info=True)
            raise

    def _build_guardduty_payload(self, alarm_details: Dict[str, Any], title: str, timestamp: str) -> Dict[str, Any]:
        """Build Slack payload for GuardDuty findings."""
        detail = alarm_details.get('detail', {})
        if not detail:
            raise ValueError("Missing 'detail' in GuardDuty finding")
        
        # Extract severity and determine emoji
        severity = detail.get('severity', 0)
        if severity < 4.0:
            emoji = ":large_blue_circle:"
            severity_str = "Low"
        elif severity < 7.0:
            emoji = ":large_orange_circle:"
            severity_str = "Medium"
        elif severity < 9.0:
            emoji = ":small_red_triangle:"
            severity_str = "High"
        else:
            emoji = ":broken_heart:"
            severity_str = "Critical"

        # Extract finding details
        finding_type = detail.get('type', 'Unknown Finding')
        region = detail.get('region', 'Unknown Region')
        account_id = detail.get('accountId', 'Unknown Account')
        finding_title = detail.get('title', 'No Title Provided')
        finding_description = detail.get('description', 'No description available')
        
        # Extract service details
        service = detail.get('service', {})
        threat_count = service.get('count', 'N/A')
        first_seen = self.format_timestamp(service.get('eventFirstSeen'))
        last_seen = self.format_timestamp(service.get('eventLastSeen'))
        
        # Extract resource details for S3 bucket if available
        resource = detail.get('resource', {})
        resource_type = resource.get('resourceType', 'Unknown')
        
        # Build additional context for S3-related findings
        additional_fields = []
        if resource_type == 'S3Bucket':
            s3_details = resource.get('s3BucketDetails', [])
            if s3_details:
                bucket_name = s3_details[0].get('name', 'Unknown')
                additional_fields.append({
                    "type": "mrkdwn",
                    "text": f"*S3 Bucket:* {bucket_name}"
                })
        
        # Build header
        header = f"{emoji} | GuardDuty Finding | {region} | Account: {account_id}"
        
        # Prepare the Slack message with formatting
        blocks = [
            {
                "type": "header",
                "text": {"type": "plain_text", "text": header}
            },
            {
                "type": "section",
                "text": {"type": "mrkdwn", "text": f"*Finding Type:* {finding_type}"}
            },
            {
                "type": "section",
                "text": {"type": "mrkdwn", "text": f"*{finding_title}*"}
            },
            {
                "type": "section",
                "text": {"type": "mrkdwn", "text": finding_description}
            },
            {
                "type": "divider"
            },
            {
                "type": "section",
                "fields": [
                    {
                        "type": "mrkdwn",
                        "text": f"*First Seen:* {first_seen}"
                    },
                    {
                        "type": "mrkdwn",
                        "text": f"*Last Seen:* {last_seen}"
                    }
                ]
            },
            {
                "type": "section",
                "fields": [
                    {
                        "type": "mrkdwn",
                        "text": f"*Severity:* {severity_str} ({severity})"
                    },
                    {
                        "type": "mrkdwn",
                        "text": f"*Threat Count:* {threat_count}"
                    }
                ]
            }
        ]
        
        # Add resource-specific fields if available
        if additional_fields:
            blocks.append({
                "type": "section",
                "fields": additional_fields
            })
        
        return {"blocks": blocks}

    def _build_cloudwatch_payload(self, alarm_details: Dict[str, Any], title: str, timestamp: str, is_error: bool) -> Dict[str, Any]:
        """Build Slack payload for CloudWatch alarms."""
        alarm_name = alarm_details.get('AlarmName', 'Unknown Alarm')
        region = alarm_details.get('Region', 'Unknown Region')
        alarm_state = alarm_details.get('NewStateValue', 'UNKNOWN')
        reason = alarm_details.get('NewStateReason', 'No reason provided')
        alarm_description = alarm_details.get('AlarmDescription', 'No description available')
        
        # Extract trigger details
        trigger = alarm_details.get('Trigger', {})
        namespace = trigger.get('Namespace', 'N/A')
        metric_name = trigger.get('MetricName', 'N/A')
        dimensions = trigger.get('Dimensions', [])
        
        # Format dimensions nicely
        dim_text = '\n'.join([f"{d.get('name', 'Unknown')}: {d.get('value', 'Unknown')}" for d in dimensions])
        if not dim_text:
            dim_text = 'No dimensions'
        
        # Determine emoji based on alarm state
        emoji = ":broken_heart:" if is_error else ":white_check_mark:"
        header_title = f"{emoji} | {title} | {alarm_name} | {region}"
        
        # Build blocks
        blocks = [
            {
                "type": "header",
                "text": {"type": "plain_text", "text": f"{alarm_state} - {alarm_name}"}
            },
            {
                "type": "section",
                "text": {"type": "mrkdwn", "text": f"*{header_title}*"}
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
                        "text": f"*Description:* {alarm_description}"
                    }
                ]
            }
        ]
        
        # Add resource details if dimensions exist
        if dim_text != 'No dimensions':
            blocks.append({
                "type": "section",
                "text": {"type": "mrkdwn", "text": f"*Resource Details:*\n{dim_text}"}
            })
        
        return {"blocks": blocks}

    def _send_to_slack(self, payload: Dict[str, Any], title: str) -> bool:
        """Send payload to Slack webhook using cURL."""
        curl = pycurl.Curl()
        try:
            # Convert payload to JSON
            json_payload = json.dumps(payload)
            logger.info(f"Sending to Slack - Payload size: {len(json_payload)} bytes")
            logger.info(f"Full payload: {json_payload[:1000]}...")  # Log first 1000 chars
            
            # Configure curl for HTTP POST with JSON
            curl.setopt(pycurl.URL, self.webhook_url)
            curl.setopt(pycurl.POST, 1)
            curl.setopt(pycurl.POSTFIELDS, json_payload)
            curl.setopt(pycurl.HTTPHEADER, ["Content-Type: application/json"])
            curl.setopt(pycurl.TIMEOUT, 30)  # Increased timeout
            curl.setopt(pycurl.VERBOSE, 0)  # Disable verbose for cleaner logs
            
            # Buffer for response
            response_buffer = io.BytesIO()
            curl.setopt(pycurl.WRITEDATA, response_buffer)
            
            # Send the notification
            logger.info("Executing HTTP POST to Slack...")
            curl.perform()
            
            # Check HTTP status code
            http_code = curl.getinfo(pycurl.RESPONSE_CODE)
            response_text = response_buffer.getvalue().decode('utf-8', errors='replace')
            
            logger.info(f"Slack response - HTTP {http_code}: {response_text}")
            
            if http_code == 200:
                if response_text == 'ok':
                    logger.info(f"✓ Slack notification sent successfully: {title}")
                    return True
                else:
                    logger.warning(f"Slack returned 200 but unexpected response: {response_text}")
                    return True  # Still consider it successful
            elif http_code >= 400:
                logger.error(f"Slack API error {http_code}: {response_text}")
                raise Exception(f"HTTP error {http_code}: {response_text}")
            else:
                logger.warning(f"Unexpected HTTP status {http_code}: {response_text}")
                return False
            
        except pycurl.error as e:
            logger.error(f"cURL error sending to Slack: {e}", exc_info=True)
            return False
        except Exception as e:
            logger.error(f"Failed to send Slack notification: {e}", exc_info=True)
            return False
        finally:
            curl.close()

def lambda_handler(event, context):
    """
    Main Lambda handler function. 
    
    This function gets triggered by SNS Topic subscriptions to CloudWatch Alarms and GuardDuty findings.
    It performs the following steps:
    1. Loading Slack webhooks from AWS Secrets Manager
    2. Parsing the event (SNS or direct EventBridge)
    3. Formatting the alarm/finding details
    4. Sending notifications to appropriate Slack channels
    
    Args:
        event: Lambda event data (can override SECRET_NAME via 'secret_name' key)
        context: Lambda context object
    Returns:
        Response dictionary with status and results
    """
    tracemalloc.start()
    notification_service = None

    try:
        # Log the incoming event for debugging
        logger.info("="*80)
        logger.info("Lambda function invoked")
        logger.info(f"Event keys: {list(event.keys())}")
        logger.info(f"Full event: {json.dumps(event, indent=2, default=str)[:2000]}...")  # First 2000 chars
        logger.info("="*80)
        
        # Parse event and determine source
        event_info = _parse_event(event)
        source = event_info['source']
        message_data = event_info['message_data']
        timestamp_str = event_info['timestamp']
        
        logger.info(f"✓ Event parsed successfully")
        logger.info(f"Source: {source}")
        logger.info(f"Timestamp: {timestamp_str}")
        logger.info(f"Message data keys: {list(message_data.keys())}")
        
        # Get secret name from environment or event
        secret_name = os.environ.get("SECRET_NAME", event.get("secret_name"))
        if not secret_name:
            raise ValueError("SECRET_NAME not found in environment or event")
        if not isinstance(secret_name, str):
            raise ValueError(
                f"SECRET_NAME must be a string, got: {type(secret_name).__name__}"
            )
        
        # Retrieve sensitive credentials from Secrets Manager
        logger.info(f"Retrieving credentials from AWS Secrets Manager: {secret_name}")
        secrets_manager = SecretsManager()
        secrets_data = secrets_manager.get_credentials(secret_name)
        logger.info(f"Retrieved {len(secrets_data)} secrets")
        logger.info(f"Secret keys available: {list(secrets_data.keys())}")

        # Parse combined configuration
        logger.info("Parsing configuration from environment and secrets")
        config = parse_config_from_env_and_secrets({}, secrets_data)
        logger.info("✓ Configuration validated successfully")

        # Determine notification details based on source
        if source == "aws.guardduty":
            logger.info(">>> Processing GuardDuty finding")
            webhook_url = config.slack_channel_webhook_guardduty
            notification_title = "GuardDuty Finding Notification"
            notification_type = "GuardDuty"
            is_error = True  # GuardDuty findings are always treated as potential security issues
            logger.info(f"Using GuardDuty webhook (length: {len(webhook_url)})")
        elif source == "aws.cloudwatch":
            logger.info(">>> Processing CloudWatch Alarm")
            webhook_url = config.slack_channel_webhook
            notification_title = "CloudWatch Alarm Notification"
            notification_type = "CloudWatch Alarm"
            # Determine if it's an error based on alarm state
            new_state = message_data.get('NewStateValue', 'ALARM')
            is_error = new_state != "OK"
            logger.info(f"Alarm state: {new_state}, Is error: {is_error}")
            logger.info(f"Using CloudWatch webhook (length: {len(webhook_url)})")
        else:
            # Default to CloudWatch for backward compatibility
            logger.warning(f"Unknown source '{source}', defaulting to CloudWatch Alarm handling")
            webhook_url = config.slack_channel_webhook
            notification_title = "CloudWatch Alarm Notification"
            notification_type = "CloudWatch Alarm"
            new_state = message_data.get('NewStateValue', 'ALARM')
            is_error = new_state != "OK"
        
        # Format timestamp
        formatted_timestamp = NotificationService.format_timestamp(timestamp_str)
        logger.info(f"Formatted timestamp: {formatted_timestamp}")
        
        # Initialize notification service
        logger.info("Initializing NotificationService...")
        notification_service = NotificationService(
            webhook_url, context.function_name
        )
        
        # Send notification
        logger.info(f"Sending {notification_type} notification to Slack...")
        success = notification_service.send_notification(
            notification_title,
            message_data,
            formatted_timestamp,
            notification_type,
            is_error
        )
        
        logger.info(f"Notification send result: {'SUCCESS' if success else 'FAILED'}")
        
        if not success:
            logger.warning("Notification sending reported failure, but continuing")
        
        # Prepare response
        response = {
            "statusCode": 200,
            "body": {
                "message": f"Successfully processed {notification_type}",
                "source": source,
                "notification_sent": success
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
                error_payload = {
                    "blocks": [
                        {
                            "type": "header",
                            "text": {"type": "plain_text", "text": ":x: Lambda Execution Failed"}
                        },
                        {
                            "type": "section",
                            "text": {"type": "mrkdwn", "text": f"```{error_msg}```"}
                        }
                    ]
                }
                notification_service._send_to_slack(error_payload, "Lambda Execution Failed")
            except Exception as notification_error:
                logger.error(f"Failed to send error notification: {notification_error}")

        # Return error response
        return {"statusCode": 500, "body": {"error": error_msg}}
        
    finally:
        current, peak = tracemalloc.get_traced_memory()
        logger.info(f"Current memory usage: {current / 1024 / 1024:.2f} MB; Peak: {peak / 1024 / 1024:.2f} MB")
        tracemalloc.stop()


def _parse_event(event: Dict[str, Any]) -> Dict[str, Any]:
    """
    Parse Lambda event to extract source, message data, and timestamp.
    
    Handles both SNS-wrapped events and direct EventBridge events.
    
    Args:
        event: Lambda event dictionary
    Returns:
        Dictionary with 'source', 'message_data', and 'timestamp' keys
    Raises:
        ValueError: If event format is not recognised
    """
    # Check if this is an SNS event
    if 'Records' in event and len(event['Records']) > 0:
        sns_record = event['Records'][0]
        if 'Sns' in sns_record:
            sns_message = sns_record['Sns']
            message_str = sns_message.get('Message', '{}')
            
            # Parse the message
            try:
                message_data = json.loads(message_str)
            except json.JSONDecodeError:
                raise ValueError(f"Failed to parse SNS message as JSON: {message_str}")
            
            # Determine source from message content
            # GuardDuty events have 'source' field set to 'aws.guardduty'
            # CloudWatch alarms have 'AlarmName' field
            if 'source' in message_data and message_data['source'] == 'aws.guardduty':
                source = 'aws.guardduty'
                timestamp = message_data.get('time')
            elif 'AlarmName' in message_data:
                # This is a CloudWatch alarm
                source = 'aws.cloudwatch'
                timestamp = sns_message.get('Timestamp')
            else:
                # Try to infer from message structure
                if 'detail' in message_data and 'detail-type' in message_data:
                    # EventBridge format
                    source = message_data.get('source', 'unknown')
                    timestamp = message_data.get('time')
                else:
                    # Default to CloudWatch if it has alarm-like fields
                    source = 'aws.cloudwatch'
                    timestamp = sns_message.get('Timestamp')
            
            logger.info(f"Parsed SNS event - Source: {source}, Has AlarmName: {'AlarmName' in message_data}, Has detail: {'detail' in message_data}")
            
            return {
                'source': source,
                'message_data': message_data,
                'timestamp': timestamp
            }
    
    # Check if this is a direct EventBridge event (GuardDuty)
    if 'source' in event and event['source'] == 'aws.guardduty':
        logger.info("Parsed direct EventBridge GuardDuty event")
        return {
            'source': event['source'],
            'message_data': event,
            'timestamp': event.get('time')
        }
    
    # Check if this is a direct CloudWatch alarm (rare, but handle it)
    if 'AlarmName' in event:
        logger.info("Parsed direct CloudWatch alarm event")
        return {
            'source': 'aws.cloudwatch',
            'message_data': event,
            'timestamp': event.get('StateChangeTime') or datetime.utcnow().isoformat()
        }
    
    # Unsupported event format
    raise ValueError(f"Unsupported event format. Event keys: {list(event.keys())}")
