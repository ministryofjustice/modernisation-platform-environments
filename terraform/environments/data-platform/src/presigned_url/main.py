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
    bucket_name = os.environ["bucketname"]
    amz_date = datetime.utcnow().strftime("%Y%m%dT%H%M%SZ")
    md5 = str(event["queryStringParameters"]["Content-MD5"])
    file_name = uuid.uuid4()
    fields = {
        "x-amz-server-side-encryption": "AES256",
        "x-amz-acl": "bucket-owner-full-control",
        "x-amz-date": amz_date,
        "Content-MD5": md5,
        "Content-Type": "binary/octet-stream",
    }
    # File upload is capped at 5GB per single upload
    conditions = [
        {"x-amz-server-side-encryption": "AES256"},
        {"x-amz-acl": "bucket-owner-full-control"},
        {"x-amz-date": amz_date},
        {"Content-MD5": md5},
        ["starts-with", "$Content-MD5", ""],
        ["starts-with", "$Content-Type", ""],
        ["starts-with", "$key", "data/"],
        ["content-length-range", 0, 5e9],
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
