import boto3 
client = boto3.client('cloudwatch')
     
def lambda_handler(event, context):
         response = client.enable_alarm_actions(
            AlarmNames=['CPU-Utilisation-High-i-014bce95a85aaeede','CPU-Utilisation-High-i-00cbccc46d25e77c6','CPU-Utilisation-High-i-0dba6054c0f5f7a11','CPU-Utilisation-High-i-0b5ef7cb90938fb82','CPU-Utilisation-High-i-04bbb6312b86648be','CPU-Utilisation-High-i-00413756d2dfcf6d2','CPU-Utilisation-High-i-080498c4c9d25e6bd','CPU-Utilisation-High-i-029d2b17679dab982','CPU-High-90%-i-029d2b17679dab982']
    )