import json
import os

import boto3
from aws_lambda_powertools import Logger
from dlq_reporter import DLQReporter
from terminal_outcome import TerminalOutcomes

logger = Logger()
reporter = DLQReporter(
    outcomes=TerminalOutcomes(
        boto3.resource("dynamodb").Table(os.environ["IDEMPOTENCY_TABLE"]),
        int(os.environ["IDEMPOTENCY_EXPIRY_SECONDS"]),
    ),
    events=boto3.client("events"),
    event_bus_name=os.environ["EVENT_BUS_NAME"],
    queue_arns=json.loads(os.environ["DLQ_ARNS"]),
)


@logger.inject_lambda_context(clear_state=True, log_event=False)
def lambda_handler(event, _context):
    records = event.get("Records", [])
    response = reporter.handle_batch(records)
    logger.info(
        "Processed push-to-s3 dead letters",
        extra={"record_count": len(records), "failed_record_count": len(response["batchItemFailures"])},
    )
    return response