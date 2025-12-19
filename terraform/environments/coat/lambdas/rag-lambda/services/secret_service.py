import boto3
import json

class SecretService:
    def __init__(self) -> None:
        self.client = boto3.client("secretsmanager")

    def get_secret(self, secret_name):

        response = self.client.get_secret_value(SecretId=secret_name)

        secret = response.get("SecretString", "")
        
        return secret