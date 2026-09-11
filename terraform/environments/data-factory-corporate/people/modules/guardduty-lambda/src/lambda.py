# Lambda that receives events from EventBridge when GuardDuty reports an unsafe or failed S3 object scan.
# Infected/failed objects are copied to the quarantine bucket and removed from the source bucket.

import json
import logging
import os

import boto3

logger = logging.getLogger()
logger.setLevel(logging.INFO)

s3_client = boto3.client("s3")

QUARANTINE_BUCKET_NAME = os.environ["QUARANTINE_BUCKET_NAME"]
QUARANTINE_KMS_KEY_ARN = os.environ["QUARANTINE_KMS_KEY_ARN"]
QUARANTINE_STATUSES = set(
    json.loads(os.environ["QUARANTINE_STATUSES"])
)


def quarantine_object(bucket_name, object_key):
    """Copy the object to the quarantine bucket then delete it from the source bucket."""
    s3_client.copy_object(
        Bucket=QUARANTINE_BUCKET_NAME,
        Key=object_key,
        CopySource={"Bucket": bucket_name, "Key": object_key},
        ServerSideEncryption="aws:kms",
        SSEKMSKeyId=QUARANTINE_KMS_KEY_ARN,
    )
    s3_client.delete_object(Bucket=bucket_name, Key=object_key)

def lambda_handler(event, context):
    logger.info("Received event: " + json.dumps(event, indent=2))

    detail = event.get("detail", {})

    s3_object = detail.get("s3ObjectDetails", {})
    bucket_name = s3_object.get("bucketName")
    object_key = s3_object.get("objectKey")

    scan_result_status = (
        detail.get("scanResultDetails", {})
        .get("scanResultStatus")
    )

    logger.info(
        f"Bucket: {bucket_name}, "
        f"Object Key: {object_key}, "
        f"Scan Result Status: {scan_result_status}"
    )

    if scan_result_status in QUARANTINE_STATUSES:
        logger.info(
            f"Quarantining object {object_key} in bucket {bucket_name} "
            f"due to scan result: {scan_result_status}"
        )

        quarantine_object(bucket_name, object_key)

    logger.info(
        f"Lambda execution completed for object: "
        f"{object_key} in bucket: {bucket_name}"
    )