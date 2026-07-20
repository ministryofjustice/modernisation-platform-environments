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
dynamodb = boto3.client("dynamodb")
logger = Logger(service="integration-hub-file-transfer-file-scan-result-recorded-adapter")
persistence_layer = DynamoDBPersistenceLayer(
    table_name=os.environ["IDEMPOTENCY_TABLE"]
)
idempotency_config = IdempotencyConfig(
    event_key_jmespath="idempotencyKey",
    payload_validation_jmespath="[object, scanResultStatus]",
    raise_on_no_idempotency_key=True,
    expires_after_seconds=int(os.environ["IDEMPOTENCY_EXPIRY_SECONDS"]),
)

_STATUS_BY_SCAN_STATUS = {
    "COMPLETED": {"NO_THREATS_FOUND", "THREATS_FOUND"},
    "SKIPPED": {"UNSUPPORTED", "ACCESS_DENIED"},
    "FAILED": {"FAILED"},
}
_COMPLETE_WORKFLOW_STATUSES = {"PUBLISHED", "COMPLETED"}


def _required(value, field_name):
    if value is None or value == "":
        raise ValueError(f"Missing required field: {field_name}")
    return value


def _event_time(event):
    value = _required(event.get("time"), "time")
    try:
        return datetime.fromisoformat(value.replace("Z", "+00:00"))
    except ValueError as error:
        raise ValueError("Event time must be an ISO 8601 timestamp") from error


def _validate_event(event):
    if event.get("source") != "aws.guardduty":
        raise ValueError("Event source must be aws.guardduty")
    if event.get("detail-type") != "GuardDuty Malware Protection Object Scan Result":
        raise ValueError(
            "Event detail-type must be GuardDuty Malware Protection Object Scan Result"
        )
    if event.get("account") != os.environ["AWS_ACCOUNT_ID"]:
        raise ValueError("Event account does not match the configured account")
    if os.environ["MALWARE_PROTECTION_PLAN_ARN"] not in event.get("resources", []):
        raise ValueError("Event does not reference the configured malware protection plan")

    detail = _required(event.get("detail"), "detail")
    if detail.get("schemaVersion") != "1.0":
        raise ValueError("Event detail.schemaVersion must be 1.0")
    if detail.get("resourceType") != "S3_OBJECT":
        raise ValueError("Event detail.resourceType must be S3_OBJECT")

    object_detail = _required(detail.get("s3ObjectDetails"), "detail.s3ObjectDetails")
    bucket_name = _required(object_detail.get("bucketName"), "detail.s3ObjectDetails.bucketName")
    if bucket_name != os.environ["PROCESSING_BUCKET_NAME"]:
        raise ValueError("Event bucket does not match the configured processing bucket")
    object_key = _required(object_detail.get("objectKey"), "detail.s3ObjectDetails.objectKey")
    version_id = _required(object_detail.get("versionId"), "detail.s3ObjectDetails.versionId")

    scan_status = _required(detail.get("scanStatus"), "detail.scanStatus")
    result_detail = _required(detail.get("scanResultDetails"), "detail.scanResultDetails")
    scan_result_status = _required(
        result_detail.get("scanResultStatus"), "detail.scanResultDetails.scanResultStatus"
    )
    valid_results = _STATUS_BY_SCAN_STATUS.get(scan_status)
    if valid_results is None or scan_result_status not in valid_results:
        raise ValueError(
            "Event scanStatus and scanResultStatus do not describe a terminal GuardDuty outcome"
        )

    return {
        "bucket": bucket_name,
        "key": object_key,
        "versionId": version_id,
        "scanResultStatus": scan_result_status,
        "recordedAt": _event_time(event),
        "sourceEventId": _required(event.get("id"), "id"),
    }


def _attribute(item, name, attribute_type="S"):
    value = item.get(name, {}).get(attribute_type)
    return _required(value, f"workflow record {name}")


