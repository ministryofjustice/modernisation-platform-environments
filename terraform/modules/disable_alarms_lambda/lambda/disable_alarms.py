import logging
import os

import boto3

# Set up logging
log_level = os.environ.get("LOG_LEVEL", "INFO").upper()
logger = logging.getLogger()
logger.setLevel(log_level)


def lambda_handler(event, context):
    try:
        # Get parameters from environment variables and event
        action = event.get("ACTION")
        specific_alarms = (
            os.environ.get("SPECIFIC_ALARMS", "").split(",")
            if os.environ.get("SPECIFIC_ALARMS")
            else []
        )

        if not action:
            raise ValueError("ACTION not provided in the event")

        # Create CloudWatch client
        cloudwatch = boto3.client("cloudwatch")

        # Get all alarms if no specific alarms are provided
        if not specific_alarms:
            response = cloudwatch.describe_alarms()
            specific_alarms = [
                alarm["AlarmName"] for alarm in response["MetricAlarms"]
            ]

        # Perform action on alarms
        for alarm_name in specific_alarms:
            if action == "DISABLE":
                cloudwatch.disable_alarm_actions(AlarmNames=[alarm_name])
                logger.info(f"Disabled alarm: {alarm_name}")
            elif action == "ENABLE":
                cloudwatch.enable_alarm_actions(AlarmNames=[alarm_name])
                logger.info(f"Enabled alarm: {alarm_name}")
            else:
                raise ValueError(f"Invalid action: {action}")

        logger.info(f"Processed {len(specific_alarms)} alarms")

        return {
            "statusCode": 200,
            "body": f"Alarms {action.lower()}d successfully",
        }
    except Exception as e:
        logger.error(f"Error processing alarms: {str(e)}")
        return {"statusCode": 500, "body": f"Error processing alarms: {str(e)}"}
