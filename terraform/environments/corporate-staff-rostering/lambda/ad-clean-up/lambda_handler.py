import json
import boto3 
from ldap3 import Server, Connection, ALL

# function to check for objects within active directory
def check_ad_for_object(object):
    
    # create a secrets manager client
    secrets_manager_client = boto3.client('secretsmanager')
    # extract the secret value
    secret_name = '/activedirectory/devtest/aws-lambda/passwords'
    response = secrets_manager_client.get_secret_value(SecretId=secret_name)
    secret_data = response['SecretString']

    # parse the JSON format secret data
    secret_json = json.loads(secret_data)
    ad_password = secret_json['aws-lambda']
    
    # dev test domain controller connection details
    server = Server('MGMCW0002.azure.noms.root:389', get_info=ALL)
    username = r'azure\aws-lambda'
    password = ad_password
    
    with Connection(server, user=username, password=password, auto_bind=True) as conn:
        search_base = 'ou=Managed-Windows-Servers,ou=Computers,dc=azure,dc=noms,dc=root'
        search_filter = f'(sAMAccountName={object})'
        
        search_result = conn.search(search_base, search_filter) # not doing anything with this right now need to pass in result into print and delete
        print(search_result)
        
        if conn.entries:
            # Get the distinguished name (DN) of the found object
            object_dn = conn.entries[0].entry_dn
            print(object_dn)
            print(f"The object {object} is present in Active Directory and will be deleted.")
            conn.delete(object_dn)
        else:
            print(f"The object {object} is not found in Active Directory - no further action taken.")

# function to iterate through instance tags 
def get_tag_value(tags, key):
    for tag in tags:
        if tag['Key'] == key:
            return tag['Value']
    return None

# function to search active directory if an instance is stopped, final iteration will be state terminated                       
def lambda_handler(event, context):
    print (json.__version__)
    if event['detail']['state'] == 'stopped':
        instance_id = event['detail']['instance-id']
        
        ec2 = boto3.client('ec2')
        response = ec2.describe_instances(InstanceIds=[instance_id])
        
        tags = response['Reservations'][0]['Instances'][0]['Tags']
        resource_key = 'server-name'
        resource_name = get_tag_value(tags, resource_key)
        
        if resource_name is not None:
            check_ad_for_object(resource_name)
        else:
            print(f"The tag '{resource_key}' was not found for the instance.")
    
    # 200 http response lambda run successful
    return {
        'statusCode': 200,
        'body': 'Active Directory search complete. Check logs for results'
    }
