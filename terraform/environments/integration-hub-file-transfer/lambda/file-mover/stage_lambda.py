import os

import boto3
from aws_lambda_powertools import Logger
from aws_lambda_powertools.utilities.idempotency import (
    DynamoDBPersistenceLayer,
    IdempotencyConfig,
    idempotent,
)

from mft_file_mover.config import Configuration
from mft_file_mover.s3_copy import S3CopyEngine
from mft_file_mover.service import FileMoverService
from mft_file_mover.store import OperationStore


config = Configuration.for_stage()
logger = Logger(service="integration-hub-file-transfer-stage")
persistence_layer = DynamoDBPersistenceLayer(table_name=os.environ["IDEMPOTENCY_TABLE"])
idempotency_config = IdempotencyConfig(
    event_key_jmespath="id",
    payload_validation_jmespath='[source, "detail-type", detail]',
    raise_on_no_idempotency_key=True,
    expires_after_seconds=config.idempotency_expiry_seconds,
)
service = FileMoverService(
    operation="STAGE",
    config=config,
    store=OperationStore(boto3.resource("dynamodb").Table(config.operation_table_name)),
    copy_engine=S3CopyEngine(
        boto3.client("s3"),
        config.account_id,
        config.part_size_bytes,
        config.maximum_parts,
        config.multipart_workers,
    ),
    eventbridge=boto3.client("events"),
    logger=logger,
)


@logger.inject_lambda_context(clear_state=True, log_event=False)
@idempotent(
    persistence_store=persistence_layer,
    config=idempotency_config,
    key_prefix="managed-file-transfer/stage",
)
def lambda_handler(event, context):
    try:
        result = service.handle(event, context)
        logger.info(
            "STAGE operation handled",
            extra={"source_event_id": event.get("id"), **result},
        )
        return result
    except Exception:
        logger.exception(
            "STAGE operation failed",
            extra={"source_event_id": event.get("id")},
        )
        raise