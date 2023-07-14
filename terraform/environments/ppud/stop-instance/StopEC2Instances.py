import boto3
region = 'eu-west-2'
instances = ['i-0550d9ffa6f55b4b2']
ec2 = boto3.client('ec2', region_name=region)

def lambda_handler(event, context):
    ec2.stop_instances(InstanceIds=instances)
    print('stopped your instances: ' + str(instances))