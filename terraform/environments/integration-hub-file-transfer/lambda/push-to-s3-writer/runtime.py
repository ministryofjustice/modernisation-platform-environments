"""Shared validation and routing helpers for the S3 writer Lambdas."""

from __future__ import annotations

import hashlib
import json
import math
import os
import re
import time
import traceback
import uuid
from collections.abc import Mapping
from contextlib import contextmanager
from dataclasses import dataclass
from datetime import datetime, timezone
from functools import lru_cache
from typing import Any

import boto3
from aws_lambda_powertools import Logger, Metrics
from aws_lambda_powertools.metrics import MetricUnit
from botocore.config import Config
from botocore.exceptions import ClientError

SUPPORTED_REGION = "eu-west-2"
IDEMPOTENCY_SECONDS = 7 * 24 * 60 * 60
TERMINAL_SECONDS = 90 * 24 * 60 * 60
SQS_RETENTION_SECONDS = 14 * 24 * 60 * 60
MAX_COPY_OBJECT_BYTES = 5 * 1000**3
MULTIPART_PART_BYTES = 512 * 1024**2
MIN_MULTIPART_PART_BYTES = 5 * 1024**2
MAX_MULTIPART_PART_BYTES = 5 * 1024**3
MAX_S3_PARTS = 10_000
MAX_MULTIPART_OBJECT_BYTES = MAX_S3_PARTS * MAX_MULTIPART_PART_BYTES
DEADLINE_SAFETY_MILLIS = 90_000
MIN_ABORT_REMAINING_MILLIS = 50_000
EVENT_SOURCE = "uk.gov.justice.service.managed-file-transfer"
REQUESTED_DETAIL_TYPE = "FileActionExecutionRequested.v1"
COMPLETED_DETAIL_TYPE = "FileActionExecutionCompleted.v1"
ALLOWED_ACTIONS = {"push-to-s3", "push-to-s3-with-hosted-pickup"}

logger = Logger(service=os.environ.get("POWERTOOLS_SERVICE_NAME", "push-to-s3-writer"))
metrics = Metrics(namespace="ManagedFileTransfer")


class InvalidMessage(ValueError):
    """An event or dispatch configuration is not authorised for this writer."""


class AwsResponseError(RuntimeError):
    def __init__(self, message: str, fields: Mapping[str, Any]):
        super().__init__(message)
        self.fields = dict(fields)


def _json_object(value: str, field: str) -> dict[str, Any]:
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
            current = _json_object(current, "message")
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
    if event.get("detail-type") != "FileActionExecutionRequested.v1":
        raise InvalidMessage("event detail-type is not supported")
    if event.get("source") != "uk.gov.justice.service.managed-file-transfer":
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
    if not isinstance(action, Mapping) or action.get("name") != action_name:
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


def resolve_secret_entry(secret_arn: str, allowlist: Mapping[str, Any]) -> tuple[str, Any]:
    """Match an ARN prefix only when its remaining suffix is exactly six characters."""
    matches = [
        (prefix, value)
        for prefix, value in allowlist.items()
        if isinstance(prefix, str)
        and secret_arn.startswith(prefix)
        and re.fullmatch(r"[A-Za-z0-9]{6}", secret_arn[len(prefix) :])
    ]
    if len(matches) != 1:
        raise InvalidMessage("configuration secret ARN is not uniquely authorised")
    return matches[0]


def load_json_environment(name: str, environ: Mapping[str, str]) -> dict[str, Any]:
    raw = environ.get(name)
    if raw is None:
        raise InvalidMessage(f"required environment variable {name} is missing")
    value = _json_object(raw, name)
    return value


