import json
import boto3
import time
import os

def create_ad_user(event):
    """
    Create a user in Active Directory via PowerShell script on EC2
    """
    instance_id = os.environ['EC2_INSTANCE_ID']
    region = os.environ['REGION']
    
    firstname = event['Firstname']
    lastname = event['Lastname']
    email = event['Email']
    
    print(f"Creating AD user: {firstname}.{lastname}")
    
    # Construct PowerShell command
    powershell_command = f"powershell.exe -File 'C:\\Windows\\system32\\user-creation.ps1' -Firstname '{firstname}' -Lastname '{lastname}' -Email '{email}'"
    
    # Execute PowerShell script on EC2 via SSM
    ssm_client = boto3.client('ssm', region_name=region)
    
    try:
        response = ssm_client.send_command(
            InstanceIds=[instance_id],
            DocumentName='AWS-RunPowerShellScript',
            Parameters={'commands': [powershell_command]},
            TimeoutSeconds=300
        )
        
        command_id = response['Command']['CommandId']
        print(f"SSM Command ID: {command_id}")
        
        # Wait for command to complete
        max_attempts = 30
        attempt = 0
        
        while attempt < max_attempts:
            time.sleep(3)
            attempt += 1
            
            try:
                result = ssm_client.get_command_invocation(
                    CommandId=command_id,
                    InstanceId=instance_id
                )
                
                status = result['Status']
                print(f"Command status (attempt {attempt}): {status}")
                
                if status == 'Success':
                    print("AD user created successfully")
                    print(f"Command output: {result.get('StandardOutputContent', '')}")
                    return True
                elif status in ['Failed', 'Cancelled', 'TimedOut']:
                    error_msg = result.get('StandardErrorContent', 'Unknown error')
                    print(f"Command failed: {error_msg}")
                    raise Exception(f"Failed to create AD user: {error_msg}")
                
            except ssm_client.exceptions.InvocationDoesNotExist:
                print(f"Waiting for command to start... (attempt {attempt})")
                continue
        
        raise Exception("Timeout waiting for AD user creation")
        
    except Exception as e:
        print(f"Error creating AD user: {str(e)}")
        raise

def create_workspace(event):
    """
    Create a WorkSpace for the user
    """
    region = os.environ['REGION']
    directory_id = os.environ['DIRECTORY_ID']
    bundle_id = os.environ['WORKSPACE_BUNDLE_ID']
    kms_key_id = os.environ['KMS_KEY_ID']
    
    firstname = event['Firstname']
    lastname = event['Lastname']
    email = event['Email']
    username = f"{firstname}.{lastname}"
    
    print(f"Creating WorkSpace for user: {username}")
    
    workspaces_client = boto3.client('workspaces', region_name=region)
    
    try:
        response = workspaces_client.create_workspaces(
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
                        {'Key': 'infrastructure-support', 'Value': 'laa_ops@digital.justice.gov.uk'},
                        {'Key': 'User', 'Value': username},
                        {'Key': 'Email', 'Value': email},
                        {'Key': 'FirstName', 'Value': firstname},
                        {'Key': 'LastName', 'Value': lastname},
                        {'Key': 'CreatedBy', 'Value': 'Lambda'}
                    ]
                }
            ]
        )
        
        print(f"WorkSpace creation response: {json.dumps(response, default=str)}")
        
        # Check for failures
        if 'FailedRequests' in response and response['FailedRequests']:
            for failed_request in response['FailedRequests']:
                error_message = f"Failed to create workspace for user: {failed_request['WorkspaceRequest']['UserName']}. Error: {failed_request['ErrorMessage']}"
                print(error_message)
                raise Exception(error_message)
        
        # Get workspace ID from successful response
        if 'PendingRequests' in response and response['PendingRequests']:
            workspace_id = response['PendingRequests'][0].get('WorkspaceId', 'pending')
            print(f"WorkSpace created successfully. ID: {workspace_id}")
            return workspace_id
        
        print("WorkSpace creation initiated successfully")
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
        # Validate input
        required_fields = ['Firstname', 'Lastname', 'Email']
        for field in required_fields:
            if field not in event:
                raise Exception(f"Missing required field: {field}")
        
        firstname = event['Firstname']
        lastname = event['Lastname']
        username = f"{firstname}.{lastname}"
        
        # Step 1: Create AD user via PowerShell on EC2
        print("Step 1: Creating AD user...")
        create_ad_user(event)
        
        # Step 2: Wait for AD propagation
        print("Waiting 10 seconds for AD propagation...")
        time.sleep(10)
        
        # Step 3: Create WorkSpace
        print("Step 2: Creating WorkSpace...")
        workspace_id = create_workspace(event)
        
        success_message = f"User creation completed successfully! Username: {username}, WorkSpace: {workspace_id}. Check AWS Console for workspace status and use 'Invite user' button to send credentials."
        
        print(success_message)
        
        return {
            'statusCode': 200,
            'body': json.dumps({
                'message': success_message,
                'username': username,
                'workspace_id': workspace_id,
                'email': event['Email']
            })
        }
        
    except Exception as e:
        error_message = f"Lambda execution failed: {str(e)}"
        print(error_message)
        
        return {
            'statusCode': 500,
            'body': json.dumps({
                'error': error_message
            })
        }
