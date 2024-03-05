import boto3
client = boto3.client('cloudwatch')

def lambda_handler(event):
    cloudwatch.enable_alarm_actions(AlarmNames=['CPU-High-i-029d2b17679dab982'])