@dataclass(frozen=True)
class WriterConfig:
    action_name: str
    source_bucket: str
    region: str
    table_name: str
    event_bus_name: str
    destinations: dict[str, Any]
    source_prefixes: dict[str, Any]
    role_arns: dict[str, Any]
    idempotency_seconds: int
    terminal_seconds: int
    dlq_arns: dict[str, Any]

    @classmethod
    def from_environment(
        cls, environ: Mapping[str, str], *, reporter: bool = False
    ) -> WriterConfig:
        action_name = environ.get("ACTION_NAME", "")
        if action_name not in ALLOWED_ACTIONS:
            raise InvalidMessage("ACTION_NAME is missing or unsupported")
        source_bucket = environ.get("SOURCE_BUCKET", "")
        if not source_bucket:
            raise InvalidMessage("required environment variable SOURCE_BUCKET is missing")
        region = environ.get("SUPPORTED_REGION", "")
        if region != SUPPORTED_REGION:
            raise InvalidMessage("SUPPORTED_REGION must be eu-west-2")
        table_name = environ.get("IDEMPOTENCY_TABLE", "")
        event_bus_name = environ.get("EVENT_BUS_NAME", "")
        if not table_name or not event_bus_name:
            raise InvalidMessage("IDEMPOTENCY_TABLE and EVENT_BUS_NAME are required")

        role_variable = "DELIVERY_ROLE_MAP" if action_name == "push-to-s3" else "MOVER_ROLE_MAP"
        destinations = load_json_environment("AUTHORISED_DESTINATION_MAP", environ)
        source_prefixes = load_json_environment("SOURCE_PREFIX_MAP", environ)
        role_arns = load_json_environment(role_variable, environ)
        if not (
            set(destinations) == set(source_prefixes) == set(role_arns)
        ):
            raise InvalidMessage("dispatch allowlists must have identical ARN-prefix keys")
        if any(not isinstance(key, str) or not key for key in destinations):
            raise InvalidMessage("dispatch allowlist keys must be non-empty strings")

        try:
            idempotency_seconds = int(environ.get("IDEMPOTENCY_EXPIRY_SECONDS", ""))
            terminal_seconds = int(environ.get("TERMINAL_OUTCOME_EXPIRY_SECONDS", ""))
        except ValueError as error:
            raise InvalidMessage("idempotency expiry settings must be integers") from error
        if idempotency_seconds != IDEMPOTENCY_SECONDS or terminal_seconds != TERMINAL_SECONDS:
            raise InvalidMessage("idempotency expiry settings do not match the supported policy")

        dlq_arns: dict[str, Any] = {}
        if reporter:
            dlq_arns = load_json_environment("DLQ_ARNS", environ)
            if not dlq_arns or any(not isinstance(arn, str) or not arn for arn in dlq_arns.values()):
                raise InvalidMessage("DLQ_ARNS must contain queue ARN strings")

        return cls(
            action_name=action_name,
            source_bucket=source_bucket,
            region=region,
            table_name=table_name,
            event_bus_name=event_bus_name,
            destinations=destinations,
            source_prefixes=source_prefixes,
            role_arns=role_arns,
            idempotency_seconds=idempotency_seconds,
            terminal_seconds=terminal_seconds,
            dlq_arns=dlq_arns,
        )


def validate_route(action: dict[str, Any], config: WriterConfig) -> dict[str, Any]:
    source_object = action["source_object"]
    if source_object["bucket"] != config.source_bucket:
        raise InvalidMessage("source bucket is not authorised")

    prefix, destination = resolve_secret_entry(action["secret_arn"], config.destinations)
    source_prefix = config.source_prefixes.get(prefix)
    role_arn = config.role_arns.get(prefix)
    if not isinstance(source_prefix, str) or not source_prefix:
        raise InvalidMessage("source prefix is not authorised")
    if source_prefix.startswith("/") or not source_prefix.endswith("/"):
        raise InvalidMessage("authorised source prefix is invalid")
    if not isinstance(role_arn, str) or not re.fullmatch(
        r"arn:aws[a-zA-Z-]*:iam::[0-9]{12}:role/.+", role_arn
    ):
        raise InvalidMessage("delivery role is not authorised")
    if not isinstance(destination, Mapping):
        raise InvalidMessage("destination configuration is invalid")

    key = source_object["key"]
    if not key.startswith(source_prefix):
        raise InvalidMessage("source key is outside the authorised prefix")
    relative_key = key[len(source_prefix) :]
    if not relative_key:
        raise InvalidMessage("source key has no relative filename")

    destination_bucket = destination.get("bucket")
    destination_prefix = destination.get("destination_prefix")
    destination_region = destination.get("region")
    kms_key_arn = destination.get("kms_key_arn")
    if not isinstance(destination_bucket, str) or not destination_bucket:
        raise InvalidMessage("destination bucket is invalid")
    if (
        not isinstance(destination_prefix, str)
        or destination_prefix.startswith("/")
        or (destination_prefix and not destination_prefix.endswith("/"))
    ):
        raise InvalidMessage("destination prefix is invalid")
    if destination_region != config.region:
        raise InvalidMessage("destination region is not supported")
    if not isinstance(kms_key_arn, str) or not re.fullmatch(
        r"arn:aws[a-zA-Z-]*:kms:eu-west-2:[0-9]{12}:key/[A-Za-z0-9-]+", kms_key_arn
    ):
        raise InvalidMessage("destination KMS key is invalid")

    if config.action_name == "push-to-s3-with-hosted-pickup":
        retention = destination.get("retention_days")
        if type(retention) is not int or retention < 1:
            raise InvalidMessage("hosted pickup retention_days is invalid")
    return {
        "secret_prefix": prefix,
        "source_prefix": source_prefix,
        "relative_key": relative_key,
        "destination_bucket": destination_bucket,
        "destination_key": f"{destination_prefix}{relative_key}",
        "destination_prefix": destination_prefix,
        "destination_region": destination_region,
        "kms_key_arn": kms_key_arn,
        "role_arn": role_arn,
        "bucket_key_enabled": config.action_name == "push-to-s3-with-hosted-pickup",
        "destination": dict(destination),
    }


