import boto3
import json
import os

lambda_client = boto3.client('lambda')
s3 = boto3.client('s3')
bucket_name = os.get.environ('BUCKET_NAME')
lambda_function_name = os.get.environ('LAMBDA_FUNCTION_NAME')

response = s3.list_objects_v2(Bucket=bucket_name)

for obj in response.get('Contents', []):
    key = obj['Key']
    event = {
        "Records": [
            {
                "s3": {
                    "bucket": {
                        "name": bucket_name,
                    },
                    "object": {
                        "key": key,
                    },
                },
            },
        ]
    }
    lambda_client.invoke(
        FunctionName=lambda_function_name,
        InvocationType='Event',
        Payload=json.dumps(event)
    )