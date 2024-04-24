import os
import boto3
import json
import time

def handler(event, context):
    log_group_name = os.environ['LOG_GROUP_NAME']
    logs = boto3.client('logs')

    message = event['Records'][0]['Sns']['Message']
    message_dict = json.loads(message)

    logs.put_log_events(
        logGroupName=log_group_name,
        logStreamName='sns',
        logEvents=[
            {
                'timestamp': int(time.time() * 1000),
                'message': json.dumps(message_dict)
            },
        ],
    )