def validate_secret_configuration(
    secret_value: str, action_name: str, route: Mapping[str, Any]
) -> None:
    secret = _json_object(secret_value, "dispatch secret")
    action = secret.get("action")
    if not isinstance(action, Mapping) or action.get("name") != action_name:
        raise InvalidMessage("dispatch secret action does not match this writer")

    if action_name == "push-to-s3":
        details = action.get("push_to_s3")
        expected = route["destination"]
        expected_values = {
            "bucket_id": expected["bucket"],
            "bucket_region": expected["region"],
            "destination_prefix": expected["destination_prefix"],
            "kms_key_arn": expected["kms_key_arn"],
        }
        actual_values = dict(details) if isinstance(details, Mapping) else {}
        actual_values.setdefault("bucket_region", SUPPORTED_REGION)
    else:
        details = action.get("push_to_s3_with_hosted_pickup")
        expected = route["destination"]
        expected_values = {
            "destination_prefix": expected["destination_prefix"],
            "retention_days": expected["retention_days"],
        }
        actual_values = dict(details) if isinstance(details, Mapping) else {}
    if actual_values != expected_values:
        raise InvalidMessage("dispatch secret action does not match the authorised destination")


def action_fingerprint(action: Mapping[str, Any], route: Mapping[str, Any], config: WriterConfig) -> str:
    source = action["source_object"]
    identity = {
        "actionName": config.action_name,
        "actionExecutionId": action["data"]["actionExecutionId"],
        "secretArn": action["secret_arn"],
        "secretVersionId": action["secret_version_id"],
        "sourceBucket": source["bucket"],
        "sourceKey": source["key"],
        "sourceVersionId": source["versionId"],
        "sourceSizeBytes": source["sizeBytes"],
        "fileId": action["data"]["fileId"],
        "correlationId": action["metadata"]["correlationId"],
        "destinationBucket": route["destination_bucket"],
        "destinationKey": route["destination_key"],
        "kmsKeyArn": route["kms_key_arn"],
        "roleArn": route["role_arn"],
    }
    encoded = json.dumps(identity, sort_keys=True, separators=(",", ":")).encode("utf-8")
    return hashlib.sha256(encoded).hexdigest()


def action_snapshot(
    action: Mapping[str, Any], route: Mapping[str, Any], config: WriterConfig, fingerprint: str
) -> dict[str, Any]:
    source = action["source_object"]
    data = action["data"]
    return {
        "id": data["actionExecutionId"],
        "fingerprint": fingerprint,
        "actionName": config.action_name,
        "actionDefinitionId": action["secret_arn"],
        "actionExecutionId": data["actionExecutionId"],
        "fileId": data["fileId"],
        "requestEventId": action["event"]["id"],
        "correlationId": action["metadata"]["correlationId"],
        "causationId": action["metadata"]["causationId"],
        "sourceBucket": source["bucket"],
        "sourceKey": source["key"],
        "sourceVersionId": source["versionId"],
        "sourceSizeBytes": source["sizeBytes"],
        "destinationBucket": route["destination_bucket"],
        "destinationKey": route["destination_key"],
        "kmsKeyArn": route["kms_key_arn"],
        "roleArn": route["role_arn"],
        "region": config.region,
    }


def _conditional_failure(error: Exception) -> bool:
    return (
        isinstance(error, ClientError)
        and error.response.get("Error", {}).get("Code") == "ConditionalCheckFailedException"
    )


