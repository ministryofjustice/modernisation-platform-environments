import json
import os
from urllib.parse import unquote_plus

import boto3

s3 = boto3.client("s3")
BUCKETS_BY_KEY = json.loads(os.environ["BUCKETS_BY_KEY"])
DEFAULT_SOURCE_BUCKET_KEY = os.environ["DEFAULT_SOURCE_BUCKET_KEY"]


def iter_events(event):
    if "Records" not in event:
        yield event
        return

    for record in event["Records"]:
        if "body" not in record:
            yield record
            continue

        yield json.loads(record["body"])


def get_object_details(event):
    if "detail" in event and "s3ObjectDetails" in event["detail"]:
        object_details = event["detail"]["s3ObjectDetails"]
        return unquote_plus(object_details["objectKey"]), object_details.get("versionId")

    return unquote_plus(event["object_key"]), event.get("version_id")


def as_bool(value):
    if isinstance(value, bool):
        return value

    return str(value).lower() == "true"


def lambda_handler(event, context):
    for payload in iter_events(event):
        source_bucket_key = payload.get("source_bucket_key", DEFAULT_SOURCE_BUCKET_KEY)
        destination_bucket_key = payload.get("destination_bucket_key")

        if destination_bucket_key is None and "destination_bucket" not in payload:
            raise KeyError("destination_bucket_key")

        source_bucket = payload.get("source_bucket", BUCKETS_BY_KEY[source_bucket_key])
        destination_bucket = payload.get(
            "destination_bucket",
            BUCKETS_BY_KEY[destination_bucket_key],
        )

        source_key, version_id = get_object_details(payload)

        copy_source = {
            "Bucket": source_bucket,
            "Key": source_key,
        }

        if version_id:
            copy_source["VersionId"] = version_id

        s3.copy_object(
            Bucket=destination_bucket,
            Key=source_key,
            CopySource=copy_source,
            MetadataDirective="COPY",
            TaggingDirective="COPY",
        )

        if as_bool(payload.get("delete_source", False)):
            delete_kwargs = {
                "Bucket": source_bucket,
                "Key": source_key,
            }

            if version_id:
                delete_kwargs["VersionId"] = version_id

            s3.delete_object(**delete_kwargs)