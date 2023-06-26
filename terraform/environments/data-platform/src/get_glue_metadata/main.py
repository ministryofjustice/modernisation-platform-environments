import json
import boto3

def handler(event, context):
    database = event["queryStringParameters"]["database"]
    table = event["queryStringParameters"]["table"]

    glue_client = boto3.client("glue")
    resp = glue_client.get_table(DatabaseName=database, Name=table)

    return {
       'statusCode': 200,
       'body': json.dumps(resp, default=str)
   }
