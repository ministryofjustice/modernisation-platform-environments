import boto3
import json
import logging
import re

logger = logging.getLogger()
logger.setLevel(logging.INFO)

def lambda_handler(event, context):

    cloudwatch = boto3.client('cloudwatch')
    for record in event['Records']:

        message = json.loads(record['Sns']['Message'])

        event_message = message.get("Event Message")

        logger.info("SNS Message: %s",message)

        if re.search(r"^Replication task has started.$",event_message):
            logger.info("Task started")
            cloudwatch.put_metric_data(
                Namespace='CustomDMSMetrics',
                MetricData=[
                    {
                        'MetricName': 'DMSReplicationFailure',
                        'Dimensions': [
                            {'Name': 'Service', 'Value': 'DMS'}
                        ],
                        'Value': 0,  # Reset Below Trigger threshold (Task Started)
                        'Unit': 'Count'
                    }
                ]
            )
        elif re.search(r"^Replication task has failed..*$",event_message):
            logger.info("Task failed")
            cloudwatch.put_metric_data(
                Namespace='CustomDMSMetrics',
                MetricData=[
                    {
                        'MetricName': 'DMSReplicationFailure',
                        'Dimensions': [
                            {'Name': 'Service', 'Value': 'DMS'}
                        ],
                        'Value': 1,  # Trigger threshold (Task Failed)
                        'Unit': 'Count'
                    }
                ]
            )