class ActionStore:
    """Atomic action claims and durable copy/terminal markers in the shared table."""

    def __init__(self, table: Any):
        self.table = table

    def get(self, action_id: str) -> dict[str, Any] | None:
        return self.table.get_item(Key={"id": action_id}, ConsistentRead=True).get("Item")

    def claim(
        self,
        item: Mapping[str, Any],
        *,
        now: int,
        lease_seconds: int,
        idempotency_seconds: int,
        terminal_seconds: int,
        allow_expired: bool = False,
    ) -> tuple[str, dict[str, Any] | None, str | None]:
        owner_token = str(uuid.uuid4())
        new_item = dict(item)
        new_item.update(
            {
                "state": "IN_PROGRESS",
                "ownerToken": owner_token,
                "leaseUntil": now + lease_seconds,
                "deduplicationExpiresAt": now + idempotency_seconds,
                "expiration": now + max(idempotency_seconds, SQS_RETENTION_SECONDS + idempotency_seconds),
            }
        )
        try:
            self.table.put_item(Item=new_item, ConditionExpression="attribute_not_exists(id)")
            return "claimed", new_item, owner_token
        except Exception as error:
            if not _conditional_failure(error):
                raise

        existing = self.get(new_item["id"])
        if existing is None:
            raise RuntimeError("action claim changed during contention; retry the record")
        if existing.get("fingerprint") != item["fingerprint"]:
            raise InvalidMessage("action execution ID is already bound to different file details")
        state = existing.get("state")
        if state in {"SUCCEEDED", "FAILED"}:
            return "terminal", existing, None
        if state not in {"IN_PROGRESS", "COPIED"}:
            raise InvalidMessage("stored action state is invalid")
        expired_in_progress = (
            state == "IN_PROGRESS"
            and int(existing.get("deduplicationExpiresAt", existing.get("expiration", 0))) <= now
        )
        if expired_in_progress and not allow_expired:
            return "expired", existing, None
        if int(existing.get("leaseUntil", 0)) > now:
            return "active", existing, None

        expiry = now + (
            terminal_seconds
            if state == "COPIED"
            else max(idempotency_seconds, SQS_RETENTION_SECONDS + idempotency_seconds)
        )
        try:
            result = self.table.update_item(
                Key={"id": new_item["id"]},
                UpdateExpression="SET ownerToken = :owner, leaseUntil = :lease, expiration = :expiry",
                ConditionExpression=(
                    "fingerprint = :fingerprint AND #state = :state "
                    "AND leaseUntil <= :now"
                ),
                ExpressionAttributeNames={"#state": "state"},
                ExpressionAttributeValues={
                    ":owner": owner_token,
                    ":lease": now + lease_seconds,
                    ":expiry": expiry,
                    ":fingerprint": item["fingerprint"],
                    ":state": state,
                    ":now": now,
                },
                ReturnValues="ALL_NEW",
            )
            return ("claimed-expired" if expired_in_progress else "claimed"), result["Attributes"], owner_token
        except Exception as error:
            if not _conditional_failure(error):
                raise
            latest = self.get(new_item["id"])
            if (
                latest
                and latest.get("fingerprint") == item["fingerprint"]
                and latest.get("state") in {"SUCCEEDED", "FAILED"}
            ):
                return "terminal", latest, None
            return "active", latest, None

    def mark_copied(
        self,
        item: Mapping[str, Any],
        owner_token: str,
        version_id: str | None,
        completed_at: str,
        deduplication_expiry: int,
        expiry: int,
        lease_until: int,
    ) -> dict[str, Any]:
        values: dict[str, Any] = {
            ":copied": "COPIED",
            ":owner": owner_token,
            ":fingerprint": item["fingerprint"],
            ":expiry": expiry,
            ":lease": lease_until,
            ":completed": completed_at,
            ":dedupe": deduplication_expiry,
        }
        update = (
            "SET #state = :copied, completedAt = :completed, deduplicationExpiresAt = :dedupe, "
            "expiration = :expiry, leaseUntil = :lease"
        )
        if version_id:
            update += ", destinationVersionId = :version"
            values[":version"] = version_id
        response = self.table.update_item(
            Key={"id": item["id"]},
            UpdateExpression=update,
            ConditionExpression="#state = :progress AND ownerToken = :owner AND fingerprint = :fingerprint",
            ExpressionAttributeNames={"#state": "state"},
            ExpressionAttributeValues={**values, ":progress": "IN_PROGRESS"},
            ReturnValues="ALL_NEW",
        )
        return response["Attributes"]

    def mark_succeeded(self, item: Mapping[str, Any], owner_token: str, expiry: int) -> dict[str, Any]:
        response = self.table.update_item(
            Key={"id": item["id"]},
            UpdateExpression="SET #state = :success, expiration = :expiry REMOVE ownerToken, leaseUntil",
            ConditionExpression="#state = :copied AND ownerToken = :owner AND fingerprint = :fingerprint",
            ExpressionAttributeNames={"#state": "state"},
            ExpressionAttributeValues={
                ":success": "SUCCEEDED",
                ":copied": "COPIED",
                ":owner": owner_token,
                ":fingerprint": item["fingerprint"],
                ":expiry": expiry,
            },
            ReturnValues="ALL_NEW",
        )
        return response["Attributes"]

    def mark_failed(
        self,
        item: Mapping[str, Any],
        owner_token: str,
        completed_at: str,
        expiry: int,
        failure_message: str = "Delivery attempts exhausted; destination outcome is uncertain.",
    ) -> dict[str, Any]:
        response = self.table.update_item(
            Key={"id": item["id"]},
            UpdateExpression=(
                "SET #state = :failed, completedAt = :completed, failureCode = :code, "
                "failureMessage = :message, expiration = :expiry REMOVE ownerToken, leaseUntil"
            ),
            ConditionExpression="#state = :progress AND ownerToken = :owner AND fingerprint = :fingerprint",
            ExpressionAttributeNames={"#state": "state"},
            ExpressionAttributeValues={
                ":failed": "FAILED",
                ":progress": "IN_PROGRESS",
                ":owner": owner_token,
                ":fingerprint": item["fingerprint"],
                ":completed": completed_at,
                ":code": "DeliveryAttemptsExhausted",
                ":message": failure_message,
                ":expiry": expiry,
            },
            ReturnValues="ALL_NEW",
        )
        return response["Attributes"]


def _aws_error_fields(error: Exception) -> dict[str, Any]:
    if isinstance(error, AwsResponseError):
        return error.fields
    if not isinstance(error, ClientError):
        return {
            "awsErrorCode": None,
            "awsErrorMessage": None,
            "httpStatusCode": None,
            "awsRequestId": None,
            "hostId": None,
            "retryCount": None,
            "retryable": isinstance(error, (TimeoutError, ConnectionError)),
        }
    response = error.response
    metadata = response.get("ResponseMetadata", {})
    error_details = response.get("Error", {})
    status = metadata.get("HTTPStatusCode")
    code = error_details.get("Code")
    return {
        "awsErrorCode": code,
        "awsErrorMessage": _sanitised_error_text(error_details.get("Message")),
        "httpStatusCode": status,
        "awsRequestId": metadata.get("RequestId"),
        "hostId": error_details.get("HostId"),
        "retryCount": metadata.get("RetryAttempts"),
        "retryable": status == 429
        or (isinstance(status, int) and status >= 500)
        or code in {"InternalError", "RequestTimeout", "RequestTimeoutException", "SlowDown", "Throttling", "ThrottlingException", "ServiceUnavailable"},
    }


