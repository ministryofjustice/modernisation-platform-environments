import json
import os
import boto3
import urllib3
from datetime import datetime

# Initialize AWS clients
secrets_manager = boto3.client('secretsmanager')
http = urllib3.PoolManager()

def lambda_handler(event, context):
    """
    Lambda function to send CloudWatch security alarm notifications to Slack.
    Triggered by SNS topic when CloudWatch alarms change state.
    """

    try:
        # Get Slack webhook URL from Secrets Manager
        secret_name = os.environ['SLACK_WEBHOOK_SECRET_NAME']
        slack_webhook_url = get_slack_webhook(secret_name)

        # Parse SNS message
        sns_message = json.loads(event['Records'][0]['Sns']['Message'])

        # Extract alarm details
        alarm_name = sns_message.get('AlarmName', 'Unknown Alarm')
        new_state = sns_message.get('NewStateValue', 'UNKNOWN')
        reason = sns_message.get('NewStateReason', 'No reason provided')
        timestamp = sns_message.get('StateChangeTime', datetime.utcnow().isoformat())
        region = sns_message.get('Region', 'unknown')
        account_id = sns_message.get('AWSAccountId', 'unknown')

        # Determine message color based on alarm state
        color = get_color_for_state(new_state)

        # Format Slack message
        slack_message = format_slack_message(
            alarm_name=alarm_name,
            state=new_state,
            reason=reason,
            timestamp=timestamp,
            region=region,
            account_id=account_id,
            color=color
        )

        # Send to Slack
        response = send_to_slack(slack_webhook_url, slack_message)

        print(f"Successfully sent alert to Slack for alarm: {alarm_name}")
        print(f"Slack response status: {response.status}")

        return {
            'statusCode': 200,
            'body': json.dumps({
                'message': 'Alert sent to Slack successfully',
                'alarm_name': alarm_name,
                'state': new_state
            })
        }

    except Exception as e:
        error_msg = f"Error processing alarm notification: {str(e)}"
        print(error_msg)
        print(f"Event: {json.dumps(event)}")

        return {
            'statusCode': 500,
            'body': json.dumps({
                'error': error_msg
            })
        }

def get_slack_webhook(secret_name):
    """Retrieve Slack webhook URL from AWS Secrets Manager."""
    try:
        response = secrets_manager.get_secret_value(SecretId=secret_name)
        secret_data = json.loads(response['SecretString'])
        return secret_data['webhook_url']
    except Exception as e:
        raise Exception(f"Failed to retrieve Slack webhook from Secrets Manager: {str(e)}")

def get_color_for_state(state):
    """Return Slack message color based on alarm state."""
    colors = {
        'ALARM': '#FF0000',      # Red
        'OK': '#36A64F',         # Green
        'INSUFFICIENT_DATA': '#FFA500'  # Orange
    }
    return colors.get(state, '#808080')  # Default gray

def format_slack_message(alarm_name, state, reason, timestamp, region, account_id, color):
    """Format CloudWatch alarm as Slack attachment."""

    # Add emoji based on state
    state_emoji = {
        'ALARM': ':rotating_light:',
        'OK': ':white_check_mark:',
        'INSUFFICIENT_DATA': ':warning:'
    }.get(state, ':question:')

    return {
        "attachments": [
            {
                "color": color,
                "title": f"{state_emoji} CloudWatch Security Alarm: {alarm_name}",
                "fields": [
                    {
                        "title": "State",
                        "value": state,
                        "short": True
                    },
                    {
                        "title": "Timestamp",
                        "value": timestamp,
                        "short": True
                    },
                    {
                        "title": "Account",
                        "value": account_id,
                        "short": True
                    },
                    {
                        "title": "Region",
                        "value": region,
                        "short": True
                    },
                    {
                        "title": "Reason",
                        "value": reason,
                        "short": False
                    }
                ],
                "footer": "OAS CloudWatch Security Alerts",
                "ts": int(datetime.utcnow().timestamp())
            }
        ]
    }

def send_to_slack(webhook_url, message):
    """Send formatted message to Slack webhook."""
    encoded_message = json.dumps(message).encode('utf-8')

    response = http.request(
        'POST',
        webhook_url,
        body=encoded_message,
        headers={'Content-Type': 'application/json'}
    )

    if response.status != 200:
        raise Exception(f"Slack webhook returned status {response.status}: {response.data.decode('utf-8')}")

    return response
