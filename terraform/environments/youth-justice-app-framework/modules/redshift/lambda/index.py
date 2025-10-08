import boto3
import os
import json
import logging

logger = logging.getLogger()
logger.setLevel(logging.INFO)

secrets_client = boto3.client('secretsmanager')
redshift_client = boto3.client('redshift-data')

def handler(event, context):
    try:
        # Retrieve secret
        secret_arn = os.environ['SECRET_ARN']
        secret_value = secrets_client.get_secret_value(SecretId=secret_arn)
        secret = json.loads(secret_value['SecretString'])

        # Extract connection details
        username = secret['username']
        password = secret['password']  # Not required directly for Data API
        database = secret.get('database', os.environ.get('DATABASE_NAME'))
        workgroup = os.environ['REDSHIFT_WORKGROUP']

        logger.info(f"Using workgroup: {workgroup}, database: {database}, user: {username}")

        # --- Query 1: Refresh materialized views ---
        sql1 = os.environ['SQL_QUERY_1']
        logger.info(f"Executing Query 1: {sql1}")
        resp1 = redshift_client.execute_statement(
            WorkgroupName=workgroup,
            Database=database,
            DbUser=username,
            Sql=sql1
        )
        logger.info(f"Query 1 submitted: {resp1['Id']}")

        # --- Query 2: Weekly FTE query ---
        sql2_file = os.environ['SQL_QUERY_2_FILE']
        with open(sql2_file, 'r') as f:
            sql2 = f.read()

        logger.info(f"Executing Query 2 from {sql2_file}")
        resp2 = redshift_client.execute_statement(
            WorkgroupName=workgroup,
            Database=database,
            DbUser=username,
            Sql=sql2
        )
        logger.info(f"Query 2 submitted: {resp2['Id']}")

        return {
            "status": "success",
            "queries": [resp1['Id'], resp2['Id']]
        }

    except Exception as e:
        logger.error(f"Error executing Redshift queries: {str(e)}")
        raise