def _sanitised_error_text(value: Any) -> str | None:
    if not isinstance(value, str):
        return None
    redacted = re.sub(r"(?i)arn:aws[^\s,]*", "[redacted-resource]", value)
    redacted = re.sub(r"(?i)(AKIA|ASIA)[A-Z0-9]{12,}", "[redacted-credential]", redacted)
    redacted = re.sub(r"[^A-Za-z0-9 .,:_/-]", " ", redacted)
    return " ".join(redacted.split())[:240] or None


def _sanitised_trace(error: Exception) -> list[str]:
    return traceback.format_tb(error.__traceback__)


@contextmanager
def structured_record_context(fields: Mapping[str, Any]):
    initial_keys = set(fields)
    logger.append_keys(**dict(fields))
    try:
        yield
    finally:
        logger.remove_keys(list(set(fields) | initial_keys))


def _update_log_fields(fields: dict[str, Any] | None, **values: Any) -> None:
    if fields is not None:
        fields.update(values)
        logger.append_keys(**values)


@dataclass
class AwsServices:
    secrets: Any
    sts: Any
    table: Any
    eventbridge: Any
    s3_for_role: Any


@lru_cache(maxsize=8)
def _base_aws_clients(region: str, table_name: str) -> tuple[Any, Any, Any, Any, Config]:
    session = boto3.session.Session(region_name=region)
    client_config = Config(
        retries={"mode": "standard", "total_max_attempts": 2},
        connect_timeout=5,
        read_timeout=15,
        max_pool_connections=4,
        tcp_keepalive=True,
    )
    secrets = session.client("secretsmanager", config=client_config)
    sts = session.client("sts", config=client_config)
    table = session.resource("dynamodb", config=client_config).Table(table_name)
    eventbridge = session.client("events", config=client_config)
    return secrets, sts, table, eventbridge, client_config


def create_aws_services(config: WriterConfig) -> AwsServices:
    secrets, sts, table, eventbridge, client_config = _base_aws_clients(
        config.region, config.table_name
    )

    def s3_for_role(role_arn: str, action_id: str) -> Any:
        assumed = sts.assume_role(
            RoleArn=role_arn,
            RoleSessionName=f"file-copy-{action_id[:12]}",
            DurationSeconds=900,
        )["Credentials"]
        role_session = boto3.session.Session(
            aws_access_key_id=assumed["AccessKeyId"],
            aws_secret_access_key=assumed["SecretAccessKey"],
            aws_session_token=assumed["SessionToken"],
            region_name=config.region,
        )
        return role_session.client("s3", config=client_config)

    return AwsServices(secrets, sts, table, eventbridge, s3_for_role)


def _remaining_millis(context: Any) -> int:
    if context is None or not hasattr(context, "get_remaining_time_in_millis"):
        return 900_000
    return int(context.get_remaining_time_in_millis())


def ensure_time(context: Any, operation: str) -> None:
    remaining = _remaining_millis(context)
    if remaining <= DEADLINE_SAFETY_MILLIS:
        raise TimeoutError(f"insufficient Lambda time remaining before {operation}")


def _copy_source(source: Mapping[str, Any]) -> dict[str, str]:
    return {
        "Bucket": source["bucket"],
        "Key": source["key"],
        "VersionId": source["versionId"],
    }


def _copy_metadata(head: Mapping[str, Any]) -> dict[str, Any]:
    return {
        key: head[key]
        for key in (
            "CacheControl",
            "ContentDisposition",
            "ContentEncoding",
            "ContentLanguage",
            "ContentType",
            "Expires",
            "Metadata",
        )
        if key in head
    }


def _multipart_part_size(size: int) -> int:
    if size > MAX_MULTIPART_OBJECT_BYTES:
        raise InvalidMessage("source object exceeds the supported S3 object size limit")
    required = max(MULTIPART_PART_BYTES, math.ceil(size / MAX_S3_PARTS))
    part_size = math.ceil(required / (1024 * 1024)) * 1024 * 1024
    if part_size > MAX_MULTIPART_PART_BYTES:
        raise InvalidMessage("source object exceeds the supported multipart copy limits")
    return max(part_size, MIN_MULTIPART_PART_BYTES)


