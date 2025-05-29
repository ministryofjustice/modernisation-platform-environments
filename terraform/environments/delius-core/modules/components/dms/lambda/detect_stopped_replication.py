import boto3
import os

def lambda_handler(event, context):
    client = boto3.client('dms')
    sns = boto3.client('sns')
    topic_arn = os.environ['SNS_TOPIC_ARN']

    response = client.describe_replication_tasks()
    tasks = response.get('ReplicationTasks', [])
    non_running = []

    for task in tasks:
        task_id = task['ReplicationTaskIdentifier']
        status = task['Status']
        if status.lower() != 'running':
            non_running.append(f"{task_id} is {status}")

    if non_running:
        message = "⚠️ DMS Replication Tasks not running:\n" + "\n".join(non_running)
        sns.publish(TopicArn=topic_arn, Subject="DMS Alert", Message=message)
