import boto3
import pandas as pd
import os
import time

# S3 and Athena-related parameters
s3_bucket = 'emds-dev-dms-data-validation-20240917144028498200000007'  # Replace with your S3 bucket
athena_database = 'test_database'  # Replace with your Athena database
s3_output = f's3://{s3_bucket}/athena-output/'  # Athena query output location
region_name = 'eu-west-2'  # Replace with your AWS region

# Local directory to save CSV files before uploading to S3
local_directory = '/tmp/athena_data/'
os.makedirs(local_directory, exist_ok=True)

# Initialize the boto3 clients
s3_client = boto3.client('s3', region_name=region_name)
athena_client = boto3.client('athena', region_name=region_name)

# Function to upload a file to S3
def upload_to_s3(file_name, s3_bucket, s3_key):
    s3_client.upload_file(file_name, s3_bucket, s3_key)
    print(f"Uploaded {file_name} to s3://{s3_bucket}/{s3_key}")

# Function to execute an Athena query
def execute_query(query, database, s3_output):
    response = athena_client.start_query_execution(
        QueryString=query,
        QueryExecutionContext={'Database': database},
        ResultConfiguration={'OutputLocation': s3_output}
    )
    return response['QueryExecutionId']

# Function to wait for query completion
def wait_for_query_completion(execution_id):
    while True:
        response = athena_client.get_query_execution(QueryExecutionId=execution_id)
        state = response['QueryExecution']['Status']['State']
        if state in ['SUCCEEDED', 'FAILED', 'CANCELLED']:
            break
        time.sleep(2)
    return state

# Dummy data for each table
dummy_data = {
    'dummy_table_1': [
        {'id': 1, 'name': 'Alice', 'age': 30},
        {'id': 2, 'name': 'Bob', 'age': 25},
        {'id': 3, 'name': 'Charlie', 'age': 35}
    ],
    'dummy_table_2': [
        {'order_id': 'O001', 'product': 'Laptop', 'price': 999.99},
        {'order_id': 'O002', 'product': 'Phone', 'price': 699.99},
        {'order_id': 'O003', 'product': 'Tablet', 'price': 499.99}
    ],
    'dummy_table_3': [
        {'user_id': 101, 'email': 'alice@example.com', 'created_at': '2023-01-01 12:00:00'},
        {'user_id': 102, 'email': 'bob@example.com', 'created_at': '2023-02-15 15:30:00'},
        {'user_id': 103, 'email': 'charlie@example.com', 'created_at': '2023-03-10 09:45:00'}
    ],
    'dummy_table_4': [
        {'transaction_id': 'T001', 'user_id': 101, 'amount': 150.50, 'transaction_date': '2023-01-01'},
        {'transaction_id': 'T002', 'user_id': 102, 'amount': 200.00, 'transaction_date': '2023-02-10'},
        {'transaction_id': 'T003', 'user_id': 103, 'amount': 99.99, 'transaction_date': '2023-03-05'}
    ]
}

# Function to create CSV files and upload to S3
def create_and_upload_csv_data(table_name, data):
    file_name = f"{local_directory}{table_name}.parquet"
    s3_key = f"{table_name}/{table_name}.parquet"
    
    # Convert data to a pandas DataFrame
    df = pd.DataFrame(data)

    # Write the DataFrame to Parquet
    df.to_parquet(file_name, engine='pyarrow', index=False)
    
    # Upload the CSV file to S3
    upload_to_s3(file_name, s3_bucket, s3_key)

# Create and upload data for each table
for table_name, data in dummy_data.items():
    create_and_upload_csv_data(table_name, data)

# Athena table creation queries
create_table_queries = [
    """
    CREATE EXTERNAL TABLE IF NOT EXISTS dummy_table_1 (
        id INT,
        name STRING,
        age INT
    )
    STORED AS PARQUET
    LOCATION 's3://emds-dev-dms-data-validation-20240917144028498200000007/dummy_table_1/'  -- Replace with actual S3 location
    TBLPROPERTIES ('has_encrypted_data'='false');
    """,
    """
    CREATE EXTERNAL TABLE IF NOT EXISTS dummy_table_2 (
        order_id STRING,
        product STRING,
        price DOUBLE
    )
    STORED AS PARQUET
    LOCATION 's3://emds-dev-dms-data-validation-20240917144028498200000007/dummy_table_2/'  -- Replace with actual S3 location
    TBLPROPERTIES ('has_encrypted_data'='false');
    """,
    """
    CREATE EXTERNAL TABLE IF NOT EXISTS dummy_table_3 (
        user_id INT,
        email STRING,
        created_at TIMESTAMP
    )
    STORED AS PARQUET
    LOCATION 's3://emds-dev-dms-data-validation-20240917144028498200000007/dummy_table_3/'  -- Replace with actual S3 location
    TBLPROPERTIES ('has_encrypted_data'='false');
    """,
    """
    CREATE EXTERNAL TABLE IF NOT EXISTS dummy_table_4 (
        transaction_id STRING,
        user_id INT,
        amount DOUBLE,
        transaction_date DATE
    )
    STORED AS PARQUET
    LOCATION 's3://emds-dev-dms-data-validation-20240917144028498200000007/dummy_table_4/'  -- Replace with actual S3 location
    TBLPROPERTIES ('has_encrypted_data'='false');
    """
]

# Execute the queries to create tables
for query in create_table_queries:
    query_execution_id = execute_query(query, athena_database, s3_output)
    print(f"Started query execution with ID: {query_execution_id}")
    
    # Wait for query completion
    query_status = wait_for_query_completion(query_execution_id)
    
    if query_status == 'SUCCEEDED':
        print(f"Table created successfully with QueryExecutionId: {query_execution_id}")
    else:
        print(f"Table creation failed with QueryExecutionId: {query_execution_id}")

print("All tables created successfully (or already existed).")