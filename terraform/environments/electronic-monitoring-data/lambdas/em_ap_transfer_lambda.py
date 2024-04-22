import json
import boto3
import datetime
from logging import getLogger
import os

logger = getLogger(__name__)

s3_client = boto3.client("s3", region_name="eu-west-2")


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
    current_timestamp = datetime.datetime.now().strftime("%Y%m%d%H%M%SZ")

    project_name = "electronic-monitoring-service"
    destination_key = f"landing/{project_name}/data/database_name={database_name}/table_name={table_name}/extraction_timestamp={current_timestamp}/{file_name}"

    # Specify from where file needs to be copied
    copy_object = {"Bucket": source_bucket_name, "Key": file_key}

    # Write copy statement
    response = s3_client.get_object(**copy_object)
    object_body = response["Body"].read()
    logger.info("File read succesfully")

    try:
        # Put the object into the destination bucket
        response = s3_client.put_object(
            Body=object_body,
            Key=destination_key,
            Bucket=destination_bucket,
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
