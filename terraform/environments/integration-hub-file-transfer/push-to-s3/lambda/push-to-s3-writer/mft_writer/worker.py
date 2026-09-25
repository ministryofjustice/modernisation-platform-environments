"""Shared validation and routing helpers for the S3 writer Lambdas."""

from __future__ import annotations

import hashlib
import json
import math
import os
import time
from collections.abc import Callable, Mapping
from datetime import datetime, timezone
from typing import Any

from aws_lambda_powertools import Metrics
from aws_lambda_powertools.metrics import MetricUnit

from mft_writer.completion import publish_completion
from mft_writer.config import (
    WriterConfig,
    validate_route,
    validate_secret_configuration,
)
from mft_writer.copy import (
    copy_versioned_object,
)
from mft_writer.diagnostics import (
    _aws_error_fields,
    _remaining_millis,
    _sanitised_error_text,
    _sanitised_trace,
    _update_log_fields,
    ensure_time,
    logger,
    structured_record_context,
)
from mft_writer.errors import InvalidMessage
from mft_writer.events import extract_requested_action
from mft_writer.services import AwsServices, create_aws_services
from mft_writer.store import ActionStore

metrics = Metrics(namespace="ManagedFileTransfer")


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
    return _process_event(event, context, services, process_writer_record, reporter=False)


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
    return _process_event(event, context, services, process_reporter_record, reporter=True)


def _process_event(
    event: Mapping[str, Any],
    context: Any,
    services: AwsServices | None,
    process_record: Callable[[Mapping[str, Any], WriterConfig, AwsServices, Any, dict[str, Any]], str],
    *,
    reporter: bool,
) -> dict[str, list[dict[str, str]]]:
    config = WriterConfig.from_environment(os.environ, reporter=reporter)
    if services is None:
        services = create_aws_services(config)
    records = event.get("Records")
    if not isinstance(records, list):
        raise InvalidMessage("Lambda input must contain an SQS Records array")

    failures: list[dict[str, str]] = []
    metric_prefix = "Reporter" if reporter else "Writer"
    metrics.add_dimension(name="ActionName", value=config.action_name)
    for record in records:
        message_id = record.get("messageId") if isinstance(record, Mapping) else None
        if not isinstance(record, Mapping) or not isinstance(message_id, str) or not message_id:
            raise InvalidMessage("SQS record is missing messageId")
        fields = _record_log_fields(record, context)
        started_at = time.perf_counter()
        try:
            with structured_record_context(fields):
                result = process_record(record, config, services, context, fields)
                metrics.add_metric(name=f"{metric_prefix}Record{result.title()}", unit=MetricUnit.Count, value=1)
                logger.info(
                    f"{metric_prefix.lower()} record processed",
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
            metrics.add_metric(name=f"{metric_prefix}RecordFailed", unit=MetricUnit.Count, value=1)
            failures.append({"itemIdentifier": message_id})
    return {"batchItemFailures": failures}