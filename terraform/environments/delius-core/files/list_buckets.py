import boto3
import json

def lambda_handler(event, context):
    # Define the accounts you want to access
    target_accounts = ['673591086753']
    bucket_list = []

    # Assume role in each account and list S3 buckets
    sts_client = boto3.client('sts')

    for account in target_accounts:
        # Assume the cross-account role
        assumed_role = sts_client.assume_role(
            RoleArn=f"arn:aws:iam::{account}:role/test-dms-s3-lister-role",
            RoleSessionName="crossAccountS3AccessSession"
        )
        
        # Use temporary credentials to access S3
        credentials = assumed_role['Credentials']
        s3_client = boto3.client(
            's3',
            aws_access_key_id=credentials['AccessKeyId'],
            aws_secret_access_key=credentials['SecretAccessKey'],
            aws_session_token=credentials['SessionToken']
        )

        # List buckets in the assumed role's account
        response = s3_client.list_buckets()
        for bucket in response['Buckets']:
            bucket_list.append({'AccountId': account, 'BucketName': bucket['Name']})

    return {
        'statusCode': 200,
        'body': json.dumps(bucket_list)
    }