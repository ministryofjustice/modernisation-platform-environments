import hashlib
import json
import os
from urllib.parse import unquote_plus

import boto3
from aws_lambda_powertools import Logger, Metrics, Tracer
from aws_lambda_powertools.metrics import MetricUnit
from aws_lambda_powertools.utilities.idempotency import (
    DynamoDBPersistenceLayer,
    IdempotencyConfig,
    idempotent_function,
)

SERVICE_NAME = "managed-file-transfer-processing-to-post-scan"
METRICS_NAMESPACE = "IntegrationHubFileTransfer"

s3_client = boto3.client("s3")
BUCKET_NAMES_BY_KEY = json.loads(os.environ["BUCKET_NAMES_BY_KEY"])
DEFAULT_SOURCE_BUCKET_KEY = os.environ["DEFAULT_SOURCE_BUCKET_KEY"]
IDEMPOTENCY_TABLE = os.environ["IDEMPOTENCY_TABLE"]
GUARDDUTY_MALWARE_SCAN_STATUS_TAG = "GuardDutyMalwareScanStatus"
logger = Logger(service=SERVICE_NAME)
metrics = Metrics(namespace=METRICS_NAMESPACE, service=SERVICE_NAME)
tracer = Tracer(service=SERVICE_NAME)
# Keep the truncated hash short enough for readable logs while still providing
# a stable discriminator for same-named objects under different prefixes.
LOG_KEY_PATH_HASH_LENGTH = 12
SCAN_RESULT_STATUS_TO_BUCKET_KEY = {
    "NO_THREATS_FOUND": "clean",
    "THREATS_FOUND": "quarantine",
    "UNSUPPORTED": "investigation",
    "ACCESS_DENIED": "investigation",
    "FAILED": "investigation",
}

persistence_layer = DynamoDBPersistenceLayer(table_name=IDEMPOTENCY_TABLE)
# Use the resolved source and destination buckets so transport-level duplicates
# are treated as the same post-scan file move.
idempotency_config = IdempotencyConfig(
    event_key_jmespath="[source_bucket_name, source_key, source_version_id, destination_bucket_name, delete_source]"
)


def iter_events(event):
    if "Records" not in event:
        yield {"payload": event, "sqs_message_id": None}
        return

    for record in event["Records"]:
        if "body" not in record:
            yield {"payload": record, "sqs_message_id": record.get("messageId")}
            continue

        yield {"payload": json.loads(record["body"]), "sqs_message_id": record.get("messageId")}


def build_event_metadata(payload, sqs_message_id):
    return {
        "event_time": payload.get("time"),
        "eventbridge_detail_type": payload.get("detail-type"),
        "eventbridge_event_id": payload.get("id"),
        "eventbridge_source": payload.get("source"),
        "sqs_message_id": sqs_message_id,
    }


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


def resolve_destination_bucket_key(payload, scan_result_status):
    if payload.get("destination_bucket_key"):
        return payload["destination_bucket_key"]

    return SCAN_RESULT_STATUS_TO_BUCKET_KEY.get(scan_result_status)


def normalise_payload(payload, sqs_message_id):
    metadata = build_event_metadata(payload, sqs_message_id)
    source_bucket_key = payload.get("source_bucket_key", DEFAULT_SOURCE_BUCKET_KEY)
    scan_result_status = get_scan_result_status(payload)
    destination_bucket_key = resolve_destination_bucket_key(payload, scan_result_status)

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
        "destination_bucket_key": destination_bucket_key,
        "source_bucket_name": source_bucket_name,
        "source_key": source_key,
        "source_version_id": version_id,
        "destination_bucket_name": destination_bucket_name,
        "delete_source": as_bool(payload.get("delete_source", False)),
        "scan_result_status": scan_result_status,
        **metadata,
    }


def get_source_tags(operation):
    tagging_kwargs = {
        "Bucket": operation["source_bucket_name"],
        "Key": operation["source_key"],
    }

    if operation["source_version_id"]:
        tagging_kwargs["VersionId"] = operation["source_version_id"]

    tag_set = s3_client.get_object_tagging(**tagging_kwargs).get("TagSet", [])
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

    s3_client.put_object_tagging(**tagging_kwargs)


