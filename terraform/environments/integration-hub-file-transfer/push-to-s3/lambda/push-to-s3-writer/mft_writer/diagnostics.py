import os
import re
import traceback
from collections.abc import Mapping
from contextlib import contextmanager
from typing import Any

from aws_lambda_powertools import Logger
from botocore.exceptions import ClientError

from mft_writer.errors import AwsResponseError

DEADLINE_SAFETY_MILLIS = 90_000
logger = Logger(service=os.environ.get("POWERTOOLS_SERVICE_NAME", "push-to-s3-writer"))


def _sanitised_error_text(value: Any) -> str | None:
    if not isinstance(value, str):
        return None
    redacted = re.sub(r"(?i)arn:aws[^\s,]*", "[redacted-resource]", value)
    redacted = re.sub(r"(?i)(AKIA|ASIA)[A-Z0-9]{12,}", "[redacted-credential]", redacted)
    redacted = re.sub(r"[^A-Za-z0-9 .,:_/-]", " ", redacted)
    return " ".join(redacted.split())[:240] or None


def _aws_error_fields(error: Exception) -> dict[str, Any]:
    if isinstance(error, AwsResponseError):
        return error.fields
    if not isinstance(error, ClientError):
        return {
            "awsErrorCode": None,
            "awsErrorMessage": None,
            "httpStatusCode": None,
            "awsRequestId": None,
            "hostId": None,
            "retryCount": None,
            "retryable": isinstance(error, (TimeoutError, ConnectionError)),
        }
    response = error.response
    metadata = response.get("ResponseMetadata", {})
    error_details = response.get("Error", {})
    status = metadata.get("HTTPStatusCode")
    code = error_details.get("Code")
    return {
        "awsErrorCode": code,
        "awsErrorMessage": _sanitised_error_text(error_details.get("Message")),
        "httpStatusCode": status,
        "awsRequestId": metadata.get("RequestId"),
        "hostId": error_details.get("HostId"),
        "retryCount": metadata.get("RetryAttempts"),
        "retryable": status == 429
        or (isinstance(status, int) and status >= 500)
        or code in {"InternalError", "RequestTimeout", "RequestTimeoutException", "SlowDown", "Throttling", "ThrottlingException", "ServiceUnavailable"},
    }


def _sanitised_trace(error: Exception) -> list[str]:
    return traceback.format_tb(error.__traceback__)


@contextmanager
def structured_record_context(fields: Mapping[str, Any]):
    logger.append_keys(**dict(fields))
    try:
        yield
    finally:
        logger.remove_keys(list(fields))


def _update_log_fields(fields: dict[str, Any] | None, **values: Any) -> None:
    if fields is not None:
        fields.update(values)
        logger.append_keys(**values)


def _remaining_millis(context: Any) -> int:
    if context is None or not hasattr(context, "get_remaining_time_in_millis"):
        return 900_000
    return int(context.get_remaining_time_in_millis())


def ensure_time(context: Any, operation: str) -> None:
    if _remaining_millis(context) <= DEADLINE_SAFETY_MILLIS:
        raise TimeoutError(f"insufficient Lambda time remaining before {operation}")