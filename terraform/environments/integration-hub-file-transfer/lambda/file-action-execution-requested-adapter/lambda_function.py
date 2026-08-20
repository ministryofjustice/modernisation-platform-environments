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
    build_requested_event_detail,
    find_dispatch_configuration,
    parse_file_routed_event,
)


eventbridge = boto3.client("events")
secretsmanager = boto3.client("secretsmanager")
logger = Logger(service="file-action-execution-requested-adapter")
persistence_layer = DynamoDBPersistenceLayer(
    table_name=os.environ["IDEMPOTENCY_TABLE"]
)
idempotency_config = IdempotencyConfig(
    event_key_jmespath="detail.metadata.idempotencyKey",
    payload_validation_jmespath='[source, "detail-type", account, detail]',
    raise_on_no_idempotency_key=True,
    expires_after_seconds=int(os.environ["IDEMPOTENCY_EXPIRY_SECONDS"]),
)


def _eventbridge_entry(routed_file, detail, requested_at):
    resource = (
        f"arn:aws:s3:::{routed_file.destination_object['bucket']}/"
        f"{routed_file.destination_object['key']}"
    )
    return {
        "Source": EVENT_SOURCE,
        "DetailType": REQUESTED_DETAIL_TYPE,
        "Detail": json.dumps(detail, separators=(",", ":")),
        "EventBusName": os.environ["EVENT_BUS_ARN"],
        "Resources": [resource],
        "Time": requested_at,
    }


def _publish(entry):
    response = eventbridge.put_events(Entries=[entry])
    if response.get("FailedEntryCount", 0) > 0:
        raise RuntimeError(
            f"Failed to publish {REQUESTED_DETAIL_TYPE} event: {response['Entries']}"
        )

    return response["Entries"][0]["EventId"]


@logger.inject_lambda_context(clear_state=True, log_event=False)
@idempotent(
    persistence_store=persistence_layer,
    config=idempotency_config,
    key_prefix="managed-file-transfer/file-action-execution-requested-adapter",
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
            return {"eventId": None, "status": "NO_MATCH"}

        log_context.update(
            {
                "secret_arn": configuration.secret_arn,
                "secret_version_id": configuration.secret_version_id,
            }
        )
        requested_at = datetime.now(timezone.utc)
        detail = build_requested_event_detail(
            routed_file, configuration, requested_at=requested_at
        )
        if detail is None:
            logger.info(
                "Matched file action configuration has no configured work",
                extra=log_context,
            )
            return {"eventId": None, "status": "NO_ACTIONS"}

        entry = _eventbridge_entry(routed_file, detail, requested_at)
        action_request = {
            "action_name": configuration.action_name,
            "action_execution_id": detail["data"]["actionExecutionId"],
            "notifications": list(configuration.notifications),
        }
        log_context["action_request"] = action_request
        event_id = _publish(entry)
        action_request["destination_event_id"] = event_id
        logger.info(
            "Published file action execution request",
            extra=log_context,
        )
        return {"eventId": event_id, "status": "PUBLISHED"}
    except Exception:
        logger.exception(
            "Failed to dispatch file actions",
            extra=log_context,
        )
        raise