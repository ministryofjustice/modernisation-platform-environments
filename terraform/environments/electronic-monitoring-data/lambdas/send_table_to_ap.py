import json
import boto3
import datetime
import logging
import os

logger = logging.getLogger(__name__)
logger.setLevel(logging.INFO)


s3_client = boto3.client("s3")

AP_DESTINATION_BUCKET = os.environ.get("AP_DESTINATION_BUCKET")

def s3_path_to_bucket_key(s3_path):
    """
    Splits out s3 file path to bucket key combination
    """
    return s3_path.replace("s3://", "").split("/", 1)

# lambda function to copy file from 1 s3 to another s3
def handler(event, context):
    # Specify source bucket
    for key, value in event.items():
        database_table_name, source_s3_key = key, value
    bucket, source_key = s3_path_to_bucket_key(source_s3_key)
    database_name, schema_name, table_name, file_name = source_key.split("/")
    logger.info(f"Copying table {table_name} from database {database_name}")
    destination_key = f"electronic_monitoring/load/{database_name}/{table_name}/{file_name}"
    logger.info(
        f"""Copying file: {source_key} from bucket: {bucket}
        to {destination_key} in bucket: {AP_DESTINATION_BUCKET}"""
    )

    copy_object = {"Bucket": bucket, "Key": source_key}

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

    return (database_name, schema_name, table_name)
