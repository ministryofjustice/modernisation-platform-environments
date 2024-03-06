import boto3
region = 'eu-west-2'
cloudwatch = boto3.client('cloudwatch', region_name=region)

def lambda_handler(event):
    cloudwatch.enable_alarm_actions(AlarmNames=['CPU-High-i-029d2b17679dab982'])