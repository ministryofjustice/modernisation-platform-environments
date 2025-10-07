import boto3
import os
import json

secrets_client = boto3.client('secretsmanager')
redshift_client = boto3.client('redshift-data')

def handler(event, context):
    # Get secret from Secrets Manager
    secret_arn = os.environ['SECRET_ARN']
    secret_string = secrets_client.get_secret_value(SecretId=secret_arn)['SecretString']
    secret = json.loads(secret_string)
    
    username = secret['username']
    password = secret.get('password')  # optional if needed
    database = os.environ['DATABASE_NAME']
    workgroup = os.environ['REDSHIFT_WORKGROUP']
    
    # Execute daily materialized views refresh
    sql1 = os.environ['SQL_QUERY_1']
    redshift_client.execute_statement(
        WorkgroupName=workgroup,
        Database=database,
        DbUser=username,
        Sql=sql1
    )
    
    # Execute weekly FTE query
    sql2_file = os.environ['SQL_QUERY_2_FILE']
    with open(sql2_file, 'r') as f:
        sql2 = f.read()
    
    redshift_client.execute_statement(
        WorkgroupName=workgroup,
        Database=database,
        DbUser=username,
        Sql=sql2
    )
    
    return {"status": "success"}
