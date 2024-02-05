import json
import boto3 
from ldap3 import Server, Connection, ALL

# checks for objects within active directory
def check_ad_for_object(hostname, domain_fqdn):
    '''
    This function takes the following variables:
    domain_fqdn
    hostname
    '''
    
    # create a secrets manager client
    secrets_manager_client = boto3.client('secretsmanager')
    
    # extract the secret value from hmpps-domain-services-test / hmpps-domain-services-prod
    secret_name = "/microsoft/AD/{}/shared-passwords".format(domain_fqdn)
    response = secrets_manager_client.get_secret_value(SecretId=secret_name)
    secret_data = response['SecretString']

    # extract the secret value from hmpps-domain-services-prod

    response = secrets_manager_client.get_secret_value(SecretId=secret_name)
    secret_data = response['SecretString']

    # parse the JSON format secret data
    secret_json = json.loads(secret_data)
    ad_password = secret_json['aws-lambda']
    
    # dev test domain controller connection details
    test_server = Server('MGMCW0002.{domain_fqdn}:389', get_info=ALL)
    test_username = r'azure\aws-lambda'
    test_password = ad_password

    # preprod and prod domain controller connection details
    prod_server = Server('MGMCW0002.{domain_fqdn}:389', get_info=ALL)
    prod_username = r'azure\aws-lambda'
    prod_password = ad_password
    
    with Connection(server, user=username, password=password, auto_bind=True) as conn:
        search_base = 'ou=Managed-Windows-Servers,ou=Computers,dc=azure,dc=noms,dc=root'
        search_filter = f'(sAMAccountName={hostname})'
        
        search_result = conn.search(search_base, search_filter) # not doing anything with this right now need to pass in result into print and delete
        print(search_result)
        
        status = 1

        if conn.entries:
            # Get the distinguished name (DN) of the found object
            object_dn = conn.entries[0].entry_dn
            print(object_dn)
            print(f"The object {object} is present in Active Directory and will be deleted.")
            # action removed during testing
            # conn.delete(object_dn) 
            status = 0
        else:
            print(f"The object {object} is not found in Active Directory - no further action taken.")
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
        domain_info['domain'] = "dev / test"
        domain_info['domain_fqdn'] = "azure.noms.root"
        domain_info['account'] = "hmpps-domain-services-test"
    elif "preproduction" in environment_tag.split('-') or "production" in environment_tag.split('-'):
        domain_info['domain'] = "preprod / prod"
        domain_info['domain_fqdn'] = "azure.hmpp.root"
        domain_info['account'] = "hmpps-domain-services-production"
    else:
        print("Unexpected environment-name tag. Aborting lambda function...")
        return None
    return domain_info

# function to search active directory if an instance is stopped, final iteration will be state terminated                       
def lambda_handler(event, context):

    if event['detail']['state'] == 'stopped': # to be updated to terminated
        instance_id = event['detail']['instance-id']
        
        # return the tags associated with the terminated instance
        ec2 = boto3.client('ec2')
        response = ec2.describe_instances(InstanceIds=[instance_id])
        tags = response['Reservations'][0]['Instances'][0]['Tags']
        
        # terminated instance server-name value
        resource_name = 'server-name'
        hostname = get_tag_value(tags, resource_name)        
        
        # terminated instance environment-name value
        resource_environment = 'environment-name'
        environment_tag = get_tag_value(tags, resource_environment)

        # determine correct domain variables
        domain = determine_domain(environment_tag)
        print("Associated domain: {}".format(domain['domain']))

        # print("The domain info is:{}, {}".format(domain['domain']))
        # The domain info is:{"domain":"preprod / prod", "domain_fqdn":"..." ...}
        # The domain info is dev / test

        if hostname is not None and domain is not None:
            check_ad_for_object(hostname, domain['domain_fqdn'])
        else:
            print(f"The tag '{resource_name}' was not found for the instance.")
    
    # 200 http response lambda run successful
    return {
        'statusCode': 200,
        'body': 'Active Directory clean up complete. Computer object {resource_name} has been removed.'
    }
