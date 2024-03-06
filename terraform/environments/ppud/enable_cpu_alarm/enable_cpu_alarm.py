import boto3 
cloudwatch = boto3.client('cloudwatch')
     
def lambda_handler(event, context):
         response = cloudwatch.enable_alarm_actions(
            AlarmNames=['CPU-High-i-029d2b17679dab982','CPU-High-i-00cbccc46d25e77c6'] 
    )