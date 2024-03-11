import json
import boto3
import pyodbc
import pandas as pd
import io

s3_client = boto3.client("s3")
secrets_manager_client = boto3.client("secretsmanager")


def get_db_credentials(secret_name):
    get_secret_value_response = secrets_manager_client.get_secret_value(
        SecretId=secret_name
    )
    secret = get_secret_value_response["SecretString"]

    return json.loads(secret)


def lambda_handler(event, context):
    username = "admin"
    password = get_db_credentials("db_password")
    sql_server_endpoint = event["sql_server_endpoint"]
    database_name = event["database_name"]
    s3_bucket = event["s3_bucket"]
    s3_key_prefix = event["s3_key_prefix"]
    query = event["query"]

    PAGE_SIZE = 1000
    file_index = 0
    offset = 0

    # Establish connection to the SQL Server
    conn_str = f"DRIVER={{ODBC Driver 17 for SQL Server}};SERVER={sql_server_endpoint};DATABASE={database_name};UID={username};PWD={password}"
    conn = pyodbc.connect(conn_str)

    while True:
        # Modify the query to fetch a specific page of data
        paginated_query = (
            f"{query} OFFSET {offset} ROWS FETCH NEXT {PAGE_SIZE} ROWS ONLY"
        )

        # Read SQL query into a pandas DataFrame
        df = pd.read_sql_query(paginated_query, conn)

        if df.empty:
            break

        # Serialize DataFrame to Parquet format in memory
        output = io.BytesIO()
        df.to_parquet(output, index=False)
        output.seek(0)

        # Write Parquet file to S3
        s3_key = f"{s3_key_prefix}/data_part_{file_index}.parquet"
        s3_client.put_object(Bucket=s3_bucket, Key=s3_key, Body=output.getvalue())
        file_index += 1

        # Update offset for next iteration
        offset += PAGE_SIZE

    # Close SQL connection
    conn.close()

    return {
        "statusCode": 200,
        "body": json.dumps("Data transfer to Parquet files completed"),
    }
