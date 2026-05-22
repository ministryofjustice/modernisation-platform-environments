import json
import boto3
import os
import secrets
import string


def generate_password(length=16):
    special = '!@#$%^&*'
    alphabet = string.ascii_letters + string.digits + special
    while True:
        password = ''.join(secrets.choice(alphabet) for _ in range(length))
        if (any(c.islower() for c in password) and
                any(c.isupper() for c in password) and
                any(c.isdigit() for c in password) and
                any(c in special for c in password)):
            return password


def create_ad_user(directory_id, firstname, lastname, email, region):
    username = f"{firstname}.{lastname}"
    ds_data = boto3.client('ds-data', region_name=region)

    # Check if user already exists
    try:
        ds_data.describe_user(
            DirectoryId=directory_id,
            SAMAccountName=username
        )
        print(f"User {username} already exists, skipping AD creation")
        return username, None  # No password — user already exists
    except ds_data.exceptions.ResourceNotFoundException:
        pass

    password = generate_password()

    ds_data.create_user(
        DirectoryId=directory_id,
        SAMAccountName=username,
        GivenName=firstname,
        Surname=lastname,
        EmailAddress=email,
        OtherAttributes={
            'displayName': {'S': f"{firstname} {lastname}"}
        }
    )

    ds_data.reset_user_password(
        DirectoryId=directory_id,
        SAMAccountName=username,
        NewPassword=password
    )

    print(f"Created AD user {username} via DS Data API")
    return username, password


def send_credentials_email(username, password, email, region):
    ses = boto3.client('ses', region_name=region)
    sender = os.environ['SES_SENDER']

    ses.send_email(
        Source=sender,
        Destination={'ToAddresses': [email]},
        Message={
            'Subject': {
                'Data': 'Your LAA WorkSpaces account has been created'
            },
            'Body': {
                'Text': {
                    'Data': (
                        f"Your LAA WorkSpaces account has been created.\n\n"
                        f"Username: {username}\n"
                        f"Temporary password: {password}\n\n"
                        f"Please change your password after your first login.\n\n"
                        f"Download the WorkSpaces client from:\n"
                        f"https://clients.amazonworkspaces.com/\n\n"
                        f"If you have any issues, contact laa_ops@digital.justice.gov.uk"
                    )
                }
            }
        }
    )

    print(f"Sent credentials email to {email} for user {username}")


def create_workspace(directory_id, username, region):
    bundle_id = os.environ['WORKSPACE_BUNDLE_ID']
    kms_key_id = os.environ['KMS_KEY_ID']

    workspaces = boto3.client('workspaces', region_name=region)

    response = workspaces.create_workspaces(
        Workspaces=[
            {
                'DirectoryId': directory_id,
                'UserName': username,
                'BundleId': bundle_id,
                'UserVolumeEncryptionEnabled': True,
                'RootVolumeEncryptionEnabled': True,
                'VolumeEncryptionKey': kms_key_id,
                'WorkspaceProperties': {
                    'RunningMode': 'AUTO_STOP',
                    'RunningModeAutoStopTimeoutInMinutes': 60
                },
                'Tags': [
                    {'Key': 'application', 'Value': 'laa-workspaces'},
                    {'Key': 'business-unit', 'Value': 'LAA'},
                    {'Key': 'infrastructure-support', 'Value': 'laa_ops@digital.justice.gov.uk'}
                ]
            }
        ]
    )

    if response.get('FailedRequests'):
        failed = response['FailedRequests'][0]
        raise Exception(f"WorkSpace creation failed: {failed['ErrorMessage']}")

    if response.get('PendingRequests'):
        workspace_id = response['PendingRequests'][0].get('WorkspaceId')
        print(f"WorkSpace {workspace_id} created for {username} (PENDING)")
        return workspace_id

    return None


def lambda_handler(event, context):
    print(f"Received event: {json.dumps(event)}")

    region = os.environ['REGION']
    directory_id = os.environ['DIRECTORY_ID']

    firstname = event['Firstname']
    lastname = event['Lastname']
    email = event['Email']

    try:
        username, password = create_ad_user(directory_id, firstname, lastname, email, region)

        if password:
            send_credentials_email(username, password, email, region)
        else:
            print(f"User {username} already existed — no email sent")

        # Small replication buffer before workspace creation
        import time
        time.sleep(15)

        workspace_id = create_workspace(directory_id, username, region)

        return {
            'statusCode': 200,
            'body': json.dumps(f'WorkSpace {workspace_id} created for {username}')
        }

    except Exception as e:
        print(f"ERROR: {e}")
        return {
            'statusCode': 500,
            'body': json.dumps(f'Failed: {str(e)}')
        }
