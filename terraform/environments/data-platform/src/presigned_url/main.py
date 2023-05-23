import os
import json
import uuid
import boto3
import logging
from datetime import datetime

logging.basicConfig(level=logging.INFO, force=True)
root_logger = logging.getLogger()
s3 = boto3.client("s3")


def handler(event, context):
    bucket_name = os.environ["BUCKET_NAME"]
    database = event["queryStringParameters"]["database"]
    table = event["queryStringParameters"]["table"]
    amz_date = datetime.utcnow().strftime("%Y%m%dT%H%M%SZ")
    md5 = str(event["queryStringParameters"]["contentMD5"])
    uuid_string = str(uuid.uuid4())
    file_name = os.path.join(
        "curated_data",
        f"database_name={database}",
        f"table_name={table}",
        f"extraction_timestamp={amz_date}",
        uuid_string,
    )
    fields = {
        "x-amz-server-side-encryption": "AES256",
        "x-amz-acl": "bucket-owner-full-control",
        "x-amz-date": amz_date,
        "Content-MD5": md5,
        "Content-Type": "binary/octet-stream",
    }
    # File upload is capped at 5GB per single upload so content-length-range is 5GB
    conditions = [
        {"x-amz-server-side-encryption": "AES256"},
        {"x-amz-acl": "bucket-owner-full-control"},
        {"x-amz-date": amz_date},
        {"Content-MD5": md5},
        ["starts-with", "$Content-MD5", ""],
        ["starts-with", "$Content-Type", ""],
        ["starts-with", "$key", file_name],
        ["content-length-range", 0, 5000000000],
    ]

    root_logger.info(f"s3 key: {file_name}")

    URL = s3.generate_presigned_post(
        Bucket=bucket_name,
        Key=file_name,
        Fields=fields,
        Conditions=conditions,
        ExpiresIn=200,
    )
    return {
        "statusCode": 200,
        "headers": {"Content-Type": "application/json"},
        "body": json.dumps({"URL": URL}),
    }
