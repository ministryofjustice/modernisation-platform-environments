import logging
import os

import boto3
from botocore.exceptions import ClientError

# Set up logging
log_level = os.environ.get("LOG_LEVEL", "INFO").upper()
logger = logging.getLogger()
logger.setLevel(log_level)


def lambda_handler(event, context):
    try:
        # Get parameters from environment variables and event
        action = None
        for key in event:
            if key.upper() == "ACTION":
                action = event[key]
                break

        action = (
            action.upper() if action else None
        )  # Convert action to uppercase if it exists

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
            all_alarms = []
            paginator = cloudwatch.get_paginator("describe_alarms")
            for page in paginator.paginate():
                all_alarms.extend(
                    [alarm["AlarmName"] for alarm in page["MetricAlarms"]]
                )
            specific_alarms = all_alarms

        # Perform action on alarms in batches
        batch_size = 100  # AWS allows up to 100 alarms per API call
        for i in range(0, len(specific_alarms), batch_size):
            batch = specific_alarms[i : i + batch_size]
            try:
                if action == "DISABLE":
                    cloudwatch.disable_alarm_actions(AlarmNames=batch)
                    logger.info(f"Disabled {len(batch)} alarms")
                elif action == "ENABLE":
                    cloudwatch.enable_alarm_actions(AlarmNames=batch)
                    logger.info(f"Enabled {len(batch)} alarms")
                else:
                    raise ValueError(f"Invalid action: {action}")
            except ClientError as e:
                logger.error(f"Error processing batch: {str(e)}")

        logger.info(f"Processed {len(specific_alarms)} alarms")
        return {
            "statusCode": 200,
            "body": f"Alarms {action.lower()}d successfully",
        }
    except Exception as e:
        logger.error(f"Error processing alarms: {str(e)}")
        return {"statusCode": 500, "body": f"Error processing alarms: {str(e)}"}
