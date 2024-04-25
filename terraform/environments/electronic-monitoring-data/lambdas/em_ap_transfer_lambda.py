import json
import boto3
import datetime
from logging import getLogger
import os

logger = getLogger(__name__)

s3_client = boto3.client("s3")


# lambda function to copy file from 1 s3 to another s3
def handler(event, context):
    # Specify source bucket
    source_bucket_name = event["Records"][0]["s3"]["bucket"]["name"]
    destination_bucket = os.environ.get("REG_BUCKET_NAME")
    # Get object that has been uploaded
    file_key = event["Records"][0]["s3"]["object"]["key"]
    file_parts = file_key.split("/")
    database_name = file_parts[0]
    table_name = file_parts[2]
    file_name = file_parts[3]
    logger.info(
        f"Copying data... Database: {database_name}, Table: {table_name}, File: {file_name}"
    )
    current_timestamp = datetime.datetime.now().strftime("%Y%m%d%H%M%SZ")

    project_name = "electronic-monitoring-service"
    destination_key = f"landing/{project_name}/data/database_name={database_name}/table_name={table_name}/extraction_timestamp={current_timestamp}/{file_name}"
    logger.info(f"Copying to: {destination_bucket}, {destination_key}")
    # Specify from where file needs to be copied
    copy_object = {"Bucket": source_bucket_name, "Key": file_key}

    try:
        # Put the object into the destination bucket
        response = s3_client.copy_object(
            Bucket=destination_bucket,
            Key=destination_key,
            CopySource=copy_object,
            ServerSideEncryption="AES256",
            ACL="bucket-owner-full-control",
            BucketKeyEnabled=True,
        )
        response_code = response["ResponseMetadata"]["HTTPStatusCode"]
        if response_code == 200:
            logger.info(f"{file_name} succesfully transferred to {destination_bucket}")
        else:
            msg = f"An error has occurred writing {destination_key} to {destination_bucket}, with response code: {response_code}"
            logger.error(msg)
            raise Exception(msg)
    except Exception as e:
        msg = f"An exception has occured: {e}"
        logger.error(msg)
        raise Exception(msg)

    return {"statusCode": 200, "body": json.dumps("File has been Successfully Copied")}
