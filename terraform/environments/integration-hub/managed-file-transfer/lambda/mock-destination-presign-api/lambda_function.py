import json
import os
from pathlib import PurePosixPath
from uuid import uuid4

import boto3
from botocore.config import Config

AWS_REGION = os.environ.get("AWS_REGION", "eu-west-2")
DESTINATION_BUCKET_NAME = os.environ["DESTINATION_BUCKET_NAME"]
DESTINATION_KMS_KEY_ARN = os.environ["DESTINATION_KMS_KEY_ARN"]
DESTINATION_PREFIX = os.environ.get("DESTINATION_PREFIX", "manual-destination-tests")

s3 = boto3.client(
    "s3",
    region_name=AWS_REGION,
    endpoint_url=f"https://s3.{AWS_REGION}.amazonaws.com",
    config=Config(signature_version="s3v4", s3={"addressing_style": "virtual"}),
)


def _parse_body(event):
    raw_body = event.get("body")
    if not raw_body:
        return {}

    return json.loads(raw_body)


def _build_destination_key(payload):
    transfer_ticket = payload.get("transferTicket") or str(uuid4())
    file_name = PurePosixPath(payload.get("fileName") or "clean-file.dat").name or "clean-file.dat"
    return f"{DESTINATION_PREFIX}/{transfer_ticket}-{file_name}"


def lambda_handler(event, context):
    payload = _parse_body(event)
    content_type = payload.get("contentType") or "application/octet-stream"
    destination_key = _build_destination_key(payload)
    presign_params = {
        "Bucket": DESTINATION_BUCKET_NAME,
        "Key": destination_key,
        "ContentType": content_type,
        "ServerSideEncryption": "aws:kms",
        "SSEKMSKeyId": DESTINATION_KMS_KEY_ARN,
    }
    upload_url = s3.generate_presigned_url(
        "put_object",
        Params=presign_params,
        ExpiresIn=3600,
        HttpMethod="PUT",
    )

    response_body = {
        "upload": {
            "url": upload_url,
            "method": "PUT",
            "headers": {
                "Content-Type": content_type,
                "x-amz-server-side-encryption": "aws:kms",
                "x-amz-server-side-encryption-aws-kms-key-id": DESTINATION_KMS_KEY_ARN,
            },
        },
        "destination": {
            "bucket": DESTINATION_BUCKET_NAME,
            "key": destination_key,
        },
    }

    return {
        "statusCode": 200,
        "headers": {"Content-Type": "application/json"},
        "body": json.dumps(response_body),
    }
