import json
import boto3
from botocore.exceptions import ClientError

def lambda_handler(event, context):
    # Retrieve the target_account_id from query string parameters
    target_account_id = event.get('queryStringParameters', {}).get('target_account_id')
    target_environment_name = event.get('queryStringParameters', {}).get('target_environment_name')

    if not target_account_id or not target_environment_name:
        # Return an error response if target_account_id or target_environment_name is not provided
        return {
            'statusCode': 400,
            'body': json.dumps({'error': 'target_account_id and target_environment_name are required as query parameters'})
        }

    # Initialize an empty list to store the bucket names
    bucket_list = []
    
    # Initialize the STS client for assuming roles
    sts_client = boto3.client('sts')

    try:
        # Assume the cross-account role
        assumed_role = sts_client.assume_role(
            RoleArn=f"arn:aws:iam::{target_account_id}:role/{target_environment_name}-dms-s3-lister-role",
            RoleSessionName="crossAccountS3AccessSession"
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
    
    # Because we cannot guarantee that the repository or client environments exist yet,
    # we do not raise an error if we cannot access the remote account, but instead just
    # return an empty list of buckets.  This is intended to remove a circular 
    # dependency where we cannot create the client environment until the repository
    # environment exists and vice versa.
    except ClientError as e:
        error_code = e.response['Error']['Code']
        if error_code == 'AccessDenied' or error_code == 'NoSuchEntity':
            # Return an empty list of buckets if the role does not exist or access is denied
            return {
                'statusCode': 200,
                'body': json.dumps({'AccountId': target_account_id, 'Buckets': [], 'message': 'Role does not exist or access is denied'})
            }
        else:
            # Handle other errors and return the error message in the response
            return {
                'statusCode': 500,
                'body': json.dumps({'error': str(e), 'AccountId': target_account_id, 'EnvironmentName': target_environment_name})
            }

    # Return the list of buckets in the target account
    return {
        'statusCode': 200,
        'body': json.dumps({'AccountId': target_account_id, 'Buckets': bucket_list})
    }
