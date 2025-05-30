import boto3
import os

def lambda_handler(event, context):
    print("Lambda execution started")

    client = boto3.client('dms')
    sns = boto3.client('sns')
    topic_arn = os.environ['SNS_TOPIC_ARN']

    try:
        response = client.describe_replication_tasks()
        print("Successfully called describe_replication_tasks")
    except Exception as e:
        print(f"Error calling describe_replication_tasks: {e}")
        raise

    tasks = response.get('ReplicationTasks', [])
    print(f"Found {len(tasks)} replication task(s)")

    # Initialize list of non-running replication tasks
    non_running = []

    for task in tasks:
        task_id = task['ReplicationTaskIdentifier']
        status = task['Status']
        print(f"Task '{task_id}' status: {status}")

        if status.lower() != 'running':
            non_running.append(f"{task_id} is {status}")

    if non_running:
        message = "⚠️ DMS Replication Tasks not running:\n" + "\n".join(non_running)
        print("Non-running tasks detected:")
        print(message)

        try:
            sns.publish(
                TopicArn=topic_arn,
                Subject="DMS Alert",
                Message=message
            )
            print("Alert published to SNS")
        except Exception as e:
            print(f"Error publishing to SNS: {e}")
            raise
    else:
        print("All DMS tasks are running")

    print("Lambda execution finished")
