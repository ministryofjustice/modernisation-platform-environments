import os
import json
import boto3
from botocore.exceptions import ClientError


secrets_client = boto3.client('secretsmanager')


def get_secret() -> dict:
    secret_name = os.getenv("SECRET_NAME")
    try:
        response = secrets_client.get_secret_value(SecretId=secret_name)
        secret = json.loads(response['SecretString'])
    except ClientError as e:
        raise Exception(f"Failed to retrieve secret: {e}")
    return secret
