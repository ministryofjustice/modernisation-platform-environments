import json
import os
from datetime import datetime, timezone

import boto3
from botocore.config import Config
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
    build_requested_event_detail,
    find_dispatch_configuration,
    parse_file_routed_event,
)


eventbridge = boto3.client("events")
# Bounded so a DynamoDB stall in the best-effort latency lookup can't run into the Lambda timeout.
dynamodb = boto3.client(
    "dynamodb",
    config=Config(connect_timeout=2, read_timeout=2, retries={"max_attempts": 2}),
)
secretsmanager = boto3.client("secretsmanager")
logger = Logger(service="file-action-execution-requested-adapter")
metrics = Metrics(service="file-action-execution-requested-adapter")
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


def _received_at(correlation_id):
    """Return the time the file landed in incoming, from its STAGE record."""
    item = dynamodb.get_item(
        TableName=os.environ["WORKFLOW_IDEMPOTENCY_TABLE"],
        ConsistentRead=True,
        Key={
            "concurrencyId": {"S": correlation_id},
            "operation": {"S": "STAGE"},
        },
    ).get("Item")
    if not item:
        return None
    if "received_at" in item:
        return datetime.fromisoformat(item["received_at"]["S"].replace("Z", "+00:00"))
    # Records written before received_at was stored: the claim time is within
    # moments of the landing time.
    if "created_at" in item:
        return datetime.fromtimestamp(int(item["created_at"]["N"]), timezone.utc)
    return None


def _record_end_to_end_latency(correlation_id, published_at, log_context):
    try:
        received_at = _received_at(correlation_id)
        if received_at is None:
            logger.warning("No landing time found for latency", extra=log_context)
            return
        latency_seconds = max((published_at - received_at).total_seconds(), 0)
        metrics.add_metric(
            name="EndToEndLatency", unit=MetricUnit.Seconds, value=latency_seconds
        )
    except Exception:
        logger.exception("Failed to record end-to-end latency", extra=log_context)


def _publish(entry):
    response = eventbridge.put_events(Entries=[entry])
    if response.get("FailedEntryCount", 0) > 0:
        raise RuntimeError(
            f"Failed to publish {REQUESTED_DETAIL_TYPE} event: {response['Entries']}"
        )

    return response["Entries"][0]["EventId"]


@logger.inject_lambda_context(clear_state=True, log_event=False)
@metrics.log_metrics
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
            _record_end_to_end_latency(
                routed_file.correlation_id, datetime.now(timezone.utc), log_context
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
            _record_end_to_end_latency(
                routed_file.correlation_id, requested_at, log_context
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
        _record_end_to_end_latency(
            routed_file.correlation_id, requested_at, log_context
        )
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