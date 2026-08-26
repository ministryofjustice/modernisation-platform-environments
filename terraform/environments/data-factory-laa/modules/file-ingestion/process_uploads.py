import awswrangler as wr
import pandas as pd
import boto3
import os

s3 = boto3.client('s3')
FILE_UPLOADS_BUCKET = os.environ['FILE_UPLOADS_BUCKET']
PROCESSED_FILE_UPLOADS_BUCKET = os.environ['PROCESSED_FILE_UPLOADS_BUCKET']
DATABASE_NAME = os.environ['DATABASE_NAME']

def lambda_handler(event, context):
    # List all top level directories in the S3 bucket
    response = s3.list_objects_v2(Bucket=FILE_UPLOADS_BUCKET, Delimiter='/')
    directories = [prefix['Prefix'] for prefix in response.get('CommonPrefixes', [])]
    
    # Read all CSV files from each directory and put them into a dict of DataFrames
    dataframes = {}
    for directory in directories:
        # List all CSV files in the directory
        response = s3.list_objects_v2(Bucket=FILE_UPLOADS_BUCKET, Prefix=directory)
        csv_files = [obj['Key'] for obj in response.get('Contents', []) if obj['Key'].endswith('.csv')]
        
        # Read each CSV file into a DataFrame and concatenate them
        df_list = []
        for csv_file in csv_files:
            df = wr.s3.read_csv(f's3://{FILE_UPLOADS_BUCKET}/{csv_file}')
            df_list.append(df)
        

        # For each DF, create a table in the database and write the data to it
        for i, df in enumerate(df_list):
            table_name = f"{directory.strip('/').replace('/', '_')}_table_{i}"
            wr.catalog.create_table(
                database=DATABASE_NAME,
                table=table_name,
                columns_types={col: str(df[col].dtype) for col in df.columns},
                description=f"Table for {directory} CSV files",
                path=f"s3://{PROCESSED_FILE_UPLOADS_BUCKET}/{table_name}/"
            )
            wr.s3.to_parquet(
                df=df,
                path=f"s3://{PROCESSED_FILE_UPLOADS_BUCKET}/{table_name}/",
                dataset=True,
                mode='overwrite'
            )
