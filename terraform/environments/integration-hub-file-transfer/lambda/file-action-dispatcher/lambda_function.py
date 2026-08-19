import json
import os
from datetime import datetime, timezone

import boto3
from aws_lambda_powertools import Logger
from aws_lambda_powertools.utilities.idempotency import (
    DynamoDBPersistenceLayer,
    IdempotencyConfig,
    idempotent,
)

from dispatcher import (
    EVENT_SOURCE,
    REQUESTED_DETAIL_TYPE,
    build_requested_event_details,
    find_dispatch_configuration,
    parse_file_routed_event,
)


eventbridge = boto3.client("events")
secretsmanager = boto3.client("secretsmanager")
logger = Logger(service="integration-hub-file-transfer-file-action-dispatcher")
persistence_layer = DynamoDBPersistenceLayer(
    table_name=os.environ["IDEMPOTENCY_TABLE"]
)
idempotency_config = IdempotencyConfig(
    event_key_jmespath="detail.metadata.idempotencyKey",
    payload_validation_jmespath='[source, "detail-type", account, detail]',
    raise_on_no_idempotency_key=True,
    expires_after_seconds=int(os.environ["IDEMPOTENCY_EXPIRY_SECONDS"]),
)


def _eventbridge_entries(routed_file, details, requested_at):
    resource = (
        f"arn:aws:s3:::{routed_file.destination_object['bucket']}/"
        f"{routed_file.destination_object['key']}"
    )
    return [
        {
            "Source": EVENT_SOURCE,
            "DetailType": REQUESTED_DETAIL_TYPE,
            "Detail": json.dumps(detail, separators=(",", ":")),
            "EventBusName": os.environ["EVENT_BUS_ARN"],
            "Resources": [resource],
            "Time": requested_at,
        }
        for detail in details
    ]


def _publish(entries):
    event_ids = []
    for index in range(0, len(entries), 10):
        response = eventbridge.put_events(Entries=entries[index : index + 10])
        if response.get("FailedEntryCount", 0) > 0:
            failures = [
                {
                    "error_code": entry.get("ErrorCode"),
                    "error_message": entry.get("ErrorMessage"),
                }
                for entry in response.get("Entries", [])
                if entry.get("ErrorCode")
            ]
            raise RuntimeError(
                f"Failed to publish {REQUESTED_DETAIL_TYPE} events: {failures}"
            )

        event_ids.extend(entry["EventId"] for entry in response["Entries"])

    return event_ids


@logger.inject_lambda_context(clear_state=True, log_event=False)
@idempotent(
    persistence_store=persistence_layer,
    config=idempotency_config,
    key_prefix="managed-file-transfer/file-action-dispatcher",
)
def lambda_handler(event, _context):
    source_event_id = event.get("id")
    correlation_id = event.get("detail", {}).get("metadata", {}).get("correlationId")
    log_context = {
        "correlation_id": correlation_id,
        "source_event_id": source_event_id,
    }

    try:
        routed_file = parse_file_routed_event(event)
        log_context.update(
            {
                "file_id": routed_file.file_id,
                "object_bucket": routed_file.destination_object["bucket"],
                "object_key": routed_file.destination_object["key"],
                "object_version_id": routed_file.destination_object["versionId"],
            }
        )
        configuration = find_dispatch_configuration(
            secretsmanager,
            os.environ["DISPATCH_SECRET_NAME_PREFIX"],
            routed_file.destination_object["key"],
        )
        if configuration is None:
            logger.info(
                "No file action configuration matched",
                extra=log_context,
            )
            return {"eventIds": [], "status": "NO_MATCH"}

        log_context.update(
            {
                "secret_arn": configuration.secret_arn,
                "secret_version_id": configuration.secret_version_id,
            }
        )
        requested_at = datetime.now(timezone.utc)
        details = build_requested_event_details(
            routed_file, configuration, requested_at=requested_at
        )
        if not details:
            logger.info(
                "Matched file action configuration has no operations",
                extra=log_context,
            )
            return {"eventIds": [], "status": "NO_OPERATIONS"}

        entries = _eventbridge_entries(routed_file, details, requested_at)
        action_requests = [
            {
                "action_definition_id": operation.action,
                "action_execution_id": detail["data"]["actionExecutionId"],
                "operation_id": operation.operation_id,
            }
            for operation, detail in zip(
                configuration.operations,
                details,
            )
        ]
        log_context["action_requests"] = action_requests
        log_context["operation_count"] = len(action_requests)
        event_ids = _publish(entries)
        for action_request, destination_event_id in zip(action_requests, event_ids):
            action_request["destination_event_id"] = destination_event_id
        logger.info(
            "Published file action execution requests",
            extra=log_context,
        )
        return {"eventIds": event_ids, "status": "PUBLISHED"}
    except Exception:
        logger.exception(
            "Failed to dispatch file actions",
            extra=log_context,
        )
        raise