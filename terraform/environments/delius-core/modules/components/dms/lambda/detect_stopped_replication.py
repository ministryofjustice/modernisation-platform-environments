import boto3

def lambda_handler(event, context):
    dms = boto3.client('dms')
    cw = boto3.client('cloudwatch')

    tasks = dms.describe_replication_tasks().get('ReplicationTasks', [])
    non_running_tasks = [t['ReplicationTaskIdentifier']
                         for t in tasks if t['Status'].lower() != 'running']

    if non_running_tasks:
        print("Non-running tasks:", non_running_tasks)
        # Publish custom metric with value 1
        cw.put_metric_data(
            Namespace='Custom/DMS',
            MetricData=[{
                'MetricName': 'DMSTaskNotRunning',
                'Value': 1,
                'Unit': 'Count'
            }]
        )
    else:
        print("All tasks running. Reporting 0.")
        cw.put_metric_data(
            Namespace='Custom/DMS',
            MetricData=[{
                'MetricName': 'DMSTaskNotRunning',
                'Value': 0,
                'Unit': 'Count'
            }]
        )
