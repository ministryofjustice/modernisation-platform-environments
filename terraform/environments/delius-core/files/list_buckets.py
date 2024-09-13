import json
import boto3
from botocore.exceptions import ClientError

def lambda_handler(event, context):
    # Retrieve the target_account_id from query string parameters
    target_account_id = event.get('queryStringParameters', {}).get('target_account_id')
    
    if not target_account_id:
        # Return an error response if target_account_id is not provided
        return {
            'statusCode': 400,
            'body': json.dumps({'error': 'target_account_id is required as a query parameter'})
        }

    # Initialize an empty list to store the bucket names
    bucket_list = []
    
    # Initialize the STS client for assuming roles
    sts_client = boto3.client('sts')

    try:
        # Assume the cross-account role
        assumed_role = sts_client.assume_role(
            RoleArn=f"arn:aws:iam::{target_account_id}:role/cross-account-s3-read-only-role",
            RoleSessionName="CrossAccountS3AccessSession"
        )
        
        # Extract the temporary credentials from the assumed role
        credentials = assumed_role['Credentials']
        
        # Initialize the S3 client using the assumed role's credentials
        s3_client = boto3.client(
            's3',
            aws_access_key_id=credentials['AccessKeyId'],
            aws_secret_access_key=credentials['SecretAccessKey'],
            aws_session_token=credentials['SessionToken']
        )
        
        # List buckets in the target account
        response = s3_client.list_buckets()
        bucket_list = [bucket['Name'] for bucket in response['Buckets']]
    
    except ClientError as e:
        # Handle errors and return the error message in the response
        return {
            'statusCode': 500,
            'body': json.dumps({'error': str(e), 'AccountId': target_account_id})
        }

    # Return the list of buckets in the target account
    return {
        'statusCode': 200,
        'body': json.dumps({'AccountId': target_account_id, 'Buckets': bucket_list})
    }
