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

SERVICE_NAME = "managed-file-transfer-incoming-to-processing"
METRICS_NAMESPACE = "IntegrationHubFileTransfer"

s3_client = boto3.client("s3")
DESTINATION_BUCKET_NAME = os.environ["DESTINATION_BUCKET_NAME"]
IDEMPOTENCY_TABLE = os.environ["IDEMPOTENCY_TABLE"]
logger = Logger(service=SERVICE_NAME)
metrics = Metrics(namespace=METRICS_NAMESPACE, service=SERVICE_NAME)
tracer = Tracer(service=SERVICE_NAME)
# Keep the truncated hash short enough for readable logs while still providing
# a stable discriminator for same-named objects under different prefixes.
LOG_KEY_PATH_HASH_LENGTH = 12
MAX_OBJECT_SIZE_BYTES = 5_000_000_000

persistence_layer = DynamoDBPersistenceLayer(table_name=IDEMPOTENCY_TABLE)
# Use object identity rather than transport metadata so duplicate SQS deliveries
# collapse onto the same logical move operation.
idempotency_config = IdempotencyConfig(
    event_key_jmespath="[operation, source_bucket_name, source_key, source_version_id, destination_bucket_name]"
)


def iter_records(event):
    if "Records" not in event:
        yield {"payload": event, "sqs_message_id": None}
        return

    for record in event["Records"]:
        if "body" not in record:
            yield {"payload": record, "sqs_message_id": record.get("messageId")}
            continue

        payload = json.loads(record["body"])

        if "Records" in payload:
            for nested_record in payload["Records"]:
                yield {"payload": nested_record, "sqs_message_id": record.get("messageId")}
            continue

        yield {"payload": payload, "sqs_message_id": record.get("messageId")}


def build_event_metadata(payload, sqs_message_id):
    return {
        "event_time": payload.get("time"),
        "eventbridge_detail_type": payload.get("detail-type"),
        "eventbridge_event_id": payload.get("id"),
        "eventbridge_source": payload.get("source"),
        "sqs_message_id": sqs_message_id,
    }


def is_s3_test_event(record):
    return record.get("Service") == "Amazon S3" and record.get("Event") == "s3:TestEvent"


def is_eventbridge_s3_object_created_event(payload):
    return payload.get("source") == "aws.s3" and payload.get("detail-type") == "Object Created"


def normalise_record(record, sqs_message_id):
    metadata = build_event_metadata(record, sqs_message_id)

    if is_eventbridge_s3_object_created_event(record):
        object_details = record["detail"]["object"]
        source_bucket_name = record["detail"]["bucket"]["name"]
        source_key = unquote_plus(object_details["key"])
        source_version_id = object_details.get("version-id") or object_details.get("versionId")
        object_size_bytes = object_details.get("size")
    elif "s3" in record:
        object_details = record["s3"]["object"]
        source_bucket_name = record["s3"]["bucket"]["name"]
        source_key = unquote_plus(object_details["key"])
        source_version_id = object_details.get("versionId")
        object_size_bytes = object_details.get("size")
    else:
        source_bucket_name = record["source_bucket_name"]
        source_key = unquote_plus(record["object_key"])
        source_version_id = record.get("version_id")
        object_size_bytes = record.get("object_size_bytes")

    return {
        "operation": "unscanned-to-processing",
        "destination_bucket_key": "processing",
        "destination_bucket_name": DESTINATION_BUCKET_NAME,
        "object_size_bytes": object_size_bytes,
        "source_bucket_name": source_bucket_name,
        "source_key": source_key,
        "source_version_id": source_version_id,
        **metadata,
    }