def copy_versioned_object(
    s3: Any,
    source: Mapping[str, Any],
    route: Mapping[str, Any],
    action_name: str,
    context: Any,
    log_fields: dict[str, Any] | None = None,
) -> tuple[str | None, int]:
    ensure_time(context, "source head")
    _update_log_fields(log_fields, operation="HeadObject")
    head = s3.head_object(
        Bucket=source["bucket"], Key=source["key"], VersionId=source["versionId"]
    )
    size = int(head["ContentLength"])
    if size != source["sizeBytes"]:
        raise InvalidMessage("source object size does not match the requested version")
    if size > MAX_MULTIPART_OBJECT_BYTES:
        raise InvalidMessage("source object exceeds the supported S3 object size limit")

    encryption = {
        "ServerSideEncryption": "aws:kms",
        "SSEKMSKeyId": route["kms_key_arn"],
    }
    if action_name == "push-to-s3-with-hosted-pickup":
        encryption["BucketKeyEnabled"] = True
    destination = {"Bucket": route["destination_bucket"], "Key": route["destination_key"]}

    if size <= MAX_COPY_OBJECT_BYTES:
        ensure_time(context, "CopyObject")
        _update_log_fields(log_fields, operation="CopyObject")
        response = s3.copy_object(
            **destination,
            CopySource=_copy_source(source),
            MetadataDirective="COPY",
            TaggingDirective="REPLACE",
            **encryption,
        )
        return response.get("VersionId"), size

    part_size = _multipart_part_size(size)
    total_parts = math.ceil(size / part_size)
    if total_parts > MAX_S3_PARTS:
        raise InvalidMessage("source object exceeds the supported multipart copy limits")
    ensure_time(context, "CreateMultipartUpload")
    _update_log_fields(log_fields, operation="CreateMultipartUpload")
    created = s3.create_multipart_upload(
        **destination,
        **_copy_metadata(head),
        **encryption,
    )
    upload_id = created["UploadId"]
    _update_log_fields(log_fields, uploadId=upload_id, bytesCopied=0)
    completed_parts: list[dict[str, Any]] = []
    try:
        for part_number in range(1, total_parts + 1):
            ensure_time(context, "UploadPartCopy")
            start = (part_number - 1) * part_size
            end = min(start + part_size, size) - 1
            _update_log_fields(
                log_fields,
                operation="UploadPartCopy",
                partNumber=part_number,
                totalParts=total_parts,
            )
            response = s3.upload_part_copy(
                **destination,
                UploadId=upload_id,
                PartNumber=part_number,
                CopySource=_copy_source(source),
                CopySourceRange=f"bytes={start}-{end}",
            )
            completed_parts.append(
                {"PartNumber": part_number, "ETag": response["CopyPartResult"]["ETag"]}
            )
            _update_log_fields(log_fields, bytesCopied=end + 1)
            logger.info(
                "multipart copy part completed",
                partNumber=part_number,
                totalParts=total_parts,
                copiedBytes=end + 1,
                sourceBucket=source["bucket"],
                sourceKey=source["key"],
                destinationBucket=route["destination_bucket"],
                destinationKey=route["destination_key"],
            )
        ensure_time(context, "CompleteMultipartUpload")
        _update_log_fields(log_fields, operation="CompleteMultipartUpload")
        response = s3.complete_multipart_upload(
            **destination,
            UploadId=upload_id,
            MultipartUpload={"Parts": completed_parts},
        )
        return response.get("VersionId"), size
    except Exception:
        if _remaining_millis(context) >= MIN_ABORT_REMAINING_MILLIS:
            try:
                s3.abort_multipart_upload(**destination, UploadId=upload_id)
            except Exception as abort_error:  # noqa: BLE001
                logger.warning(
                    "multipart abort failed",
                    **_aws_error_fields(abort_error),
                    sourceBucket=source["bucket"],
                    sourceKey=source["key"],
                    destinationBucket=route["destination_bucket"],
                    destinationKey=route["destination_key"],
                )
        raise


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


def _lease_seconds(context: Any) -> int:
    return max(30, math.ceil(_remaining_millis(context) / 1000) + 30)


def _read_dispatch_secret(services: AwsServices, action: Mapping[str, Any]) -> str:
    response = services.secrets.get_secret_value(
        SecretId=action["secret_arn"], VersionId=action["secret_version_id"]
    )
    if response.get("VersionId") != action["secret_version_id"]:
        raise InvalidMessage("Secrets Manager returned a different secret version")
    secret_value = response.get("SecretString")
    if not isinstance(secret_value, str):
        raise InvalidMessage("dispatch secret does not contain a JSON string")
    return secret_value


def _claim_action(
    store: ActionStore,
    item: Mapping[str, Any],
    config: WriterConfig,
    context: Any,
    *,
    allow_expired: bool = False,
) -> tuple[str, dict[str, Any] | None, str | None]:
    now = int(datetime.now(timezone.utc).timestamp())
    return store.claim(
        item,
        now=now,
        lease_seconds=_lease_seconds(context),
        idempotency_seconds=config.idempotency_seconds,
        terminal_seconds=config.terminal_seconds,
        allow_expired=allow_expired,
    )


