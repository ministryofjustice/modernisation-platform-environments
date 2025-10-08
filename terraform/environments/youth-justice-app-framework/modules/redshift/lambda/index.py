import boto3
import os

redshift_client = boto3.client("redshift-data")

def handler(event, context):
    # Environment variables
    secret_arn = os.environ["SECRET_ARN"]
    database = os.environ["DATABASE_NAME"]

    try:
        # Execute daily materialized views refresh
        sql1 = os.environ["SQL_QUERY_1"]
        resp1 = redshift_client.execute_statement(
            SecretArn=secret_arn,
            Database=database,
            Sql=sql1
        )
        print(f"Query 1 executed, statement ID: {resp1['Id']}")

        # Execute weekly FTE query
        sql2_file = os.environ["SQL_QUERY_2_FILE"]
        with open(sql2_file, "r") as f:
            sql2 = f.read()

        resp2 = redshift_client.execute_statement(
            SecretArn=secret_arn,
            Database=database,
            Sql=sql2
        )
        print(f"Query 2 executed, statement ID: {resp2['Id']}")

        return {"status": "success", "queries": [resp1["Id"], resp2["Id"]]}

    except Exception as e:
        print(f"Error executing Redshift queries: {e}")
        raise
