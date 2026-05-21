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
SOURCE_BUCKET_NAME = os.getenv("SOURCE_BUCKET_NAME")
logger = Logger(service="managed-file-transfer-unscanned-to-processing")

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


def normalise_transfer_record(record):
    if record.get("source") != "aws.transfer":
        raise KeyError("source")

    if record.get("detail-type") != "SFTP Server File Upload Completed":
        raise ValueError(f"Unsupported Transfer event type: {record.get('detail-type')}")

    detail = record["detail"]
    file_path = detail["file-path"].lstrip("/")
    bucket_name, separator, source_key = file_path.partition("/")

    if not separator or not bucket_name or not source_key:
        raise ValueError(f"Unsupported Transfer file path: {detail['file-path']}")

    username = detail["username"]
    expected_prefix = f"{username}/"
    if not source_key.startswith(expected_prefix):
        raise ValueError(
            f"Transfer file path is outside the user's home directory: {detail['file-path']}"
        )

    if SOURCE_BUCKET_NAME and bucket_name != SOURCE_BUCKET_NAME:
        raise ValueError(
            f"Transfer file path bucket {bucket_name} did not match expected source bucket {SOURCE_BUCKET_NAME}"
        )

    return {
        "operation": "unscanned-to-processing",
        "source_bucket_name": bucket_name,
        "source_key": source_key,
        "source_version_id": None,
        "destination_bucket_name": DESTINATION_BUCKET_NAME,
    }


def normalise_record(record):
    if "detail" in record and "detail-type" in record:
        return normalise_transfer_record(record)

    object_details = record["s3"]["object"]

    return {
        "operation": "unscanned-to-processing",
        "source_bucket_name": record["s3"]["bucket"]["name"],
        "source_key": unquote_plus(object_details["key"]),
        "source_version_id": object_details.get("versionId"),
        "destination_bucket_name": DESTINATION_BUCKET_NAME,
    }


def get_log_fields(operation):
    return {
        "object_key": operation["source_key"],
        "source_bucket_name": operation["source_bucket_name"],
        "destination_bucket_name": operation["destination_bucket_name"],
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

    s3.copy_object(
        Bucket=operation["destination_bucket_name"],
        Key=operation["source_key"],
        CopySource=copy_source,
        MetadataDirective="COPY",
        TaggingDirective="COPY",
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
            operation = normalise_record(record)
            process_record(operation=operation)
        except Exception:
            logger.exception(
                "Failed to move S3 object",
                extra=get_log_fields(operation) if operation else {},
            )
            raise