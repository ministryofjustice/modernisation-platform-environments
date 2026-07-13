import json
import os
from datetime import datetime

import boto3
from aws_lambda_powertools import Logger
from aws_lambda_powertools.utilities.idempotency import (
    DynamoDBPersistenceLayer,
    IdempotencyConfig,
    idempotent,
)


eventbridge = boto3.client("events")
logger = Logger(service="integration-hub-file-transfer-file-received-adapter")
persistence_layer = DynamoDBPersistenceLayer(
    table_name=os.environ["IDEMPOTENCY_TABLE"]
)
idempotency_config = IdempotencyConfig(
    event_key_jmespath="id",
    payload_validation_jmespath='[source, "detail-type", detail]',
    raise_on_no_idempotency_key=True,
    expires_after_seconds=int(os.environ["IDEMPOTENCY_EXPIRY_SECONDS"]),
)


def _required(value, field_name):
    if value is None or value == "":
        raise ValueError(f"Missing required field: {field_name}")
    return value


def _build_detail(event):
    if event.get("source") != "aws.s3":
        raise ValueError("Event source must be aws.s3")
    if event.get("detail-type") != "Object Created":
        raise ValueError("Event detail-type must be Object Created")

    event_id = _required(event.get("id"), "id")
    detail = _required(event.get("detail"), "detail")
    bucket = _required(detail.get("bucket"), "detail.bucket")
    bucket_name = _required(bucket.get("name"), "detail.bucket.name")
    if bucket_name != os.environ["INCOMING_BUCKET_NAME"]:
        raise ValueError("Event bucket does not match the configured incoming bucket")

    object_detail = _required(detail.get("object"), "detail.object")
    object_key = _required(object_detail.get("key"), "detail.object.key")
    version_id = _required(
        object_detail.get("version-id"), "detail.object.version-id"
    )
    size_bytes = _required(object_detail.get("size"), "detail.object.size")

    return {
        "metadata": {
            "correlationId": event_id,
            "idempotencyKey": f"{bucket_name}:{object_key}:{version_id}",
        },
        "data": {
            "fileId": event_id,
            "object": {
                "bucket": bucket_name,
                "key": object_key,
                "versionId": version_id,
                "sizeBytes": size_bytes,
            },
            "provenance": {"ingressMethod": "s3"},
        },
    }


def _event_time(event):
    value = _required(event.get("time"), "time")

    try:
        return datetime.fromisoformat(value.replace("Z", "+00:00"))
    except ValueError as error:
        raise ValueError("Event time must be an ISO 8601 timestamp") from error


@logger.inject_lambda_context(clear_state=True, log_event=False)
@idempotent(
    persistence_store=persistence_layer,
    config=idempotency_config,
    key_prefix="managed-file-transfer/file-received-adapter",
)
def lambda_handler(event, _context):
    source_event_id = event.get("id")

    try:
        response = eventbridge.put_events(
            Entries=[
                {
                    "Source": "uk.gov.justice.service.managed-file-transfer",
                    "DetailType": "FileReceived.v1",
                    "Detail": json.dumps(_build_detail(event), separators=(",", ":")),
                    "EventBusName": os.environ["EVENT_BUS_ARN"],
                    "Resources": [
                        f"arn:aws:s3:::{event['detail']['bucket']['name']}/{event['detail']['object']['key']}"
                    ],
                    "Time": _event_time(event),
                }
            ]
        )

        if response.get("FailedEntryCount", 0) > 0:
            raise RuntimeError(
                f"Failed to publish FileReceived.v1 event: {response['Entries']}"
            )

        destination_event_id = response["Entries"][0]["EventId"]
        logger.info(
            "Published FileReceived.v1 event",
            extra={
                "destination_event_id": destination_event_id,
                "source_event_id": source_event_id,
            },
        )
        return {"eventId": destination_event_id}
    except Exception:
        logger.exception(
            "Failed to transform or publish S3 Object Created event",
            extra={"source_event_id": source_event_id},
        )
        raise