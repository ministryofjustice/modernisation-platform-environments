import time
import json
import boto3

def lambda_handler(event, context):

    client = boto3.client("ec2")
    ssm = boto3.client("ssm")
    InstanceId = "i-0b5c31ecda24ebc04" # RGVW110

    response = ssm.send_command(InstanceIds=[InstanceId],DocumentName="AWS-RunPowerShellScript", Parameters={"commands": ['& "C:\\Scripts\\DEV_CPU_Notification.ps1"']})
    command_id = response["Command"]["CommandId"]
    time.sleep(3)

    output = ssm.get_command_invocation(CommandId=command_id, InstanceId=InstanceId)
    print(output)
    return {"statusCode": 200, "body": json.dumps("Run Successful")}
