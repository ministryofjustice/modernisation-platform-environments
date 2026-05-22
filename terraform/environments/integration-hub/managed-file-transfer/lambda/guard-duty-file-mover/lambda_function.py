import json
import os
import hashlib
from urllib.parse import unquote_plus

import boto3
from aws_lambda_powertools import Logger
from aws_lambda_powertools.utilities.idempotency import (
    DynamoDBPersistenceLayer,
    IdempotencyConfig,
    idempotent_function,
)

s3 = boto3.client("s3")
BUCKET_NAMES_BY_KEY = json.loads(os.environ["BUCKET_NAMES_BY_KEY"])
DEFAULT_SOURCE_BUCKET_KEY = os.environ["DEFAULT_SOURCE_BUCKET_KEY"]
IDEMPOTENCY_TABLE = os.environ["IDEMPOTENCY_TABLE"]
GUARDDUTY_MALWARE_SCAN_STATUS_TAG = "GuardDutyMalwareScanStatus"
logger = Logger(service="managed-file-transfer-processing-to-post-scan")
# Keep the truncated hash short enough for readable logs while still providing
# a stable discriminator for same-named objects under different prefixes.
LOG_KEY_PATH_HASH_LENGTH = 12

persistence_layer = DynamoDBPersistenceLayer(table_name=IDEMPOTENCY_TABLE)
# Use the resolved source and destination buckets so transport-level duplicates
# are treated as the same post-scan file move.
idempotency_config = IdempotencyConfig(
    event_key_jmespath="[source_bucket_name, source_key, source_version_id, destination_bucket_name, delete_source]"
)


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


def get_scan_result_status(event):
    if "detail" in event and "scanResultDetails" in event["detail"]:
        return event["detail"]["scanResultDetails"].get("scanResultStatus")

    return event.get("scan_result_status")


def as_bool(value):
    if isinstance(value, bool):
        return value

    return str(value).lower() == "true"


def normalise_payload(payload):
    source_bucket_key = payload.get("source_bucket_key", DEFAULT_SOURCE_BUCKET_KEY)
    destination_bucket_key = payload.get("destination_bucket_key")

    if destination_bucket_key is None and "destination_bucket_name" not in payload and "destination_bucket" not in payload:
        raise KeyError("destination_bucket_key")

    source_bucket_name = payload.get(
        "source_bucket_name",
        payload.get("source_bucket", BUCKET_NAMES_BY_KEY[source_bucket_key]),
    )
    destination_bucket_name = payload.get(
        "destination_bucket_name",
        payload.get("destination_bucket", BUCKET_NAMES_BY_KEY[destination_bucket_key]),
    )
    source_key, version_id = get_object_details(payload)

    return {
        "operation": "processing-to-post-scan",
        "source_bucket_name": source_bucket_name,
        "source_key": source_key,
        "source_version_id": version_id,
        "destination_bucket_name": destination_bucket_name,
        "delete_source": as_bool(payload.get("delete_source", False)),
        "scan_result_status": get_scan_result_status(payload),
    }


def get_source_tags(operation):
    tagging_kwargs = {
        "Bucket": operation["source_bucket_name"],
        "Key": operation["source_key"],
    }

    if operation["source_version_id"]:
        tagging_kwargs["VersionId"] = operation["source_version_id"]

    tag_set = s3.get_object_tagging(**tagging_kwargs).get("TagSet", [])
    return {tag["Key"]: tag["Value"] for tag in tag_set}


def put_destination_tags(operation, destination_version_id):
    tags = get_source_tags(operation)

    if operation["scan_result_status"]:
        tags[GUARDDUTY_MALWARE_SCAN_STATUS_TAG] = operation["scan_result_status"]

    tagging_kwargs = {
        "Bucket": operation["destination_bucket_name"],
        "Key": operation["source_key"],
        "Tagging": {
            "TagSet": [
                {"Key": key, "Value": value}
                for key, value in sorted(tags.items())
            ]
        },
    }

    if destination_version_id:
        tagging_kwargs["VersionId"] = destination_version_id

    s3.put_object_tagging(**tagging_kwargs)


def get_log_fields(operation):
    source_key = operation["source_key"]

    return {
        "object_key": source_key.rsplit("/", 1)[-1],
        "object_key_path_hash": hashlib.sha256(source_key.encode("utf-8")).hexdigest()[:LOG_KEY_PATH_HASH_LENGTH],
        "source_bucket_name": operation["source_bucket_name"],
        "destination_bucket_name": operation["destination_bucket_name"],
    }


@idempotent_function(
    data_keyword_argument="operation",
    persistence_store=persistence_layer,
    config=idempotency_config,
    key_prefix="managed-file-transfer/processing-to-post-scan",
)
def process_record(*, operation):
    logger.info("Moving S3 object", extra=get_log_fields(operation))

    copy_source = {
        "Bucket": operation["source_bucket_name"],
        "Key": operation["source_key"],
    }

    if operation["source_version_id"]:
        copy_source["VersionId"] = operation["source_version_id"]

    copy_response = s3.copy_object(
        Bucket=operation["destination_bucket_name"],
        Key=operation["source_key"],
        CopySource=copy_source,
        MetadataDirective="COPY",
        TaggingDirective="COPY",
    )
    put_destination_tags(operation, copy_response.get("VersionId"))

    logger.info("Moved S3 object", extra=get_log_fields(operation))

    if operation["delete_source"]:
        delete_kwargs = {
            "Bucket": operation["source_bucket_name"],
            "Key": operation["source_key"],
        }

        if operation["source_version_id"]:
            delete_kwargs["VersionId"] = operation["source_version_id"]

        s3.delete_object(**delete_kwargs)

    return {
        "delete_source": operation["delete_source"],
        "destination_bucket_name": operation["destination_bucket_name"],
        "source_bucket_name": operation["source_bucket_name"],
        "source_key": operation["source_key"],
        "source_version_id": operation["source_version_id"],
        "scan_result_status": operation["scan_result_status"],
    }


@logger.inject_lambda_context(clear_state=True, log_event=False)
def lambda_handler(event, context):
    idempotency_config.register_lambda_context(context)

    for payload in iter_events(event):
        operation = None

        try:
            operation = normalise_payload(payload)
            process_record(operation=operation)
        except Exception:
            logger.exception(
                "Failed to move S3 object",
                extra=get_log_fields(operation) if operation else {},
            )
            raise