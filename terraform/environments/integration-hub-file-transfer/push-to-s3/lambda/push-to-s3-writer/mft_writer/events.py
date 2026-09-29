import json
import re
import uuid
from collections.abc import Mapping
from datetime import datetime
from typing import Any

from mft_writer.errors import InvalidMessage

SUPPORTED_REGION = "eu-west-2"
EVENT_SOURCE = "uk.gov.justice.service.managed-file-transfer"
REQUESTED_DETAIL_TYPE = "FileActionExecutionRequested.v1"


def json_object(value: str, field: str) -> dict[str, Any]:
    try:
        decoded = json.loads(value)
    except (TypeError, json.JSONDecodeError) as error:
        raise InvalidMessage(f"{field} must contain a JSON object") from error
    if not isinstance(decoded, dict):
        raise InvalidMessage(f"{field} must contain a JSON object")
    return decoded


def unwrap_event(value: Mapping[str, Any] | str) -> dict[str, Any]:
    """Decode direct EventBridge events and the SNS notification wrapper."""
    current: Any = value
    for _ in range(4):
        if isinstance(current, str):
            current = json_object(current, "message")
            continue
        if not isinstance(current, Mapping):
            raise InvalidMessage("event must be a JSON object")
        if current.get("Type") == "Notification":
            message = current.get("Message")
            if not isinstance(message, str):
                raise InvalidMessage("SNS notification must contain a string Message")
            current = message
            continue
        return dict(current)
    raise InvalidMessage("event envelope nesting is invalid")


def extract_requested_action(
    value: Mapping[str, Any] | str, action_name: str
) -> dict[str, Any]:
    event = unwrap_event(value)
    if set(event) - {
        "version",
        "id",
        "detail-type",
        "source",
        "account",
        "time",
        "region",
        "resources",
        "replay-name",
        "detail",
    }:
        raise InvalidMessage("event contains unsupported fields")
    if event.get("version") != "0":
        raise InvalidMessage("event version is not supported")
    if event.get("detail-type") != REQUESTED_DETAIL_TYPE:
        raise InvalidMessage("event detail-type is not supported")
    if event.get("source") != EVENT_SOURCE:
        raise InvalidMessage("event source is not supported")
    if not isinstance(event.get("account"), str) or not re.fullmatch(r"[0-9]{12}", event["account"]):
        raise InvalidMessage("event account is invalid")
    if event.get("region") != SUPPORTED_REGION:
        raise InvalidMessage("event region is not supported")
    if not isinstance(event.get("time"), str):
        raise InvalidMessage("event time is invalid")
    try:
        event_time = datetime.fromisoformat(event["time"].replace("Z", "+00:00"))
    except ValueError as error:
        raise InvalidMessage("event time is invalid") from error
    if event_time.tzinfo is None:
        raise InvalidMessage("event time must include a timezone")
    try:
        uuid.UUID(event.get("id", ""))
    except (AttributeError, TypeError, ValueError) as error:
        raise InvalidMessage("event ID is invalid") from error
    if "resources" in event and (
        not isinstance(event["resources"], list)
        or any(not isinstance(resource, str) for resource in event["resources"])
    ):
        raise InvalidMessage("event resources are invalid")
    if "replay-name" in event and not isinstance(event["replay-name"], str):
        raise InvalidMessage("event replay-name is invalid")

    try:
        detail = event["detail"]
        if not isinstance(detail, Mapping) or set(detail) != {"metadata", "data"}:
            raise InvalidMessage("event detail contains unsupported fields")
        metadata = detail["metadata"]
        data = detail["data"]
        source_object = data["object"]
        reference = data["configurationReference"]
        action = data["action"]
    except InvalidMessage:
        raise
    except (KeyError, TypeError) as error:
        raise InvalidMessage("requested action is missing required fields") from error

    if not all(isinstance(item, Mapping) for item in (metadata, data, source_object, reference, action)):
        raise InvalidMessage("requested action contains invalid object fields")
    if set(metadata) != {"correlationId", "causationId", "idempotencyKey"}:
        raise InvalidMessage("requested metadata contains unsupported fields")
    if set(data) - {
        "fileId",
        "object",
        "action",
        "actionExecutionId",
        "requestedAt",
        "notifications",
        "configurationReference",
    }:
        raise InvalidMessage("requested action data contains unsupported fields")
    if set(source_object) != {"bucket", "key", "versionId", "sizeBytes"}:
        raise InvalidMessage("source object contains unsupported fields")
    required_strings = (
        metadata.get("correlationId"),
        metadata.get("causationId"),
        metadata.get("idempotencyKey"),
        data.get("fileId"),
        data.get("actionExecutionId"),
        data.get("requestedAt"),
        source_object.get("bucket"),
        source_object.get("key"),
        source_object.get("versionId"),
        reference.get("secretArn"),
        reference.get("secretVersionId"),
    )
    if not all(isinstance(item, str) and item for item in required_strings):
        raise InvalidMessage("requested action contains invalid required values")
    if len(source_object["bucket"]) < 3:
        raise InvalidMessage("source bucket is invalid")
    if type(source_object.get("sizeBytes")) is not int or source_object["sizeBytes"] < 0:
        raise InvalidMessage("source object sizeBytes must be a non-negative integer")
    if action.get("name") != action_name:
        raise InvalidMessage("requested action does not match this writer")
    if set(action) != {"name"}:
        raise InvalidMessage("requested action contains unsupported fields")
    try:
        requested_at = datetime.fromisoformat(data["requestedAt"].replace("Z", "+00:00"))
    except ValueError as error:
        raise InvalidMessage("requestedAt is invalid") from error
    if requested_at.tzinfo is None:
        raise InvalidMessage("requestedAt must include a timezone")
    if source_object["versionId"] == "null":
        raise InvalidMessage("source object must have an immutable S3 version ID")
    notifications = data.get("notifications")
    if (
        not isinstance(notifications, list)
        or any(not isinstance(notification, str) or not notification for notification in notifications)
        or len(notifications) != len(set(notifications))
    ):
        raise InvalidMessage("requested notifications are invalid")
    for identifier in (
        metadata["correlationId"],
        metadata["causationId"],
        data["fileId"],
        data["actionExecutionId"],
    ):
        try:
            uuid.UUID(identifier)
        except ValueError as error:
            raise InvalidMessage("requested action contains an invalid UUID") from error
    if metadata["idempotencyKey"] != f"action-request:{data['actionExecutionId']}":
        raise InvalidMessage("requested action idempotency key is invalid")
    if set(reference) != {"secretArn", "secretVersionId"}:
        raise InvalidMessage("configuration reference contains unsupported fields")

    secret_arn = reference["secretArn"]
    if not re.fullmatch(
        r"arn:aws[a-zA-Z-]*:secretsmanager:eu-west-2:[0-9]{12}:secret:.+",
        secret_arn,
    ):
        raise InvalidMessage("configuration secret ARN is invalid")

    return {
        "event": event,
        "metadata": dict(metadata),
        "data": dict(data),
        "source_object": dict(source_object),
        "secret_arn": secret_arn,
        "secret_version_id": reference["secretVersionId"],
    }