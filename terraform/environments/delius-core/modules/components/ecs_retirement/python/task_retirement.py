import json
import logging
import os
import boto3
from botocore.exceptions import ClientError
from datetime import datetime
import urllib.request

# Setting up logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

def get_slack_token(parameter_name: str) -> str:
    ssm_client = boto3.client('ssm')

    try:
        response = ssm_client.get_parameter(
            Name=parameter_name,
            WithDecryption=True
        )
        return response['Parameter']['Value']

    except ClientError as e:
        raise Exception(f"Error retrieving parameter {parameter_name}: {e}")

def retirement_date(raw_date):
    return datetime.strptime(raw_date, '%a, %d %b %Y %H:%M:%S %Z').strftime('%Y-%m-%d')


def standalone_task_message(resources, env, event):
    '''
    This logic will parse the standalone task event message
    '''

    task_list = ''
    for task in resources:
        task_list += ('\n' + str(task))

    message = str(
        'AWS Fargate tasks will be retired on *' + retirement_date(event['detail']['startTime']) + '*.' +
        '\nThese are standalone tasks, therefore action maybe required to replace them after this date.' +
        '\n\n*Environment:* ' + env +
        '\n\n*Task IDs:* ' + task_list +
        '\n\n<https://phd.aws.amazon.com/phd/home?region=us-east-1#/event-log?eventID=' +
        event['detail']['eventArn'] +
        '|Click here> for details.'
    )
    logging.info(json.dumps(message))

    return message


def service_message(resources, env, event):
    '''
    This logic will parse the service task event message
    '''

    service_list = ''
    for service in resources:
        service_split = service.split('|')
        service_list += ('\nCluster: _' +
                         service_split[0].rstrip() + '_ Service: _' + service_split[1].lstrip() + '_')

    message = str(
        'AWS Fargate tasks will be retired on *' + retirement_date(event['detail']['startTime']) + '*.' +
        '\nThere are ' + str(len(resources)) + ' ECS services affected. ECS will attempt to start replacement tasks after this date.' +
        '\n\n*Environment:* ' + env +
        '\n\n*Services:* ' + service_list +
        '\n\n<https://phd.aws.amazon.com/phd/home?region=us-east-1#/event-log?eventID=' +
        event['detail']['eventArn'] +
        '|Click here> for details.'
    )
    logging.info(json.dumps(message))

    return message


def lambda_handler(event, context):
    logging.info(json.dumps(event))

    # Check that the required environment variables for Slack have been set. If
    # they have not, then raise an exception.
    required_vars = [
        'SLACK_TOKEN',
        'SLACK_CHANNEL'
    ]
    for var in required_vars:
        if not os.environ[var]:
            raise 'Environment variable ' + var + ' not set'

    env = os.environ['ENVIRONMENT']
    slack_token = get_slack_token(os.environ['SLACK_TOKEN'])
    slack_channel = os.environ['SLACK_CHANNEL']

    # Depending on if this task retirement notification is for ECS Services or a
    # Standalone Tasks. We will generate a slack message accordingly.
    resources = event['resources']
    if ':' in resources[0]:
        message = standalone_task_message(resources, env, event)
    elif '|' in resources[0]:
        message = service_message(resources, env, event)
    else:
        raise 'Unable to parse affected tasks'

    slack_url = 'https://slack.com/api/chat.postMessage'
    headers = {
        'Content-Type': 'application/json',
        'Authorization': f'Bearer {slack_token}'
    }

    payload = json.dumps({
        'channel': slack_channel,
        'text': message,
        'username': 'AWS Fargate Task Retirement',
        'icon_emoji': ':warning:'
    }).encode('utf-8')

    req = urllib.request.Request(slack_url, data=payload, headers=headers)

    try:
        with urllib.request.urlopen(req) as resp:
            resp_data = json.loads(resp.read())
            if not resp_data.get('ok'):
                raise Exception(f"Slack API returned an error: {resp_data}")
            logger.info(f"Message posted to: {slack_channel}")
    except Exception as e:
        logger.error(f"Failed to send message to Slack: {e}")
        raise