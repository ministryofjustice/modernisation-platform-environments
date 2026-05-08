import json
import os
from urllib.parse import unquote_plus

import boto3

s3 = boto3.client("s3")
DESTINATION_BUCKET = os.environ["DESTINATION_BUCKET"]


def iter_s3_records(event):
    for record in event["Records"]:
        if "body" not in record:
            yield record
            continue

        payload = json.loads(record["body"])

        for s3_record in payload.get("Records", []):
            yield s3_record


def lambda_handler(event, context):
    for record in iter_s3_records(event):
        source_bucket = record["s3"]["bucket"]["name"]
        source_key = unquote_plus(record["s3"]["object"]["key"])

        copy_source = {
            "Bucket": source_bucket,
            "Key": source_key,
        }

        if "versionId" in record["s3"]["object"]:
            copy_source["VersionId"] = record["s3"]["object"]["versionId"]

        s3.copy_object(
            Bucket=DESTINATION_BUCKET,
            Key=source_key,
            CopySource=copy_source,
            MetadataDirective="COPY",
            TaggingDirective="COPY",
        )