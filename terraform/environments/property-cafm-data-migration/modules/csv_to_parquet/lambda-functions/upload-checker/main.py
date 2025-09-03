import json
import logging
import os
import boto3
from datetime import datetime, timezone

logger = logging.getLogger()
logger.setLevel(os.getenv("LOG_LEVEL", "INFO"))

stepfunctions = boto3.client("stepfunctions")
state_machine_arn = os.environ["STATE_MACHINE_ARN"]


def handler(event, context):
    try:
        record = event["Records"][0]
        bucket = record["s3"]["bucket"]["name"]
        key = record["s3"]["object"]["key"]

        logger.info(f"File uploaded: s3://{bucket}/{key}")

        extraction_timestamp = datetime.now(timezone.utc).strftime("%Y%m%d%H%M%SZ")

        state_machine_input_payload = {
            "csv_upload_bucket": bucket,
            "csv_upload_key": key,
            "extraction_timestamp": extraction_timestamp,
            "output_bucket": os.environ["OUTPUT_BUCKET"],
            "name": os.environ["NAME"],
        }

        # Start Step Function with file info
        response = stepfunctions.start_execution(
            stateMachineArn=state_machine_arn,
            input=json.dumps(state_machine_input_payload),
        )

        logger.info(f"Step Function started: {response['executionArn']}")
    except Exception as e:
        logger.error(f"Error triggering Step Function: {str(e)}")
        raise
