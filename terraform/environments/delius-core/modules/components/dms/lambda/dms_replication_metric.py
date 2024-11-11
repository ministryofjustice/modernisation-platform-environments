import boto3
import json
import logging

logger = logging.getLogger()
logger.setLevel(logging.INFO)

def lambda_handler(event, context):

    cloudwatch = boto3.client('cloudwatch')
    for record in event['Records']:

        message = json.loads(record['Sns']['Message'])

        event_type = message.get("EventType")
        status = message.get("status")

        logger.info("SNS Message: %s",message)

        if event_type == "replication-task-state-change" and status == "STARTED":
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
        elif event_type == "failure":
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