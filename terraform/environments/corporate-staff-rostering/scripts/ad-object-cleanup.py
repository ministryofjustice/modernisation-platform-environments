import boto3
from ldap3 import Server, Connection, ALL

def check_ad_for_object(object):
    server = Server('MGMCW0002.azure.noms.root:389', get_info=ALL)
    username = 'azure\aws-lambda'
    password = 'Aw5Servic3Acc0unt'
    
    with Connection(server, user=username, password=password, auto_bind=True) as conn:
        search_base = 'ou=Managed-Windows-Servers, ou=Computers, dc=azure, dc=noms, dc=root'
        search_filter = f'(sAMAccountName={object})'
        
        conn.search(search_base, search_filter)
        
        if conn.entries:
            print(f"The object {object} is present in Active Directory and will be deleted.")
        else:
            print(f"The object {object} is not found in Active Directory - no further action taken.")

def get_tag_value(tags, key):
    for tag in tags:
        if tag['Key'] == key:
            return tag['Value']
    return None
            
            
def lambda_handler(event, context):
    if event['detail']['state'] == 'stopped':
        instance_id = event['detail']['instance_id']
        
        ec2 = boto3.client('ec2')
        response = ec2.describe_instances(InstanceIds=[instance_id])
        
        tags = response['Reservations'][0]['Instances'][0]['Tags']
        
        resource_key = 'server-name'
        
        resource_name = get_tag_value(tags, resource_key)
        
        if resource_name is not None:
            check_ad_for_object(resource_name)
        else:
            print(f"The tag '{resource_key}' was not found for the instance.")
    
    return {
        'statusCode': 200,
        'body': 'Active Directory search complete. Check logs for results'
    }