import os
import json
import boto3
import logging
from datetime import datetime

logging.basicConfig(level=logging.INFO, force=True)
root_logger = logging.getLogger()
s3 = boto3.client("s3")


def handler(event, context):
    bucket_name = os.environ["bucketname"]
    amz_date = datetime.utcnow().strftime("%Y%m%dT%H%M%SZ")
    file_name = event["queryStringParameters"]["filename"]
    fields = {
        "x-amz-server-side-encryption": "AES256",
        "x-amz-acl": "bucket-owner-full-control",
        "x-amz-date": amz_date,
    }
    # File upload is capped at 5GB per single upload
    conditions = [
        {"x-amz-server-side-encryption": "AES256"},
        {"x-amz-acl": "bucket-owner-full-control"},
        {"x-amz-date": amz_date},
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
