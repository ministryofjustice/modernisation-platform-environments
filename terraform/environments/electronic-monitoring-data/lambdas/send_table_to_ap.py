import json
import boto3
import datetime
from logging import getLogger
import os

logger = getLogger(__name__)

s3_client = boto3.client("s3")

PARQUET_BUCKET_NAME = os.environ.get("PARQUET_BUCKET_NAME")
AP_DESTINATION_BUCKET = os.environ.get("AP_DESTINATION_BUCKET")

# lambda function to copy file from 1 s3 to another s3
def handler(event, context):
    # Specify source bucket
    database_name, table_name = event.items()[0]
    logger.info(f"Copying table {table_name} from database {database_name}")
    source_key = f"{database_name}/{table_name}/"
    destination_key = f"electronic_monitoring/load/{database_name}/{table_name}/"
    logger.info(
        f"""Copying file: {source_key} from bucket: {PARQUET_BUCKET_NAME}
        to {destination_key} in bucket: {AP_DESTINATION_BUCKET}"""
    )

    copy_object = {"Bucket": PARQUET_BUCKET_NAME, "Key": source_key}

    try:
        # Put the object into the destination bucket
        response = s3_client.copy_object(
            Bucket=AP_DESTINATION_BUCKET,
            Key=destination_key,
            CopySource=copy_object,
            ServerSideEncryption="AES256",
            ACL="bucket-owner-full-control",
            BucketKeyEnabled=True,
        )
        response_code = response["ResponseMetadata"]["HTTPStatusCode"]
        if response_code == 200:
            logger.info(f"{source_key} succesfully transferred to {AP_DESTINATION_BUCKET}")
        else:
            msg = f"An error has occurred writing {destination_key} to {AP_DESTINATION_BUCKET}, with response code: {response_code}"
            logger.error(msg)
            raise Exception(msg)
    except Exception as e:
        msg = f"An exception has occured: {e}"
        logger.error(msg)
        raise Exception(msg)

    return {"statusCode": 200, "body": json.dumps("File has been Successfully Copied to the AP")}
