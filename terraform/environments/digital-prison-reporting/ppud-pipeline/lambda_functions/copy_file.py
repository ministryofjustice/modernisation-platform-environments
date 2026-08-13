import logging
import os
import re

import boto3

logger = logging.getLogger()
logger.setLevel(os.getenv("LOG_LEVEL", "INFO"))


def handler(event, context):  # pylint: disable=unused-argument
    bak_upload_bucket = os.environ["BACKUP_UPLOADS_BUCKET"]
    land_bucket = os.environ["LAND_BUCKET"]
    region = os.environ["REGION"]

    s3 = boto3.resource("s3", region_name=region)

    regex_pattern = r"\d{14}"

    try:
        record = event["Records"][0]
        key = record["s3"]["object"]["key"]

        match = re.search(regex_pattern, key)

        if match is not None:
            s3.meta.client.copy(
                {"Bucket": land_bucket, "Key": key}, bak_upload_bucket, key
            )
            logger.info(f"Copied file: {key} from {land_bucket} to {bak_upload_bucket}")
        else:
            logger.info(
                f"File not copied as key:{key} does not follow naming convention"
            )

    except Exception as e:
        logger.error(f"Error copying file to bucket: {str(e)}")
        raise
