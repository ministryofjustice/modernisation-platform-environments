import json
import boto3
import datetime

s3_client = boto3.client("s3")


# lambda function to copy file from 1 s3 to another s3
def lambda_handler(event, context):
    # specify source bucket
    source_bucket_name = event["Records"][0]["s3"]["bucket"]["name"]
    # get object that has been uploaded
    file_name = event["Records"][0]["s3"]["object"]["key"]
    file_parts = file_name.split["/"]
    database_name = file_parts[1]
    table_name = file_parts[2]
    file_name = file_parts[3]
    current_timestamp = datetime.datetime.now().strftime("%Y%m%d%H%M%SZ")
    # specify destination bucket
    destination_bucket_name = "moj-reg-dev"
    project_name = ""
    destination_key = f"landing/{project_name}/data/database_name={database_name}/table_name={table_name}/extraction_timestamp={current_timestamp}/{file_name}"
    # specify from where file needs to be copied
    copy_object = {"Bucket": source_bucket_name, "Key": destination_key}
    # write copy statement
    s3_client.copy_object(
        CopySource=copy_object, Bucket=destination_bucket_name, Key=file_name
    )

    return {"statusCode": 3000, "body": json.dumps("File has been Successfully Copied")}
