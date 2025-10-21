import json
import logging
import os
import boto3
from botocore.exceptions import ClientError
from datetime import datetime
from collections import defaultdict
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


def service_message_markup(resources, env, event):
    '''
    This logic will parse the service task event message
    '''

    def detect_environment_from_cluster(cluster_name):
        cluster_name = cluster_name.lower()
        if "prod" in cluster_name:
            return "prod"
        elif "preprod" in cluster_name:
            return "preprod"
        elif "stage" in cluster_name:
            return "stage"
        elif "dev" in cluster_name:
            return "dev"
        elif "poc" in cluster_name:
            return "poc"
        elif "training" in cluster_name:
            return "training"
        else:
            return "unknown"


    # Color & emoji mappings
    env_colors = {
        "prod": "#E01E5A",       # red
        "preprod": "#E01E5A",    # red
        "stage": "#ECB22E",      # yellow
        "dev": "#2EB67D",        # green
        "poc": "#36C5F0",        # blue
        "training": "#F0AC36",   # orange
        "unknown": "#AAAAAA"
    }

    env_labels = {
        "prod": "🔴 *PROD*",
        "preprod": "🔴 *PREPROD*",
        "stage": "🟡 *STAGE*",
        "dev": "🟢 *DEV*",
        "poc": "🔵 *POC*",
        "training": "🟠 *TRAINING*",
        "unknown": "*UNKNOWN*"
    }

    # Group services by environment
    env_groups = defaultdict(list)
    for service in resources:
        cluster_name, svc_name = service.split("|")
        env_name = detect_environment_from_cluster(cluster_name)
        env_groups[env_name].append((cluster_name.strip(), svc_name.strip()))

    attachments = []

    for env_name, services in env_groups.items():
        service_list = ""
        for cluster, svc in services:
            service_list += f"• Cluster: _{cluster}_    |   Service: _{svc}_\n"
        service_list = service_list.rstrip("\n")

        blocks = [
            {
                "type": "section",
                "text": {
                    "type": "mrkdwn",
                    "text": f"🚨 *AWS Fargate service tasks will be retired on* `{retirement_date(event['detail']['startTime'])}`"
                }
            },
            {
                "type": "section",
                "text": {
                    "type": "mrkdwn",
                    "text": f"*Environment:* {env_labels.get(env_name, env_name.upper())}"
                }
            },
            {
                "type": "section",
                "text": {
                    "type": "mrkdwn",
                    "text": f"There are *{len(services)} ECS services* affected. ECS will attempt to start replacement tasks after this date."
                }
            },
            {
                "type": "section",
                "text": {
                    "type": "mrkdwn",
                    "text": f"*Services:*\n{service_list}"
                }
            },
            {
                "type": "actions",
                "elements": [
                    {
                        "type": "button",
                        "text": {"type": "plain_text", "text": "Click here for details"},
                        "url": f"https://phd.aws.amazon.com/phd/home?region=us-east-1#/event-log?eventID={event['detail']['eventArn']}"
                    }
                ]
            }
        ]

        attachments.append({
            "color": env_colors.get(env_name, "#AAAAAA"),
            "blocks": blocks
        })

    return {"attachments": attachments}


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
        message = service_message_markup(resources, env, event)
    else:
        raise 'Unable to parse affected tasks'

    slack_url = 'https://slack.com/api/chat.postMessage'
    headers = {
        'Content-Type': 'application/json',
        'Authorization': f'Bearer {slack_token}'
    }

    payload = json.dumps({
        'channel': slack_channel,
        'username': 'AWS Fargate Task Retirement',
        'icon_emoji': ':warning:',
        # "attachments": message["attachments"],
        **message
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