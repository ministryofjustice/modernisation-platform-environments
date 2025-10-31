import os
import boto3
import json
import time
from datetime import datetime
from botocore.exceptions import ClientError

def handler(event, context):
    todays_date = datetime.now().strftime('%Y-%m-%d')

    log_group_name = os.environ['LOG_GROUP_NAME']
    log_stream_name = todays_date
    logs = boto3.client('logs')

    message = event['Records'][0]['Sns']['Message']
    message_dict = json.loads(message)
    
    try:
        logs.create_log_stream(
            logGroupName=log_group_name,
            logStreamName=log_stream_name
        )
    except ClientError as e:
        if e.response['Error']['Code'] == 'ResourceAlreadyExistsException':
            pass
        else:
            raise e

    logs.put_log_events(
        logGroupName=log_group_name,
        logStreamName=log_stream_name,
        logEvents=[
            {
                'timestamp': int(time.time() * 1000),
                'message': json.dumps(message_dict)
            },
        ],
    )