"""SQS dead-letter terminal outcome reporter Lambda entry point."""

from runtime import logger, metrics, process_reporter_event


@logger.inject_lambda_context(clear_state=True, log_event=False)
@metrics.log_metrics(capture_cold_start_metric=True)
def lambda_handler(event, context):
    return process_reporter_event(event, context)