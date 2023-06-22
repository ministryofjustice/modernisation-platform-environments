import json
import boto3

def handler(event, context):
    request_body = json.loads(event['body'])
    database = request_body['database']
    table = request_body['table']

    glue_client = boto3.client("glue")
    resp = glue_client.get_table(DatabaseName=database, Name=table)

    return {
       'statusCode': 200,
       'body': json.dumps(resp, default=str)
   }
