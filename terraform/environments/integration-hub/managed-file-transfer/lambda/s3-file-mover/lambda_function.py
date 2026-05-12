import json
import os
from urllib.parse import unquote_plus

import boto3
from aws_lambda_powertools.utilities.idempotency import (
    DynamoDBPersistenceLayer,
    IdempotencyConfig,
    idempotent_function,
)

s3 = boto3.client("s3")
DESTINATION_BUCKET_NAME = os.environ["DESTINATION_BUCKET_NAME"]
IDEMPOTENCY_TABLE = os.environ["IDEMPOTENCY_TABLE"]

persistence_layer = DynamoDBPersistenceLayer(table_name=IDEMPOTENCY_TABLE)
# Use object identity rather than transport metadata so duplicate SQS deliveries
# collapse onto the same logical move operation.
idempotency_config = IdempotencyConfig(
    event_key_jmespath='["operation", "source_bucket_name", "source_key", "source_version_id", "destination_bucket_name"]'
)


def iter_s3_records(event):
    for record in event["Records"]:
        if "body" not in record:
            yield record
            continue

        payload = json.loads(record["body"])

        for s3_record in payload.get("Records", []):
            yield s3_record


def normalise_record(record):
    object_details = record["s3"]["object"]

    return {
        "operation": "unscanned-to-processing",
        "source_bucket_name": record["s3"]["bucket"]["name"],
        "source_key": unquote_plus(object_details["key"]),
        "source_version_id": object_details.get("versionId"),
        "destination_bucket_name": DESTINATION_BUCKET_NAME,
    }


@idempotent_function(
    data_keyword_argument="operation",
    persistence_store=persistence_layer,
    config=idempotency_config,
    key_prefix="managed-file-transfer/unscanned-to-processing",
)
def process_record(*, operation):
    copy_source = {
        "Bucket": operation["source_bucket_name"],
        "Key": operation["source_key"],
    }

    if operation["source_version_id"]:
        copy_source["VersionId"] = operation["source_version_id"]

    s3.copy_object(
        Bucket=operation["destination_bucket_name"],
        Key=operation["source_key"],
        CopySource=copy_source,
        MetadataDirective="COPY",
        TaggingDirective="COPY",
    )

    return {
        "destination_bucket_name": operation["destination_bucket_name"],
        "source_bucket_name": operation["source_bucket_name"],
        "source_key": operation["source_key"],
        "source_version_id": operation["source_version_id"],
    }


def lambda_handler(event, context):
    idempotency_config.register_lambda_context(context)

    for record in iter_s3_records(event):
        process_record(operation=normalise_record(record))