import boto3
import botocore.exceptions
import os


grafana_client = boto3.client('grafana')
secretsmanager_client = boto3.client('secretsmanager')
workspace_api_key_name = os.environ['WORKSPACE_API_KEY_NAME']
workspace_api_key_ttl = os.environ.get('WORKSPACE_API_KEY_TTL') or 1209600 # 1209600 is 14 days
workspace_id = os.environ['WORKSPACE_ID']
secret_id = os.environ['SECRET_ID']


def lambda_handler(event, context):
    try:
        delete_workspace_api_key = grafana_client.delete_workspace_api_key(
            keyName=workspace_api_key_name,
            workspaceId=workspace_id
        )
    except botocore.exceptions.ClientError as e:
        if e.response['Error']['Code'] == 'ResourceNotFoundException':
            pass
        else:
            print(e)
            return {
                'statusCode': 500,
                'body': 'Failed to delete Grafana API key'
            }

    try:
        create_workspace_api_key = grafana_client.create_workspace_api_key(
            keyName=workspace_api_key_name,
            keyRole='ADMIN',
            secondsToLive=workspace_api_key_ttl,
            workspaceId=workspace_id
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
            SecretId=secret_id,
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
