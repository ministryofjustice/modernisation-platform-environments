import json
import boto3
import os
import time
from concurrent.futures import ThreadPoolExecutor


def lambda_handler(event, context):
    print(f"Received event: {json.dumps(event)}")

    region = os.environ['REGION']
    secrets_client = boto3.client('secretsmanager', region_name=region)

    secret_arn = event['detail']['requestParameters']['secretId']

    # Retrieve current user list
    current_response = secrets_client.get_secret_value(
        SecretId=secret_arn,
        VersionStage='AWSCURRENT'
    )
    current_data = json.loads(current_response['SecretString'])
    current_users_list = current_data.get('users', [])

    # Detect duplicate usernames
    usernames = [u['username'] for u in current_users_list]
    if len(usernames) != len(set(usernames)):
        raise Exception(f"Duplicate usernames detected in user list: {usernames}")

    current_users = {u['username']: u for u in current_users_list}

    # Retrieve previous user list
    try:
        previous_response = secrets_client.get_secret_value(
            SecretId=secret_arn,
            VersionStage='AWSPREVIOUS'
        )
        previous_data = json.loads(previous_response['SecretString'])
        previous_users = {u['username']: u for u in previous_data.get('users', [])}
    except Exception:
        previous_users = {}

    # Calculate diff
    to_create = [u for username, u in current_users.items() if username not in previous_users]
    to_delete = [u for username, u in previous_users.items() if username not in current_users]
    to_keep = [u for username, u in current_users.items() if username in previous_users]

    # Warn about email-only changes (not actioned)
    for username, user in current_users.items():
        if username in previous_users and user != previous_users[username]:
            print(f"WARNING: Details changed for {username} but update is not supported — delete and recreate manually if needed")

    print(f"Users to create: {[u['username'] for u in to_create]}")
    print(f"Users to delete: {[u['username'] for u in to_delete]}")
    print(f"Users unchanged: {[u['username'] for u in to_keep]}")

    # Mass deletion protection
    if to_delete and len(previous_users) > 0:
        deletion_ratio = len(to_delete) / len(previous_users)
        if deletion_ratio > 0.5 and os.environ.get('ALLOW_MASS_DELETE', 'false').lower() != 'true':
            raise Exception(
                f"Mass deletion protection triggered: {len(to_delete)} of {len(previous_users)} users "
                f"({int(deletion_ratio * 100)}%) would be deleted. "
                f"Set ALLOW_MASS_DELETE=true on the Lambda to override."
            )

    # Dry run
    if os.environ.get('DRY_RUN', 'false').lower() == 'true':
        print(f"DRY RUN: would create {len(to_create)}, delete {len(to_delete)}")
        return {'created': 0, 'deleted': 0, 'failed': 0, 'dry_run': True}

    with ThreadPoolExecutor(max_workers=10) as executor:
        create_futures = {executor.submit(create_user, user, region): user for user in to_create}
        delete_futures = {executor.submit(delete_user, user, region): user for user in to_delete}

    create_results = [f.result() for f in create_futures]
    delete_results = [f.result() for f in delete_futures]

    summary = {
        'created': len([r for r in create_results if r['success']]),
        'deleted': len([r for r in delete_results if r['success']]),
        'failed': len([r for r in create_results + delete_results if not r['success']]),
        'details': create_results + delete_results
    }

    print(f"Summary: created={summary['created']}, deleted={summary['deleted']}, failed={summary['failed']}")

    if summary['failed'] > 0:
        failed = [r for r in create_results + delete_results if not r['success']]
        print(f"Failed operations: {json.dumps(failed)}")

    return summary


def create_user(user, region):
    username = user['username']
    lambda_client = boto3.client('lambda', region_name=region)

    for attempt in range(1, 4):
        try:
            print(f"Creating user {username} (attempt {attempt}/3)...")
            response = lambda_client.invoke(
                FunctionName=os.environ['USER_CREATION_LAMBDA'],
                InvocationType='RequestResponse',
                Payload=json.dumps({
                    'Firstname': user['firstname'],
                    'Lastname': user['lastname'],
                    'Email': user['email']
                })
            )

            payload = json.loads(response['Payload'].read())
            if response['StatusCode'] == 200 and payload.get('statusCode') == 200:
                print(f"Created user {username} successfully")
                return {'success': True, 'action': 'create', 'username': username}

            error = payload.get('body', 'Unknown error')
            raise Exception(error)

        except Exception as e:
            if attempt < 3:
                print(f"Attempt {attempt} failed for {username}: {e}. Retrying in 10s...")
                time.sleep(10)
            else:
                print(f"Failed to create user {username} after 3 attempts: {e}")
                return {'success': False, 'action': 'create', 'username': username, 'error': str(e)}

    return {'success': False, 'action': 'create', 'username': username, 'error': 'Max retries exceeded'}


def delete_user(user, region):
    username = user['username']
    directory_id = os.environ['DIRECTORY_ID']
    errors = []

    # 1. Find and terminate WorkSpace
    try:
        workspaces_client = boto3.client('workspaces', region_name=region)
        response = workspaces_client.describe_workspaces(
            DirectoryId=directory_id,
            UserName=username
        )

        if response['Workspaces']:
            workspace_id = response['Workspaces'][0]['WorkspaceId']
            workspaces_client.terminate_workspaces(
                TerminateWorkspaceRequests=[{'WorkspaceId': workspace_id}]
            )
            print(f"Terminated workspace {workspace_id} for {username}")
        else:
            print(f"No workspace found for {username}, skipping workspace termination")

    except Exception as e:
        errors.append(f"Workspace termination failed: {e}")
        print(f"ERROR: Workspace termination failed for {username}: {e}")

    # 2. Delete AD user via DS Data API
    try:
        ds_data = boto3.client('ds-data', region_name=region)
        ds_data.delete_user(
            DirectoryId=directory_id,
            SAMAccountName=username
        )
        print(f"Deleted AD user {username}")
    except ds_data.exceptions.ResourceNotFoundException:
        print(f"AD user {username} not found in directory, skipping")
    except Exception as e:
        errors.append(f"AD user deletion failed: {e}")
        print(f"ERROR: AD user deletion failed for {username}: {e}")

    # 3. Delete password SSM parameter (may not exist for DS API-created users)
    try:
        ssm_client = boto3.client('ssm', region_name=region)
        param_name = f"/laa-workspaces/development/user-passwords/{username}"
        ssm_client.delete_parameter(Name=param_name)
        print(f"Deleted password parameter for {username}")
    except ssm_client.exceptions.ParameterNotFound:
        print(f"Password parameter not found for {username}, skipping")
    except Exception as e:
        errors.append(f"Password parameter deletion failed: {e}")
        print(f"ERROR: Password parameter deletion failed for {username}: {e}")

    if errors:
        return {'success': False, 'action': 'delete', 'username': username, 'errors': errors}
    return {'success': True, 'action': 'delete', 'username': username}


def wait_for_ssm_command(ssm_client, command_id, instance_id, max_wait=120):
    terminal_statuses = {'Success', 'Failed', 'TimedOut', 'Cancelled', 'DeliveryTimedOut'}
    elapsed = 0

    while elapsed < max_wait:
        try:
            result = ssm_client.get_command_invocation(
                CommandId=command_id,
                InstanceId=instance_id
            )
            status = result['Status']
            if status in terminal_statuses:
                return status, result
            print(f"SSM command status: {status} ({elapsed}s elapsed)")
        except ssm_client.exceptions.InvocationDoesNotExist:
            pass

        time.sleep(10)
        elapsed += 10

    return 'TimedOut', {}