def get_log_fields(operation, routing_outcome=None):
    source_key = operation["source_key"]

    log_fields = {
        "destination_bucket_key": operation["destination_bucket_key"],
        "event_time": operation.get("event_time"),
        "eventbridge_detail_type": operation.get("eventbridge_detail_type"),
        "eventbridge_event_id": operation.get("eventbridge_event_id"),
        "eventbridge_source": operation.get("eventbridge_source"),
        "above_5gb": (operation.get("object_size_bytes") or 0) > MAX_OBJECT_SIZE_BYTES,
        "object_key": source_key.rsplit("/", 1)[-1],
        "object_key_path_hash": hashlib.sha256(source_key.encode("utf-8")).hexdigest()[:LOG_KEY_PATH_HASH_LENGTH],
        "object_size_bytes": operation.get("object_size_bytes"),
        "operation": operation["operation"],
        "source_bucket_name": operation["source_bucket_name"],
        "source_version_id": operation["source_version_id"],
        "sqs_message_id": operation.get("sqs_message_id"),
        "destination_bucket_name": operation["destination_bucket_name"],
    }

    if routing_outcome is not None:
        log_fields["routing_outcome"] = routing_outcome

    return log_fields


def get_s3_test_event_log_fields(record, sqs_message_id):
    return {
        "event_name": record.get("Event"),
        "event_service": record.get("Service"),
        "source_bucket_name": record.get("Bucket"),
        "sqs_message_id": sqs_message_id,
    }


@idempotent_function(
    data_keyword_argument="operation",
    persistence_store=persistence_layer,
    config=idempotency_config,
    key_prefix="managed-file-transfer/unscanned-to-processing",
)
@tracer.capture_method
def process_record(*, operation):
    logger.info("Starting S3 object move", extra=get_log_fields(operation, routing_outcome="started"))

    copy_source = {
        "Bucket": operation["source_bucket_name"],
        "Key": operation["source_key"],
    }

    if operation["source_version_id"]:
        copy_source["VersionId"] = operation["source_version_id"]

    s3_client.copy(
        CopySource=copy_source,
        Bucket=operation["destination_bucket_name"],
        Key=operation["source_key"],
        ExtraArgs={
            "MetadataDirective": "COPY",
            "TaggingDirective": "COPY",
        },
    )
    logger.info("Copied S3 object", extra=get_log_fields(operation, routing_outcome="copied"))

    if operation["source_version_id"]:
        s3_client.delete_object(
            Bucket=operation["source_bucket_name"],
            Key=operation["source_key"],
            VersionId=operation["source_version_id"],
        )
    else:
        s3_client.delete_object(
            Bucket=operation["source_bucket_name"],
            Key=operation["source_key"],
        )

    logger.info("Moved S3 object", extra=get_log_fields(operation, routing_outcome="moved"))

    return {
        "destination_bucket_name": operation["destination_bucket_name"],
        "destination_bucket_key": operation["destination_bucket_key"],
        "source_bucket_name": operation["source_bucket_name"],
        "source_key": operation["source_key"],
        "source_version_id": operation["source_version_id"],
    }


@logger.inject_lambda_context(clear_state=True, log_event=False)
@tracer.capture_lambda_handler
@metrics.log_metrics(capture_cold_start_metric=True)
def lambda_handler(event, context):
    idempotency_config.register_lambda_context(context)

    for record in iter_records(event):
        operation = None
        payload = record["payload"]
        sqs_message_id = record["sqs_message_id"]

        try:
            if is_s3_test_event(payload):
                logger.info(
                    "Received S3 notification test event",
                    extra=get_s3_test_event_log_fields(payload, sqs_message_id),
                )
                metrics.add_metric(name="IgnoredTestEvents", unit=MetricUnit.Count, value=1)
                continue

            operation = normalise_record(payload, sqs_message_id)
            tracer.put_annotation("route_name", operation["operation"])
            tracer.put_annotation("destination_bucket_key", operation["destination_bucket_key"])
            process_record(operation=operation)
            metrics.add_metric(name="ObjectsMoved", unit=MetricUnit.Count, value=1)
        except Exception:
            metrics.add_metric(name="RecordProcessingFailures", unit=MetricUnit.Count, value=1)
            logger.exception(
                "Failed to move S3 object",
                extra=get_log_fields(operation, routing_outcome="failed") if operation else build_event_metadata(payload, sqs_message_id),
            )
            raise
