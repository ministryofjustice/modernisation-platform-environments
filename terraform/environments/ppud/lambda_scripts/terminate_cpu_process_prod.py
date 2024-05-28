import time
time.sleep(120)
import json
import boto3

def lambda_handler(event, context):

    client = boto3.client("ec2")
    ssm = boto3.client("ssm")
    InstanceId = "i-029d2b17679dab982" # RGVW022

    response = ssm.send_command(InstanceIds=[InstanceId],DocumentName="AWS-RunPowerShellScript", Parameters={"commands": ['& "C:\\Scripts\\PROD_Terminate_Word.ps1"']})
    command_id = response["Command"]["CommandId"]
    time.sleep(3)

    output = ssm.get_command_invocation(CommandId=command_id, InstanceId=InstanceId)
    print(output)
    return {"statusCode": 200, "body": json.dumps("Run Successful")}
