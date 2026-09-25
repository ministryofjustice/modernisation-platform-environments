import json
from collections.abc import Mapping
from datetime import datetime, timezone
from typing import Any

from mft_writer.diagnostics import _sanitised_error_text
from mft_writer.errors import AwsResponseError
from mft_writer.events import EVENT_SOURCE

COMPLETED_DETAIL_TYPE = "FileActionExecutionCompleted.v1"


def build_completion_detail(
    item: Mapping[str, Any], status: str, *, completed_at: str | None = None
) -> dict[str, Any]:
    data: dict[str, Any] = {
        "fileId": item["fileId"],
        "object": {
            "bucket": item["sourceBucket"],
            "key": item["sourceKey"],
            "versionId": item["sourceVersionId"],
            "sizeBytes": int(item["sourceSizeBytes"]),
        },
        "actionDefinitionId": item["actionDefinitionId"],
        "actionExecutionId": item["actionExecutionId"],
        "status": status,
        "completedAt": completed_at or datetime.now(timezone.utc).isoformat().replace("+00:00", "Z"),
    }
    if status == "succeeded":
        result = {
            "destinationBucket": item["destinationBucket"],
            "destinationKey": item["destinationKey"],
        }
        if item.get("destinationVersionId"):
            result["destinationVersionId"] = item["destinationVersionId"]
        data["result"] = result
    else:
        data["failure"] = {
            "code": item.get("failureCode", "DeliveryAttemptsExhausted"),
            "message": item.get("failureMessage", "Delivery attempts exhausted."),
            "retryable": False,
        }
    return {
        "metadata": {
            "correlationId": item["correlationId"],
            "causationId": item["requestEventId"],
            "idempotencyKey": f"action-complete:{item['actionExecutionId']}",
        },
        "data": data,
    }


def publish_completion(eventbridge: Any, event_bus_name: str, item: Mapping[str, Any], status: str) -> None:
    detail = build_completion_detail(
        item,
        status,
        completed_at=item.get("completedAt"),
    )
    response = eventbridge.put_events(
        Entries=[
            {
                "EventBusName": event_bus_name,
                "Source": EVENT_SOURCE,
                "DetailType": COMPLETED_DETAIL_TYPE,
                "Detail": json.dumps(detail, separators=(",", ":")),
            }
        ]
    )
    entries = response.get("Entries", [])
    failed_count = int(response.get("FailedEntryCount", 0))
    if failed_count or len(entries) != 1 or entries[0].get("ErrorCode"):
        entry = entries[0] if entries else {}
        metadata = response.get("ResponseMetadata", {})
        fields = {
            "awsErrorCode": entry.get("ErrorCode", "EventBridgeRejected"),
            "awsErrorMessage": _sanitised_error_text(entry.get("ErrorMessage")),
            "awsRequestId": metadata.get("RequestId"),
            "httpStatusCode": metadata.get("HTTPStatusCode"),
            "retryCount": metadata.get("RetryAttempts"),
            "retryable": entry.get("ErrorCode") in {"InternalFailure", "ThrottlingException"},
        }
        raise AwsResponseError("EventBridge rejected the completion event", fields)