def get_log_fields(operation, routing_outcome=None):
    source_key = operation["source_key"]

    log_fields = {
        "delete_source": operation["delete_source"],
        "destination_bucket_key": operation.get("destination_bucket_key"),
        "event_time": operation.get("event_time"),
        "eventbridge_detail_type": operation.get("eventbridge_detail_type"),
        "eventbridge_event_id": operation.get("eventbridge_event_id"),
        "eventbridge_source": operation.get("eventbridge_source"),
        "object_key": source_key.rsplit("/", 1)[-1],
        "object_key_path_hash": hashlib.sha256(source_key.encode("utf-8")).hexdigest()[:LOG_KEY_PATH_HASH_LENGTH],
        "operation": operation["operation"],
        "scan_result_status": operation["scan_result_status"],
        "source_bucket_name": operation["source_bucket_name"],
        "source_version_id": operation["source_version_id"],
        "sqs_message_id": operation.get("sqs_message_id"),
        "destination_bucket_name": operation["destination_bucket_name"],
    }

    if routing_outcome is not None:
        log_fields["routing_outcome"] = routing_outcome

    return log_fields


@idempotent_function(
    data_keyword_argument="operation",
    persistence_store=persistence_layer,
    config=idempotency_config,
    key_prefix="managed-file-transfer/processing-to-post-scan",
)
@tracer.capture_method
def process_record(*, operation):
    logger.info("Starting post-scan routing", extra=get_log_fields(operation, routing_outcome="started"))

    copy_source = {
        "Bucket": operation["source_bucket_name"],
        "Key": operation["source_key"],
    }

    if operation["source_version_id"]:
        copy_source["VersionId"] = operation["source_version_id"]

    copy_response = s3_client.copy(
        CopySource=copy_source,
        Bucket=operation["destination_bucket_name"],
        Key=operation["source_key"],
        ExtraArgs={
            "MetadataDirective": "COPY",
            "TaggingDirective": "COPY",
        },
    )
    put_destination_tags(operation, copy_response.get("VersionId"))

    logger.info("Copied S3 object", extra=get_log_fields(operation, routing_outcome="copied"))

    if operation["delete_source"]:
        delete_kwargs = {
            "Bucket": operation["source_bucket_name"],
            "Key": operation["source_key"],
        }

        if operation["source_version_id"]:
            delete_kwargs["VersionId"] = operation["source_version_id"]

        s3_client.delete_object(**delete_kwargs)
        logger.info("Moved S3 object", extra=get_log_fields(operation, routing_outcome="moved"))
    else:
        logger.info("Retained source S3 object", extra=get_log_fields(operation, routing_outcome="copied_only"))

    return {
        "delete_source": operation["delete_source"],
        "destination_bucket_name": operation["destination_bucket_name"],
        "destination_bucket_key": operation.get("destination_bucket_key"),
        "source_bucket_name": operation["source_bucket_name"],
        "source_key": operation["source_key"],
        "source_version_id": operation["source_version_id"],
        "scan_result_status": operation["scan_result_status"],
    }


@logger.inject_lambda_context(clear_state=True, log_event=False)
@tracer.capture_lambda_handler
@metrics.log_metrics(capture_cold_start_metric=True)
def lambda_handler(event, context):
    idempotency_config.register_lambda_context(context)

    for record in iter_events(event):
        operation = None
        payload = record["payload"]
        sqs_message_id = record["sqs_message_id"]

        try:
            operation = normalise_payload(payload, sqs_message_id)
            tracer.put_annotation("route_name", operation["operation"])
            tracer.put_annotation("destination_bucket_key", operation.get("destination_bucket_key") or "direct")
            tracer.put_annotation("scan_result_status", operation["scan_result_status"] or "UNKNOWN")
            process_record(operation=operation)
            metrics.add_metric(name="ObjectsRouted", unit=MetricUnit.Count, value=1)
        except Exception:
            metrics.add_metric(name="RecordProcessingFailures", unit=MetricUnit.Count, value=1)
            logger.exception(
                "Failed to move S3 object",
                extra=get_log_fields(operation, routing_outcome="failed") if operation else build_event_metadata(payload, sqs_message_id),
            )
            raise
