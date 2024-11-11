import boto3
import json

def lambda_handler(event, context):

    cloudwatch = boto3.client('cloudwatch')
    for record in event['Records']:

        message = json.loads(record['Sns']['Message'])

        if message.get("EventType") == "replication-task-state-change" and message.get("status") == "STARTED":
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
        elif message.get("EventType") == "failure":
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