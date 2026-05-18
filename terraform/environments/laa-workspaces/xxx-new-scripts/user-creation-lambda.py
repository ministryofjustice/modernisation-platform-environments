import json
import boto3
import time
import os

def create_ad_user(event):
    """
    Create a user in Active Directory via PowerShell script on EC2
    """
    # The EC2 instance hosting the AD
    instance_id = os.environ['EC2_INSTANCE_ID']
    region = os.environ['REGION']
    
    # Variables to pass to the PowerShell script
    firstname = event['Firstname']
    lastname = event['Lastname']
    email = event['Email']
    
    # Construct the PowerShell script command with variables
    powershell_command = f"powershell.exe -File 'C:\\Windows\\system32\\user-creation.ps1' -Firstname '{firstname}' -Lastname '{lastname}' -Email '{email}'"
    
    # Execute the PowerShell script on the EC2 instance
    ssm_client = boto3.client('ssm', region_name=region)
    response = ssm_client.send_command(
        InstanceIds=[instance_id],
        DocumentName='AWS-RunPowerShellScript',
        Parameters={'commands': [powershell_command]}
    )
    
    # Retrieve the command invocation ID
    command_id = response['Command']['CommandId']
    print(f"Command ID: {command_id}")
    
    # Wait for AD user creation to complete (allow time for PowerShell script execution and AD replication)
    # PowerShell New-ADUser takes ~70 seconds, plus AD replication time
    print("Waiting 90 seconds for AD user creation and replication...")
    time.sleep(90)

def create_workspace(event):
    """
    Create a WorkSpace for the user
    """
    # Get configuration from environment variables
    region = os.environ['REGION']
    directory_id = os.environ['DIRECTORY_ID']
    bundle_id = os.environ['WORKSPACE_BUNDLE_ID']
    # kms_key_id = os.environ['KMS_KEY_ID']  # Temporarily disabled for testing
    
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
                    # Temporarily disable encryption to test user creation
                    # 'UserVolumeEncryptionEnabled': True,
                    # 'RootVolumeEncryptionEnabled': True,
                    # 'VolumeEncryptionKey': kms_key_id,
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
        
        print(response)
        
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
        create_workspace(event)
        
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