def _publish_copied(
    store: ActionStore,
    services: AwsServices,
    item: Mapping[str, Any],
    owner_token: str,
    config: WriterConfig,
    log_fields: dict[str, Any] | None = None,
) -> None:
    _update_log_fields(log_fields, operation="publish-completion")
    publish_completion(services.eventbridge, config.event_bus_name, item, "succeeded")
    _update_log_fields(log_fields, operation="checkpoint-mark-succeeded")
    store.mark_succeeded(
        item,
        owner_token,
        int(datetime.now(timezone.utc).timestamp()) + config.terminal_seconds,
    )


def process_writer_record(
    record: Mapping[str, Any],
    config: WriterConfig,
    services: AwsServices,
    context: Any,
    log_fields: dict[str, Any] | None = None,
) -> str:
    _update_log_fields(log_fields, operation="validate-event")
    action = extract_requested_action(record.get("body", ""), config.action_name)
    _update_log_fields(
        log_fields,
        actionExecutionId=action["data"]["actionExecutionId"],
        correlationId=action["metadata"]["correlationId"],
        fileId=action["data"]["fileId"],
        sourceBucket=action["source_object"]["bucket"],
        sourceKey=action["source_object"]["key"],
        sourceVersionId=action["source_object"]["versionId"],
        operation="validate-route",
        region=config.region,
    )
    route = validate_route(action, config)
    _update_log_fields(
        log_fields,
        destinationBucket=route["destination_bucket"],
        destinationKey=route["destination_key"],
        roleArn=route["role_arn"],
        operation="read-dispatch-secret",
    )
    secret_value = _read_dispatch_secret(services, action)
    validate_secret_configuration(secret_value, config.action_name, route)
    fingerprint = action_fingerprint(action, route, config)
    item = action_snapshot(action, route, config, fingerprint)
    store = ActionStore(services.table)
    _update_log_fields(log_fields, operation="claim-action")
    claim_status, stored, owner_token = _claim_action(store, item, config, context)
    if claim_status == "terminal":
        return "duplicate"
    if claim_status == "expired":
        raise RuntimeError("action deduplication window expired; destination outcome may be uncertain")
    if claim_status == "active" or stored is None or owner_token is None:
        raise RuntimeError("another invocation holds the action lease")
    if stored.get("state") == "COPIED":
        _publish_copied(store, services, stored, owner_token, config)
        return "published"

    _update_log_fields(log_fields, operation="AssumeRole")
    ensure_time(context, "AssumeRole")
    s3 = services.s3_for_role(route["role_arn"], item["actionExecutionId"])
    version_id, size = copy_versioned_object(
        s3, action["source_object"], route, config.action_name, context, log_fields
    )
    if size != item["sourceSizeBytes"]:
        raise InvalidMessage("source object size changed during the copy")
    now = int(datetime.now(timezone.utc).timestamp())
    completed_at = datetime.fromtimestamp(now, timezone.utc).isoformat().replace("+00:00", "Z")
    _update_log_fields(log_fields, operation="checkpoint-mark-copied")
    stored = store.mark_copied(
        stored,
        owner_token,
        version_id,
        completed_at,
        now + config.idempotency_seconds,
        now + config.terminal_seconds,
        now + _lease_seconds(context),
    )
    _publish_copied(store, services, stored, owner_token, config, log_fields)
    return "copied"


def _record_log_fields(record: Mapping[str, Any], context: Any) -> dict[str, Any]:
    attributes = record.get("attributes") or {}
    return {
        "lambdaRequestId": getattr(context, "aws_request_id", None),
        "sqsMessageId": record.get("messageId"),
        "sourceQueueArn": record.get("eventSourceARN"),
        "receiveCount": attributes.get("ApproximateReceiveCount"),
        "remainingTimeMillis": _remaining_millis(context),
    }


def _log_record_failure(error: Exception, context: Any, elapsed_millis: int) -> None:
    fields = _aws_error_fields(error)
    fields["remainingTimeMillis"] = _remaining_millis(context)
    fields["elapsedMillis"] = elapsed_millis
    fields["failureReason"] = _sanitised_error_text(str(error)) if isinstance(error, InvalidMessage) else None
    logger.error(
        "record processing failed",
        errorType=type(error).__name__,
        exceptionTrace=_sanitised_trace(error),
        **fields,
    )


def process_writer_event(
    event: Mapping[str, Any], context: Any, services: AwsServices | None = None
) -> dict[str, list[dict[str, str]]]:
    config = WriterConfig.from_environment(os.environ)
    if services is None:
        services = create_aws_services(config)
    records = event.get("Records")
    if not isinstance(records, list):
        raise InvalidMessage("Lambda input must contain an SQS Records array")

    failures: list[dict[str, str]] = []
    metrics.add_dimension(name="ActionName", value=config.action_name)
    for record in records:
        message_id = record.get("messageId") if isinstance(record, Mapping) else None
        if not isinstance(record, Mapping) or not isinstance(message_id, str) or not message_id:
            raise InvalidMessage("SQS record is missing messageId")
        fields = _record_log_fields(record, context)
        started_at = time.perf_counter()
        try:
            with structured_record_context(fields):
                result = process_writer_record(record, config, services, context, fields)
                metrics.add_metric(name=f"WriterRecord{result.title()}", unit=MetricUnit.Count, value=1)
                logger.info(
                    "writer record processed",
                    result=result,
                    elapsedMillis=round((time.perf_counter() - started_at) * 1000),
                    remainingTimeMillis=_remaining_millis(context),
                )
        except Exception as error:  # noqa: BLE001
            with structured_record_context(fields):
                _update_log_fields(fields, remainingTimeMillis=_remaining_millis(context))
                _log_record_failure(
                    error, context, round((time.perf_counter() - started_at) * 1000)
                )
            metrics.add_metric(name="WriterRecordFailed", unit=MetricUnit.Count, value=1)
            failures.append({"itemIdentifier": message_id})
    return {"batchItemFailures": failures}


