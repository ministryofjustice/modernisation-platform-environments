import json
import os
from datetime import datetime, timezone

import boto3
from aws_lambda_powertools import Logger, Metrics
from aws_lambda_powertools.metrics import MetricUnit
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
metrics = Metrics(service="integration-hub-file-transfer-file-action-dispatcher")
persistence_layer = DynamoDBPersistenceLayer(
    table_name=os.environ["IDEMPOTENCY_TABLE"]
)
idempotency_config = IdempotencyConfig(
    event_key_jmespath="detail.metadata.idempotencyKey",
    payload_validation_jmespath='[source, "detail-type", account, detail]',
    raise_on_no_idempotency_key=True,
    expires_after_seconds=int(os.environ["IDEMPOTENCY_EXPIRY_SECONDS"]),
)


def _eventbridge_entries(routed_file, configuration, requested_at):
    details = build_requested_event_details(
        routed_file, configuration, requested_at=requested_at
    )
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
            raise RuntimeError(
                f"Failed to publish {REQUESTED_DETAIL_TYPE} events: "
                f"{response.get('Entries', [])}"
            )

        response_entries = response.get("Entries", [])
        if len(response_entries) != len(entries[index : index + 10]):
            raise RuntimeError("EventBridge returned an incomplete publish response")

        for response_entry in response_entries:
            event_id = response_entry.get("EventId")
            if not event_id:
                raise RuntimeError("EventBridge did not return a requested event ID")
            event_ids.append(event_id)

    return event_ids


@logger.inject_lambda_context(clear_state=True, log_event=False)
@metrics.log_metrics
@idempotent(
    persistence_store=persistence_layer,
    config=idempotency_config,
    key_prefix="managed-file-transfer/file-action-dispatcher",
)
def lambda_handler(event, _context):
    source_event_id = event.get("id")

    try:
        routed_file = parse_file_routed_event(
            event,
            os.environ["AWS_ACCOUNT_ID"],
            os.environ["CLEAN_BUCKET_NAME"],
        )
        configuration = find_dispatch_configuration(
            secretsmanager,
            os.environ["DISPATCH_SECRET_NAME_PREFIX"],
            routed_file.destination_object["key"],
        )
        if configuration is None:
            metrics.add_metric(name="ConfigurationNotMatched", unit=MetricUnit.Count, value=1)
            logger.info(
                "No file action configuration matched",
                extra={"source_event_id": source_event_id},
            )
            return {"eventIds": [], "status": "NO_MATCH"}

        requested_at = datetime.now(timezone.utc)
        entries = _eventbridge_entries(routed_file, configuration, requested_at)
        if not entries:
            metrics.add_metric(name="ConfigurationEmpty", unit=MetricUnit.Count, value=1)
            logger.info(
                "Matched file action configuration has no operations",
                extra={"source_event_id": source_event_id},
            )
            return {"eventIds": [], "status": "NO_OPERATIONS"}

        event_ids = _publish(entries)
        metrics.add_metric(
            name="ActionsRequested", unit=MetricUnit.Count, value=len(event_ids)
        )
        logger.info(
            "Published file action execution requests",
            extra={
                "destination_event_ids": event_ids,
                "source_event_id": source_event_id,
            },
        )
        return {"eventIds": event_ids, "status": "PUBLISHED"}
    except Exception:
        metrics.add_metric(name="DispatchFailed", unit=MetricUnit.Count, value=1)
        logger.exception(
            "Failed to dispatch file actions",
            extra={"source_event_id": source_event_id},
        )
        raise