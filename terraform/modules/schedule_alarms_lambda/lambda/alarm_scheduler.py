import fnmatch
import logging
import os

import boto3
from botocore.exceptions import ClientError

# Set up logging
log_level = os.environ.get("LOG_LEVEL", "INFO").upper()
logger = logging.getLogger()
logger.setLevel(log_level)


def matches_pattern(alarm_name, patterns):
    """Check if alarm name matches any of the provided patterns"""
    if not patterns:
        return True
    return any(
        fnmatch.fnmatch(alarm_name, pattern.strip()) for pattern in patterns
    )


def get_matching_alarms(cloudwatch, specific_alarms=None, alarm_patterns=None):
    """Get all alarms that match either specific names or patterns"""
    matching_alarms = []
    paginator = cloudwatch.get_paginator("describe_alarms")

    # Convert specific_alarms to a set for O(1) lookup
    specific_alarm_set = set(specific_alarms) if specific_alarms else set()

    for page in paginator.paginate():
        for alarm in page["MetricAlarms"]:
            alarm_name = alarm["AlarmName"]
            # Include alarm if it's in specific_alarms or matches patterns
            if (
                (not specific_alarm_set and not alarm_patterns)
                or (alarm_name in specific_alarm_set)
                or (
                    alarm_patterns
                    and matches_pattern(alarm_name, alarm_patterns)
                )
            ):
                matching_alarms.append(alarm_name)

    return matching_alarms


def lambda_handler(event, context):
    try:
        # Get parameters from environment variables and event
        action = None
        for key in event:
            if key.upper() == "ACTION":
                action = event[key]
                break

        action = action.upper() if action else None

        # Get specific alarms and patterns from environment variables
        specific_alarms = (
            os.environ.get("SPECIFIC_ALARMS", "").split(",")
            if os.environ.get("SPECIFIC_ALARMS")
            else []
        )
        specific_alarms = [a.strip() for a in specific_alarms if a.strip()]

        alarm_patterns = (
            os.environ.get("ALARM_PATTERNS", "").split(",")
            if os.environ.get("ALARM_PATTERNS")
            else []
        )
        alarm_patterns = [p.strip() for p in alarm_patterns if p.strip()]

        if not action:
            raise ValueError("ACTION not provided in the event")

        # Create CloudWatch client
        cloudwatch = boto3.client("cloudwatch")

        # Get matching alarms
        matching_alarms = get_matching_alarms(
            cloudwatch,
            specific_alarms=specific_alarms,
            alarm_patterns=alarm_patterns,
        )

        if not matching_alarms:
            logger.info("No matching alarms found")
            return {"statusCode": 200, "body": "No matching alarms found"}

        # Perform action on alarms in batches
        batch_size = 100  # AWS allows up to 100 alarms per API call
        for i in range(0, len(matching_alarms), batch_size):
            batch = matching_alarms[i : i + batch_size]
            try:
                if action == "DISABLE":
                    cloudwatch.disable_alarm_actions(AlarmNames=batch)
                    logger.info(f"Disabled {len(batch)} alarms")
                elif action == "ENABLE":
                    cloudwatch.enable_alarm_actions(AlarmNames=batch)
                    # We put newly re-enabled alarms into INSUFFICIENT_DATA state to force a re-evaulation.
                    # A new PagerDuty notification will be sent for any which go into ALARM state on re-evaluation.
                    # Unfortunately there is no batching of alarms for the set_alarm_state API so we need to
                    # loop through each one individually.
                    for alarm in batch:
                       cloudwatch.set_alarm_state(AlarmName=alarm,StateValue='INSUFFICIENT_DATA',StateReason='Re-evaluate alarm after AlarmActions re-enabled')
                    logger.info(f"Enabled {len(batch)} alarms")
                else:
                    raise ValueError(f"Invalid action: {action}")
            except ClientError as e:
                logger.error(f"Error processing batch: {str(e)}")

        logger.info(f"Processed {len(matching_alarms)} alarms")
        return {
            "statusCode": 200,
            "body": f"Alarms {action.lower()}d successfully",
        }
    except Exception as e:
        logger.error(f"Error processing alarms: {str(e)}")
        return {"statusCode": 500, "body": f"Error processing alarms: {str(e)}"}
