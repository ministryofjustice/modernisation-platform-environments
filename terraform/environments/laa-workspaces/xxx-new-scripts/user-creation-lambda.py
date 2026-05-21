import json
import boto3
import time
import os

def wait_for_ssm_command(ssm_client, command_id, instance_id, max_wait=300):
    """Poll SSM command status until it reaches a terminal state."""
    terminal_statuses = {'Success', 'Failed', 'TimedOut', 'Cancelled', 'DeliveryTimedOut'}
    elapsed = 0
    poll_interval = 10

    while elapsed < max_wait:
        try:
            result = ssm_client.get_command_invocation(
                CommandId=command_id,
                InstanceId=instance_id
            )
            status = result['Status']
            print(f"SSM command status: {status} ({elapsed}s elapsed)")
            if status in terminal_statuses:
                return status, result
        except ssm_client.exceptions.InvocationDoesNotExist:
            print("SSM invocation not yet registered, retrying...")

        time.sleep(poll_interval)
        elapsed += poll_interval

    return 'TimedOut', {}


def create_ad_user(event):
    """
    Create a user in Active Directory via PowerShell script on EC2
    """
    instance_id = os.environ['EC2_INSTANCE_ID']
    region = os.environ['REGION']

    firstname = event['Firstname']
    lastname = event['Lastname']
    email = event['Email']

    powershell_command = f"powershell.exe -File 'C:\\Windows\\system32\\user-creation.ps1' -Firstname '{firstname}' -Lastname '{lastname}' -Email '{email}'"

    ssm_client = boto3.client('ssm', region_name=region)
    response = ssm_client.send_command(
        InstanceIds=[instance_id],
        DocumentName='AWS-RunPowerShellScript',
        Parameters={'commands': [powershell_command]}
    )

    command_id = response['Command']['CommandId']
    print(f"Command ID: {command_id}")

    status, result = wait_for_ssm_command(ssm_client, command_id, instance_id)

    if status != 'Success':
        output = result.get('StandardErrorContent', '') or result.get('StandardOutputContent', '')
        raise Exception(f"PowerShell script failed with status '{status}': {output}")

    print(f"PowerShell script completed successfully. Waiting 30 seconds for AD replication...")
    time.sleep(30)

def create_workspace(event):
    """
    Create a WorkSpace for the user
    """
    # Get configuration from environment variables
    region = os.environ['REGION']
    directory_id = os.environ['DIRECTORY_ID']
    bundle_id = os.environ['WORKSPACE_BUNDLE_ID']
    kms_key_id = os.environ['KMS_KEY_ID']
    
    firstname = event['Firstname']
    lastname = event['Lastname']
    Username = f"{firstname}.{lastname}"
    
    workspaces = boto3.client('workspaces', region_name=region)
    
    try:
        response = workspaces.create_workspaces(
            Workspaces=[
                {
                    'DirectoryId': directory_id,
                    'UserName': Username,
                    'BundleId': bundle_id,
                    'UserVolumeEncryptionEnabled': True,
                    'RootVolumeEncryptionEnabled': True,
                    'VolumeEncryptionKey': kms_key_id,
                    'WorkspaceProperties': {
                        'RunningMode': 'AUTO_STOP',
                        'RunningModeAutoStopTimeoutInMinutes': 60
                    },
                    'Tags': [
                        {
                            'Key': 'application',
                            'Value': 'laa-workspaces'
                        },
                        {
                            'Key': 'business-unit',
                            'Value': 'LAA'
                        },
                        {
                            'Key': 'infrastructure-support',
                            'Value': 'laa_ops@digital.justice.gov.uk'
                        }
                    ]
                }
            ]
        )
        
        if 'FailedRequests' in response:
            for failed_request in response['FailedRequests']:
                error_message = f"Failed to create workspace for user: {failed_request['WorkspaceRequest']['UserName']}. Error: {failed_request['ErrorMessage']}"
                print(error_message)
                raise Exception(error_message)
        
        # Get workspace ID from successful response
        if 'PendingRequests' in response and response['PendingRequests']:
            workspace_id = response['PendingRequests'][0].get('WorkspaceId', 'pending')
            return workspace_id
        
        return "created"
        
    except Exception as e:
        error_message = f"Failed to create workspace: {str(e)}"
        print(error_message)
        raise Exception(error_message)

def lambda_handler(event, context):
    """
    Lambda handler - creates AD user and WorkSpace
    """
    print(f"Received event: {json.dumps(event)}")

    try:
        create_ad_user(event)

        # Retry workspace creation in case AD replication hasn't fully propagated
        last_error = None
        for attempt in range(1, 4):
            try:
                create_workspace(event)
                break
            except Exception as e:
                if 'ResourceNotFound.User' in str(e) and attempt < 3:
                    print(f"User not yet visible in directory (attempt {attempt}/3), waiting 30s...")
                    time.sleep(30)
                    last_error = e
                else:
                    raise
        else:
            raise last_error
        
        firstname = event['Firstname']
        lastname = event['Lastname']
        Username = f"{firstname}.{lastname}"
        
        return {
            'statusCode': 200,
            'body': json.dumps(f'Lambda ran Successfully! Workspace created for user: {Username}. Check the AWS Console for the workspace status.')
        }
    except Exception as e:
        return {
            'statusCode': 500,
            'body': json.dumps(f'Lambda and workspace creation failed with error: {str(e)}')
        }
