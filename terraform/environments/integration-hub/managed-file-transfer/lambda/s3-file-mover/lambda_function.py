import hashlib
import json
import os
from urllib.parse import unquote_plus

import boto3
from aws_lambda_powertools import Logger
from aws_lambda_powertools.utilities.idempotency import (
    DynamoDBPersistenceLayer,
    IdempotencyConfig,
    idempotent_function,
)

s3 = boto3.client("s3")
DESTINATION_BUCKET_NAME = os.environ["DESTINATION_BUCKET_NAME"]
IDEMPOTENCY_TABLE = os.environ["IDEMPOTENCY_TABLE"]
logger = Logger(service="managed-file-transfer-unscanned-to-processing")
# Keep the truncated hash short enough for readable logs while still providing
# a stable discriminator for same-named objects under different prefixes.
LOG_KEY_PATH_HASH_LENGTH = 12

persistence_layer = DynamoDBPersistenceLayer(table_name=IDEMPOTENCY_TABLE)
# Use object identity rather than transport metadata so duplicate SQS deliveries
# collapse onto the same logical move operation.
idempotency_config = IdempotencyConfig(
    event_key_jmespath='["operation", "source_bucket_name", "source_key", "source_version_id", "destination_bucket_name"]'
)


def iter_records(event):
    if "Records" not in event:
        yield event
        return

    for record in event["Records"]:
        if "body" not in record:
            yield record
            continue

        payload = json.loads(record["body"])

        if "Records" in payload:
            for nested_record in payload["Records"]:
                yield nested_record
            continue

        yield payload


def is_s3_test_event(record):
    return record.get("Service") == "Amazon S3" and record.get("Event") == "s3:TestEvent"


def normalise_record(record):
    object_details = record["s3"]["object"]

    return {
        "operation": "unscanned-to-processing",
        "source_bucket_name": record["s3"]["bucket"]["name"],
        "source_key": unquote_plus(object_details["key"]),
        "source_version_id": object_details.get("versionId"),
        "destination_bucket_name": DESTINATION_BUCKET_NAME,
    }


def get_log_fields(operation):
    source_key = operation["source_key"]

    return {
        "object_key": source_key.rsplit("/", 1)[-1],
        "object_key_path_hash": hashlib.sha256(source_key.encode("utf-8")).hexdigest()[:LOG_KEY_PATH_HASH_LENGTH],
        "source_bucket_name": operation["source_bucket_name"],
        "destination_bucket_name": operation["destination_bucket_name"],
    }


def get_copy_extra_args(operation):
    head_object_kwargs = {
        "Bucket": operation["source_bucket_name"],
        "Key": operation["source_key"],
    }

    if operation["source_version_id"]:
        head_object_kwargs["VersionId"] = operation["source_version_id"]

    source_object = s3.head_object(**head_object_kwargs)
    extra_args = {
        "MetadataDirective": "REPLACE",
        "Metadata": source_object.get("Metadata", {}),
        "TaggingDirective": "COPY",
    }

    if source_object.get("ContentType"):
        extra_args["ContentType"] = source_object["ContentType"]

    return extra_args


def get_s3_test_event_log_fields(record):
    return {
        "event_name": record.get("Event"),
        "event_service": record.get("Service"),
        "source_bucket_name": record.get("Bucket"),
    }


@idempotent_function(
    data_keyword_argument="operation",
    persistence_store=persistence_layer,
    config=idempotency_config,
    key_prefix="managed-file-transfer/unscanned-to-processing",
)
def process_record(*, operation):
    logger.info("Moving S3 object", extra=get_log_fields(operation))

    copy_source = {
        "Bucket": operation["source_bucket_name"],
        "Key": operation["source_key"],
    }

    if operation["source_version_id"]:
        copy_source["VersionId"] = operation["source_version_id"]

    s3.copy(
        CopySource=copy_source,
        Bucket=operation["destination_bucket_name"],
        Key=operation["source_key"],
        ExtraArgs=get_copy_extra_args(operation),
    )

    if operation["source_version_id"]:
        s3.delete_object(
            Bucket=operation["source_bucket_name"],
            Key=operation["source_key"],
            VersionId=operation["source_version_id"],
        )
    else:
        s3.delete_object(
            Bucket=operation["source_bucket_name"],
            Key=operation["source_key"],
        )

    logger.info("Moved S3 object", extra=get_log_fields(operation))

    return {
        "destination_bucket_name": operation["destination_bucket_name"],
        "source_bucket_name": operation["source_bucket_name"],
        "source_key": operation["source_key"],
        "source_version_id": operation["source_version_id"],
    }


@logger.inject_lambda_context(clear_state=True, log_event=False)
def lambda_handler(event, context):
    idempotency_config.register_lambda_context(context)

    for record in iter_records(event):
        operation = None

        try:
            if is_s3_test_event(record):
                logger.info(
                    "Received S3 notification test event",
                    extra=get_s3_test_event_log_fields(record),
                )
                continue

            operation = normalise_record(record)
            process_record(operation=operation)
        except Exception:
            logger.exception(
                "Failed to move S3 object",
                extra=get_log_fields(operation) if operation else {},
            )
            raise
