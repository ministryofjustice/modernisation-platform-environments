import boto3
from botocore.exceptions import BotoCoreError, ClientError
import os


grafana_client = boto3.client('grafana')
secretsmanager_client = boto3.client('secretsmanager')


WORKSPACE_API_KEY_NAME = os.environ['WORKSPACE_API_KEY_NAME']
WORKSPACE_API_KEY_TTL = 1209600 # 14 days
WORKSPACE_ID = os.environ['WORKSPACE_ID']
SECRET_ID = os.environ['SECRET_ID']


def lambda_handler(event, context):
    try:
        delete_workspace_api_key = grafana_client.delete_workspace_api_key(
            keyName='observability-platform-prometheus',
            workspaceId='g-e937f84aea'
        )
    # except ManagedGrafana.Client.exceptions.ResourceNotFoundException:
    except (BotoCoreError, ClientError):
        pass
    except Exception as e:
        print(e)
        return {
            'statusCode': 500,
            'body': 'Failed to delete Grafana API key'
        }

    try:
        create_workspace_api_key = grafana_client.create_workspace_api_key(
            keyName='observability-platform-prometheus',
            keyRole='ADMIN',
            secondsToLive=WORKSPACE_API_KEY_TTL,
            workspaceId='g-e937f84aea'
        )
    except Exception as e:
        print(e)
        return {
            'statusCode': 500,
            'body': 'Failed to create Grafana API key'
        }

    api_key = create_workspace_api_key['key']

    try: 
        update_secret = secretsmanager_client.update_secret(
            SecretId=SECRET_ID,
            SecretString=api_key
        )

    except Exception as e:
        print(e)
        return {
            'statusCode': 500,
            'body': 'Failed to update AWS Secrets Manager secret'
        }

    else:
        return {
            'statusCode': 200,
            'body': 'Successfully updated AWS Secrets Manager secret'
        }
