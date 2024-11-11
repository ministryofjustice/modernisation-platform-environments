import boto3

def lambda_handler(event, context):
    cloudwatch = boto3.client('cloudwatch')
    cloudwatch.put_metric_data(
        Namespace='CustomDMSMetrics',
        MetricData=[
            {
                'MetricName': 'DMSReplicationEvent',
                'Dimensions': [
                    {'Name': 'Service', 'Value': 'DMS'}
                ],
                'Value': 1,  # Trigger threshold
                'Unit': 'Count'
            }
        ]
    )