def process_reporter_record(
    record: Mapping[str, Any],
    config: WriterConfig,
    services: AwsServices,
    context: Any,
    log_fields: dict[str, Any] | None = None,
) -> str:
    _update_log_fields(log_fields, operation="validate-event")
    queue_arn = record.get("eventSourceARN")
    if queue_arn not in config.dlq_arns.values():
        raise InvalidMessage("SQS source is not an authorised dead-letter queue")
    action = extract_requested_action(record.get("body", ""), config.action_name)
    route = validate_route(action, config)
    _update_log_fields(
        log_fields,
        actionExecutionId=action["data"]["actionExecutionId"],
        correlationId=action["metadata"]["correlationId"],
        fileId=action["data"]["fileId"],
        sourceBucket=action["source_object"]["bucket"],
        sourceKey=action["source_object"]["key"],
        sourceVersionId=action["source_object"]["versionId"],
        destinationBucket=route["destination_bucket"],
        destinationKey=route["destination_key"],
        roleArn=route["role_arn"],
        region=config.region,
        operation="report-dead-letter-outcome",
    )
    fingerprint = action_fingerprint(action, route, config)
    item = action_snapshot(action, route, config, fingerprint)
    store = ActionStore(services.table)
    claim_status, stored, owner_token = _claim_action(
        store, item, config, context, allow_expired=True
    )
    if claim_status == "active" or stored is None:
        raise RuntimeError("action is still active; reporter will retry")
    if claim_status == "terminal":
        if stored.get("state") == "SUCCEEDED":
            return "already-succeeded"
        if stored.get("state") == "FAILED":
            _update_log_fields(log_fields, operation="publish-completion")
            publish_completion(services.eventbridge, config.event_bus_name, stored, "failed")
            return "failed-republished"
        raise InvalidMessage("stored terminal action state is invalid")
    if owner_token is None:
        raise RuntimeError("reporter did not acquire the action lease")
    if stored.get("state") == "COPIED":
        _publish_copied(store, services, stored, owner_token, config, log_fields)
        return "copied-reported"

    completed_at = datetime.now(timezone.utc).isoformat().replace("+00:00", "Z")
    _update_log_fields(log_fields, operation="checkpoint-mark-failed")
    stored = store.mark_failed(
        stored,
        owner_token,
        completed_at,
        int(datetime.now(timezone.utc).timestamp()) + config.terminal_seconds,
        "Delivery attempts exhausted; destination outcome may be uncertain.",
    )
    _update_log_fields(log_fields, operation="publish-completion")
    publish_completion(services.eventbridge, config.event_bus_name, stored, "failed")
    return "failed-reported"


def process_reporter_event(
    event: Mapping[str, Any], context: Any, services: AwsServices | None = None
) -> dict[str, list[dict[str, str]]]:
    config = WriterConfig.from_environment(os.environ, reporter=True)
    if services is None:
        services = create_aws_services(config)
    records = event.get("Records")
    if not isinstance(records, list):
        raise InvalidMessage("Lambda input must contain an SQS Records array")

    failures: list[dict[str, str]] = []
    metrics.add_dimension(name="ActionName", value=config.action_name)
    for record in records:
        message_id = record.get("messageId") if isinstance(record, Mapping) else None
        if not isinstance(record, Mapping) or not isinstance(message_id, str) or not message_id:
            raise InvalidMessage("SQS record is missing messageId")
        fields = _record_log_fields(record, context)
        started_at = time.perf_counter()
        try:
            with structured_record_context(fields):
                result = process_reporter_record(record, config, services, context, fields)
                metrics.add_metric(name=f"ReporterRecord{result.title()}", unit=MetricUnit.Count, value=1)
                logger.info(
                    "reporter record processed",
                    result=result,
                    elapsedMillis=round((time.perf_counter() - started_at) * 1000),
                    remainingTimeMillis=_remaining_millis(context),
                )
        except Exception as error:  # noqa: BLE001
            with structured_record_context(fields):
                _update_log_fields(fields, remainingTimeMillis=_remaining_millis(context))
                _log_record_failure(
                    error, context, round((time.perf_counter() - started_at) * 1000)
                )
            metrics.add_metric(name="ReporterRecordFailed", unit=MetricUnit.Count, value=1)
            failures.append({"itemIdentifier": message_id})
    return {"batchItemFailures": failures}