import boto3
import os
import json

redshift_client = boto3.client("redshift-data")

def handler(event, context):
    workgroup = os.environ["REDSHIFT_WORKGROUP"]
    database = os.environ["DATABASE_NAME"]
    secret_arn = os.environ["SECRET_ARN"]
    sql_query_1 = os.environ["SQL_QUERY_1"]
    sql_query_2_file = os.environ["SQL_QUERY_2_FILE"]

    query_to_run = event.get("query", "materialized_views")  # default if nothing sent
    results = []

    try:
        if query_to_run == "materialized_views":
            print(f"Executing query 1: {sql_query_1}")
            resp = redshift_client.execute_statement(
                WorkgroupName=workgroup,
                Database=database,
                Sql=sql_query_1,
                SecretArn=secret_arn
            )
            results.append(resp["Id"])
            print(f"Query 1 statement ID: {resp['Id']}")

        elif query_to_run == "fte_redshift":
            print(f"Reading SQL from file: {sql_query_2_file}")
            with open(sql_query_2_file, "r") as f:
                sql_query_2 = f.read()
            resp = redshift_client.execute_statement(
                WorkgroupName=workgroup,
                Database=database,
                Sql=sql_query_2,
                SecretArn=secret_arn
            )
            results.append(resp["Id"])
            print(f"Query 2 statement ID: {resp['Id']}")

        return {"status": "success", "executed_statements": results}

    except Exception as e:
        print(f"Error executing Redshift query: {e}")
        raise
