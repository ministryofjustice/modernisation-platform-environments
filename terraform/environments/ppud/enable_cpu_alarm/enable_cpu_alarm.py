import boto3 
client = boto3.client('cloudwatch')
     
def lambda_handler(event, context):
         response = client.enable_alarm_actions(
            AlarmNames=['CPU-High-i-029d2b17679dab982','CPU-High-i-00cbccc46d25e77c6'] 
    )