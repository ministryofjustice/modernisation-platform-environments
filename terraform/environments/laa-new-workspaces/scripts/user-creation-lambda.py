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
    service_account_secret_arn = os.environ.get('LAMBDA_SERVICE_ACCOUNT_SECRET_ARN', '')

    firstname = event['Firstname']
    lastname = event['Lastname']
    email = event['Email']

    powershell_command = f"powershell.exe -File 'C:\\Windows\\system32\\user-creation.ps1' -Firstname '{firstname}' -Lastname '{lastname}' -Email '{email}' -ServiceAccountSecretArn '{service_account_secret_arn}' -Region '{region}'"

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

    # Extract password from PS1 stdout — line reads "Password: <value>"
    stdout = result.get('StandardOutputContent', '')
    password = None
    for line in stdout.splitlines():
        if line.startswith('Password:'):
            password = line.split(':', 1)[1].strip()
            break

    print(f"PowerShell script completed successfully. Waiting 30 seconds for AD replication...")
    time.sleep(30)
    return password


def get_registration_code(directory_id, region):
    workspaces = boto3.client('workspaces', region_name=region)
    response = workspaces.describe_workspace_directories(DirectoryIds=[directory_id])
    return response['Directories'][0]['RegistrationCode']


def send_credentials_email(username, password, email, region, registration_code):
    ses = boto3.client('ses', region_name=region)
    selfservice_url = os.environ['SELFSERVICE_URL']
    client_download_url = 'https://clients.amazonworkspaces.com/'
    support_email = 'laa_ops@digital.justice.gov.uk'

    web_access_url = 'https://clients.amazonworkspaces.com/webclient'

    text_body = (
        f"Your LAA WorkSpaces account has been created.\n\n"
        f"USERNAME: {username}\n"
        f"TEMPORARY PASSWORD: {password}\n"
        f"REGISTRATION CODE: {registration_code}\n\n"
        f"IMPORTANT: You must complete Step 1 (OTP setup) before you can log in to WorkSpaces.\n\n"
        f"--- STEP 1: SET UP MULTI-FACTOR AUTHENTICATION (OTP) ---\n"
        f"1. Go to: {selfservice_url}\n"
        f"2. Log in with your username and temporary password\n"
        f"3. Click 'Enroll Token'\n"
        f"4. Scan the QR code with Microsoft Authenticator or Google Authenticator\n"
        f"5. Enter the 6-digit code shown in the app to verify\n\n"
        f"--- STEP 2: LOG IN TO WORKSPACES ---\n"
        f"1. Go to: {web_access_url}\n"
        f"2. Enter registration code: {registration_code}\n"
        f"3. Sign in with your username and temporary password\n"
        f"4. Enter your OTP code when prompted\n"
        f"5. You will be prompted to set a new password when your WorkSpace loads\n\n"
        f"For support contact: {support_email}"
    )

    html_body = f"""
    <html><body style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
    <h2 style="color: #1d70b8;">Your LAA WorkSpaces Account</h2>

    <h3>Login Details</h3>
    <table style="border-collapse: collapse; width: 100%;">
      <tr><td style="padding: 8px; font-weight: bold;">Username</td>
          <td style="padding: 8px;">{username}</td></tr>
      <tr style="background-color: #f3f2f1;">
          <td style="padding: 8px; font-weight: bold;">Temporary Password</td>
          <td style="padding: 8px; font-family: monospace;">{password}</td></tr>
      <tr><td style="padding: 8px; font-weight: bold;">Registration Code</td>
          <td style="padding: 8px; font-family: monospace;">{registration_code}</td></tr>
    </table>
    <p style="color: #d4351c; background-color: #fff4f4; padding: 12px; border-left: 4px solid #d4351c;">
      <strong>Important:</strong> You must complete Step 1 (OTP setup) before you can log in to WorkSpaces.
    </p>

    <h3>Step 1 — Set Up Multi-Factor Authentication (OTP) first</h3>
    <ol>
      <li>Go to the MFA self-service portal: <a href="{selfservice_url}">{selfservice_url}</a></li>
      <li>Log in with your username and temporary password</li>
      <li>Click <strong>Enroll Token</strong></li>
      <li>Scan the QR code with <strong>Microsoft Authenticator</strong> or <strong>Google Authenticator</strong></li>
      <li>Enter the 6-digit code shown in the app to verify enrolment</li>
    </ol>

    <h3>Step 2 — Log In to WorkSpaces</h3>
    <ol>
      <li>Go to AWS WorkSpaces Web Access: <a href="{web_access_url}">{web_access_url}</a></li>
      <li>Enter your registration code: <strong style="font-family: monospace;">{registration_code}</strong></li>
      <li>Sign in with your username and temporary password</li>
      <li>Enter your OTP code from the authenticator app when prompted</li>
      <li>You will be asked to set a new password when your WorkSpace loads</li>
    </ol>

    <hr style="margin: 24px 0;">
    <p style="color: #505a5f; font-size: 14px;">
      For support contact <a href="mailto:{support_email}">{support_email}</a>
    </p>
    </body></html>
    """

    ses.send_email(
        Source=os.environ['SES_SENDER'],
        Destination={'ToAddresses': [email]},
        Message={
            'Subject': {'Data': 'Your LAA WorkSpaces account has been created'},
            'Body': {
                'Text': {'Data': text_body},
                'Html': {'Data': html_body}
            }
        }
    )
    print(f"Sent credentials email to {email}")

def create_workspace(event):
    """
    Create a WorkSpace for the user
    """
    region = os.environ['REGION']
    directory_id = os.environ['DIRECTORY_ID']
    kms_key_id = os.environ['KMS_KEY_ID']

    workspace_type = event.get('WorkspaceType', 'standard').lower()
    bundle_map = {
        'standard':    os.environ['BUNDLE_ID_STANDARD'],
        'performance': os.environ['BUNDLE_ID_PERFORMANCE'],
        'power':       os.environ['BUNDLE_ID_POWER']
    }
    bundle_id = bundle_map.get(workspace_type, os.environ['BUNDLE_ID_STANDARD'])
    print(f"Using workspace type: {workspace_type} (bundle: {bundle_id})")

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
        firstname = event['Firstname']
        lastname = event['Lastname']
        email = event['Email']
        username = f"{firstname}.{lastname}"

        password = create_ad_user(event)

        if password:
            registration_code = get_registration_code(os.environ['DIRECTORY_ID'], os.environ['REGION'])
            send_credentials_email(username, password, email, os.environ['REGION'], registration_code)
        else:
            print(f"No password extracted from PS1 output — user may already exist, skipping email")

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
        
        return {
            'statusCode': 200,
            'body': json.dumps(f'Lambda ran Successfully! Workspace created for user: {username}. Check the AWS Console for the workspace status.')
        }
    except Exception as e:
        return {
            'statusCode': 500,
            'body': json.dumps(f'Lambda and workspace creation failed with error: {str(e)}')
        }