def _workflow_record(processing_object_lookup_key):
    response = dynamodb.query(
        TableName=os.environ["WORKFLOW_IDEMPOTENCY_TABLE"],
        IndexName=os.environ["PROCESSING_OBJECT_LOOKUP_KEY_INDEX_NAME"],
        KeyConditionExpression=(
            "processing_object_lookup_key = :processing_object_lookup_key"
        ),
        ExpressionAttributeValues={
            ":processing_object_lookup_key": {"S": processing_object_lookup_key}
        },
        Limit=2,
    )
    items = response.get("Items", [])
    if len(items) != 1:
        raise RuntimeError(
            f"Expected one workflow record for processing object {processing_object_lookup_key}, found {len(items)}"
        )

    item = items[0]
    status = _attribute(item, "status")
    if status not in _COMPLETE_WORKFLOW_STATUSES:
        raise RuntimeError(
            f"Workflow record for processing object {processing_object_lookup_key} is not published"
        )

    return {
        "fileId": _attribute(item, "file_id"),
        "correlationId": _attribute(item, "correlation_id"),
        "causationId": _attribute(item, "staged_event_id"),
        "bucket": _attribute(item, "processing_bucket"),
        "key": _attribute(item, "processing_key"),
        "versionId": _attribute(item, "processing_version_id"),
        "sizeBytes": int(_attribute(item, "incoming_size_bytes", "N")),
    }


def _build_operation(scan, workflow):
    idempotency_key = f"scan:{workflow['correlationId']}:{workflow['versionId']}"
    return {
        "idempotencyKey": idempotency_key,
        "sourceEventId": scan["sourceEventId"],
        "recordedAt": scan["recordedAt"].isoformat().replace("+00:00", "Z"),
        "scanResultStatus": scan["scanResultStatus"],
        "object": {
            "bucket": workflow["bucket"],
            "key": workflow["key"],
            "versionId": workflow["versionId"],
            "sizeBytes": workflow["sizeBytes"],
        },
        "fileId": workflow["fileId"],
        "correlationId": workflow["correlationId"],
        "causationId": workflow["causationId"],
    }


def _build_detail(operation):
    return {
        "metadata": {
            "correlationId": operation["correlationId"],
            "causationId": operation["causationId"],
            "idempotencyKey": operation["idempotencyKey"],
        },
        "data": {
            "fileId": operation["fileId"],
            "object": operation["object"],
            "scanResultStatus": operation["scanResultStatus"],
            "recordedAt": operation["recordedAt"],
        },
    }


@idempotent(
    persistence_store=persistence_layer,
    config=idempotency_config,
    key_prefix="managed-file-transfer/file-scan-result-recorded-adapter",
)
def _publish(operation):
    response = eventbridge.put_events(
        Entries=[
            {
                "Source": "uk.gov.justice.service.managed-file-transfer",
                "DetailType": "FileScanResultRecorded.v1",
                "Detail": json.dumps(_build_detail(operation), separators=(",", ":")),
                "EventBusName": os.environ["EVENT_BUS_ARN"],
                "Resources": [
                    f"arn:aws:s3:::{operation['object']['bucket']}/{operation['object']['key']}"
                ],
                "Time": datetime.fromisoformat(
                    operation["recordedAt"].replace("Z", "+00:00")
                ),
            }
        ]
    )
    if response.get("FailedEntryCount", 0) > 0:
        raise RuntimeError(
            f"Failed to publish FileScanResultRecorded.v1 event: {response['Entries']}"
        )

    destination_event_id = response["Entries"][0]["EventId"]
    logger.info(
        "Published FileScanResultRecorded.v1 event",
        extra={
            "destination_event_id": destination_event_id,
            "source_event_id": operation["sourceEventId"],
            "processing_object_lookup_key": (
                f"{operation['object']['bucket']}:{operation['object']['key']}:"
                f"{operation['object']['versionId']}"
            ),
        },
    )
    return {"eventId": destination_event_id}


@logger.inject_lambda_context(clear_state=True, log_event=False)
def lambda_handler(event, _context):
    scan = _validate_event(event)
    processing_object_lookup_key = (
        f"{scan['bucket']}:{scan['key']}:{scan['versionId']}"
    )
    workflow = _workflow_record(processing_object_lookup_key)
    return _publish(_build_operation(scan, workflow))
