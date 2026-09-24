import json
import os

import boto3
from aws_lambda_powertools import Logger
from aws_lambda_powertools.utilities.idempotency import (
    DynamoDBPersistenceLayer,
    IdempotencyConfig,
    idempotent_function,
)
from file_mover import FileMover, batch_response
from terminal_outcome import TerminalOutcomes

logger = Logger()
events = boto3.client("events")
secrets = boto3.client("secretsmanager")
sts = boto3.client("sts")
outcomes = TerminalOutcomes(
    boto3.resource("dynamodb").Table(os.environ["IDEMPOTENCY_TABLE"]),
    int(os.environ["IDEMPOTENCY_EXPIRY_SECONDS"]),
)


def delivery_client(role_arn, region):
    response = sts.assume_role(
        RoleArn=role_arn,
        RoleSessionName="push-to-s3-delivery",
        DurationSeconds=900,
    )
    credentials = response["Credentials"]
    return boto3.client(
        "s3",
        region_name=region,
        aws_access_key_id=credentials["AccessKeyId"],
        aws_secret_access_key=credentials["SecretAccessKey"],
        aws_session_token=credentials["SessionToken"],
    )


file_mover = FileMover(
    secrets=secrets,
    events=events,
    delivery_client_factory=delivery_client,
    authorised_destination_map=json.loads(os.environ["AUTHORISED_DESTINATION_MAP"]),
    delivery_role_map=json.loads(os.environ["DELIVERY_ROLE_MAP"]),
    source_prefix_map=json.loads(os.environ["SOURCE_PREFIX_MAP"]),
    event_bus_name=os.environ["EVENT_BUS_NAME"],
    supported_region=os.environ["SUPPORTED_REGION"],
    outcomes=outcomes,
)
persistence_layer = DynamoDBPersistenceLayer(table_name=os.environ["IDEMPOTENCY_TABLE"])
idempotency_config = IdempotencyConfig(
    event_key_jmespath="detail.data.actionExecutionId",
    payload_validation_jmespath='[source, "detail-type", account, detail]',
    raise_on_no_idempotency_key=True,
    expires_after_seconds=int(os.environ["IDEMPOTENCY_EXPIRY_SECONDS"]),
)


@idempotent_function(
    data_keyword_argument="event",
    persistence_store=persistence_layer,
    config=idempotency_config,
    key_prefix="managed-file-transfer/push-to-s3",
)
def process_event(*, event):
    return file_mover.process(event)


@logger.inject_lambda_context(clear_state=True, log_event=False)
def lambda_handler(event, _context):
    idempotency_config.register_lambda_context(_context)
    response = batch_response(event.get("Records", []), lambda item: process_event(event=item))
    logger.info(
        "Processed push-to-s3 batch",
        extra={
            "record_count": len(event.get("Records", [])),
            "failed_record_count": len(response["batchItemFailures"]),
        },
    )
    return response