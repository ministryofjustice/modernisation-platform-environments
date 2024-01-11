import boto3
import os


grafana_client = boto3.client('grafana')
secretsmanager_client = boto3.client('secretsmanager')


WORKSPACE_API_KEY_NAME = os.environ['WORKSPACE_API_KEY_NAME']
WORKSPACE_API_KEY_TTL = os.environ('WORKSPACE_API_KEY_TTL', 25920000) # default and max of 30 days
WORKSPACE_ID = os.environ['WORKSPACE_ID']
SECRET_ID = os.environ['SECRET_ID']


def lambda_handler(event, context):
    create_api_key_response = grafana_client.workspace_api_key(
        keyName=WORKSPACE_API_KEY_NAME,
        keyRole='ADMIN',
        secondsToLive=WORKSPACE_API_KEY_TTL,
        workspaceId=WORKSPACE_ID
    )
