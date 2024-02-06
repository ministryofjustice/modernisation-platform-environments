import json
import boto3 
from ldap3 import Server, Connection, ALL

# checks for objects within active directory
def check_ad_for_object(hostname, domain_fqdn, domain_name):
    '''
    This function takes the following variables:
    hostname
    domain_fqdn
    domain_account 
    '''
    
    # create a secrets manager connection
    secrets_manager = boto3.client('secretsmanager')
    
    # extract the secret value from hmpps-domain-services-test / hmpps-domain-services-prod
    secret_name = f"/microsoft/AD/{domain_fqdn}/shared-passwords"
    response = secrets_manager.get_secret_value(SecretId=secret_name)
    secret_data = response['SecretString']

    # parse the JSON format secret data
    secret_json = json.loads(secret_data)
    ad_password = secret_json['aws-lambda'] # update
    
    # domain connection details
    domain_controller = Server(f'{domain_fqdn}:389')
    ad_username = rf'{domain_name}\aws-lambda'
    
    with Connection(Server, user=ad_username, password=ad_password, auto_bind=True) as conn:
        search_base = 'ou=Managed-Windows-Servers,ou=Computers,dc=azure,dc=noms,dc=root'
        search_filter = f'(sAMAccountName={hostname})'
        
        search_result = conn.search(search_base, search_filter)
        print(search_result)
        status = 1 # default to "fail"

        if conn.entries:
            # Get the distinguished name (DN) of the found object
            object_dn = conn.entries[0].entry_dn
            print(object_dn)
            print(f"The object {hostname} is present in Active Directory and will be deleted.")
            # action removed during testing
            # conn.delete(object_dn) 
            status = 0
        else:
            print(f"The object {hostname} is not found in Active Directory - no further action taken.")
        return status

# function to iterate through instance tags
def get_tag_value(tags, key):
    for tag in tags:
        if tag['Key'] == key:
            return tag['Value']
    return None

# function to determine test or prod domain values to be used
def determine_domain(environment_tag):
    domain_info = {}
    if "development" in environment_tag.split('-') or "test" in environment_tag.split('-'):
        domain_info['domain_name'] = "azure"
        domain_info['domain_fqdn'] = "azure.noms.root"
        # domain_info['account'] = "hmpps-domain-services-test"
    elif "preproduction" in environment_tag.split('-') or "production" in environment_tag.split('-'):
        domain_info['domain_name'] = "hmpp"
        domain_info['domain_fqdn'] = "azure.hmpp.root"
        # domain_info['account'] = "hmpps-domain-services-production"
    else:
        print("Unexpected environment-name tag. Aborting lambda function...")
        return None
    return domain_info

# function to search active directory if an instance is stopped, final iteration will be state terminated                       
def lambda_handler(event, context):

    if event['detail']['state'] == 'stopped': # to be updated to terminated
        instance_id = event['detail']['instance-id']
        
        # creates an ec2 connection for terminated instance
        ec2 = boto3.client('ec2')
        response = ec2.describe_instances(InstanceIds=[instance_id])
        # return the tags associated with the terminated instance
        tags = response['Reservations'][0]['Instances'][0]['Tags']
        
        # terminated instance server-name value
        resource_name = 'server-name'
        hostname = get_tag_value(tags, resource_name)        
        
        # terminated instance environment-name value
        resource_environment = 'environment-name'
        environment_tag = get_tag_value(tags, resource_environment)

        # determine correct domain variables
        domain = determine_domain(environment_tag)
        print("Domain address: {}".format(domain['domain_fqdn']))

        # pass hostname and domain fqdn into AD function
        if hostname is not None and domain is not None:
            check_ad_for_object(hostname, domain['domain_fqdn'], domain['domain_name'])
        else:
            print(f"The tag '{resource_name}' was not found for the instance.")
    
    # 200 http response lambda run successful
    return {
        'statusCode': 200,
        'body': 'Active Directory clean up complete. Computer object {resource_name} has been removed.'
    }
