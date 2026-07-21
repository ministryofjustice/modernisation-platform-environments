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
s3 = boto3.client("s3")
logger = Logger(service="integration-hub-file-transfer-file-scan-result-recorded-adapter")
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


def _event_time(event):
    value = _required(event.get("time"), "time")
    try:
        return datetime.fromisoformat(value.replace("Z", "+00:00"))
    except ValueError as error:
        raise ValueError("Event time must be an ISO 8601 timestamp") from error


def _scan(event):
    detail = _required(event.get("detail"), "detail")
    object_detail = _required(detail.get("s3ObjectDetails"), "detail.s3ObjectDetails")
    result_detail = _required(detail.get("scanResultDetails"), "detail.scanResultDetails")

    return {
        "bucket": _required(
            object_detail.get("bucketName"), "detail.s3ObjectDetails.bucketName"
        ),
        "key": _required(
            object_detail.get("objectKey"), "detail.s3ObjectDetails.objectKey"
        ),
        "versionId": _required(
            object_detail.get("versionId"), "detail.s3ObjectDetails.versionId"
        ),
        "scanResultStatus": _required(
            result_detail.get("scanResultStatus"),
            "detail.scanResultDetails.scanResultStatus",
        ),
        "statusReasons": result_detail.get("statusReasons"),
    }


def _attribute(item, name, attribute_type="S"):
    value = item.get(name, {}).get(attribute_type)
    return _required(value, f"workflow record {name}")


def _tag_status(scan):
    response = s3.get_object_tagging(
        Bucket=scan["bucket"],
        Key=scan["key"],
        VersionId=scan["versionId"],
        ExpectedBucketOwner=os.environ["AWS_ACCOUNT_ID"],
    )
    tag_status = next(
        (
            tag["Value"]
            for tag in response.get("TagSet", [])
            if tag["Key"] == "GuardDutyMalwareScanStatus"
        ),
        None,
    )
    return tag_status if tag_status == scan["scanResultStatus"] else "MISMATCH"


def _workflow_record(scan):
    response = s3.head_object(
        Bucket=scan["bucket"],
        Key=scan["key"],
        VersionId=scan["versionId"],
        ExpectedBucketOwner=os.environ["AWS_ACCOUNT_ID"],
    )
    correlation_id = _required(
        response.get("Metadata", {}).get("mft-correlation-id"),
        "processing object metadata mft-correlation-id",
    )
    response = dynamodb.get_item(
        TableName=os.environ["WORKFLOW_IDEMPOTENCY_TABLE"],
        Key={
            "concurrencyId": {"S": correlation_id},
            "operation": {"S": "STAGE"},
        },
        ConsistentRead=True,
    )
    item = response.get("Item")
    if not item:
        raise RuntimeError("No staging workflow record exists for the processing object")

    status = _attribute(item, "status")
    if status != "COMPLETED":
        raise RuntimeError("The staging workflow record is not completed")

    return {
        "fileId": _attribute(item, "file_id"),
        "correlationId": correlation_id,
        "causationId": _attribute(item, "staged_event_id"),
        "object": {
            "bucket": _attribute(item, "processing_bucket"),
            "key": _attribute(item, "processing_key"),
            "versionId": _attribute(item, "processing_version_id"),
            "sizeBytes": int(_attribute(item, "incoming_size_bytes", "N")),
        },
    }


def _build_detail(scan, workflow, tag_status, recorded_at):
    data = {
        "fileId": workflow["fileId"],
        "object": workflow["object"],
        "scanResultStatus": scan["scanResultStatus"],
        "tagStatus": tag_status,
        "recordedAt": recorded_at.isoformat().replace("+00:00", "Z"),
    }
    if scan["statusReasons"]:
        data["statusReasons"] = scan["statusReasons"]

    return {
        "metadata": {
            "correlationId": workflow["correlationId"],
            "causationId": workflow["causationId"],
            "idempotencyKey": (
                f"scan:{workflow['correlationId']}:"
                f"{workflow['object']['versionId']}"
            ),
        },
        "data": data,
    }


@logger.inject_lambda_context(clear_state=True, log_event=False)
@idempotent(
    persistence_store=persistence_layer,
    config=idempotency_config,
    key_prefix="managed-file-transfer/file-scan-result-recorded-adapter",
)
def lambda_handler(event, _context):
    scan = _scan(event)
    workflow = _workflow_record(scan)
    tag_status = _tag_status(scan)
    recorded_at = _event_time(event)
    response = eventbridge.put_events(
        Entries=[
            {
                "Source": "uk.gov.justice.service.managed-file-transfer",
                "DetailType": "FileScanResultRecorded.v1",
                "Detail": json.dumps(
                    _build_detail(scan, workflow, tag_status, recorded_at),
                    separators=(",", ":"),
                ),
                "EventBusName": os.environ["EVENT_BUS_ARN"],
                "Resources": [
                    f"arn:aws:s3:::{workflow['object']['bucket']}/{workflow['object']['key']}"
                ],
                "Time": recorded_at,
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
            "source_event_id": event.get("id"),
            "correlation_id": workflow["correlationId"],
        },
    )
    return {"eventId": destination_event_id}
