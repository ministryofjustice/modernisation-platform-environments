"""
AWS Lambda function to pull CloudWatch Alarm from SNS Topic and publish
into Slack. This will also publish GuardDuty findings, EventBridge events
and S3 events into Slack.
"""

import functools
import json
import os
import logging
import time
import tracemalloc
import urllib.request
import urllib.error
import urllib.parse
from dataclasses import dataclass
from enum import StrEnum
from typing import TYPE_CHECKING, Any
from datetime import datetime, timezone, timedelta
import boto3
from botocore.exceptions import ClientError

if TYPE_CHECKING:
    from mypy_boto3_secretsmanager import SecretsManagerClient

type SecretsData = dict[str, str | int | bool]
type Payload = dict[str, Any]  # a Slack Block Kit message: {"blocks": [...]}


# Environment configuration.
# Every value read from the Lambda environment is declared here for discoverability.

# NOTE: SECRET_NAME is the one exception — it is resolved per-invocation in
# lambda_handler (it may also be supplied by the event payload), so it is read
# there rather than as a module constant.

# DEBUG mode: raises the log level to DEBUG and enables tracemalloc reporting.
# DEFAULT: false
_DEBUG = os.environ.get("DEBUG", "").lower() in {"1", "true", "yes"}

# CloudWatch EMF metrics: namespace + on/off switch (see _emit_metric). Emitted as
# pure-JSON stdout lines, auto-extracted by CloudWatch Logs (no PutMetricData, no IAM).
# # DEFAULT: CcmsEbs/SlackNotifier
_METRICS_NAMESPACE = os.environ.get("METRICS_NAMESPACE", "CcmsEbs/SlackNotifier")
# DEFAULT: true
_METRICS_ENABLED = os.environ.get("METRICS_ENABLED", "true").lower() in {"1", "true", "yes", "on"}

# When on, an SNS message we can't classify is surfaced to Slack as a fallback
# notification (build_fallback) instead of being silently skipped.
# DEFAULT: true
_NOTIFY_UNRECOGNISED = os.environ.get("NOTIFY_UNRECOGNISED", "true").lower() in {"1", "true", "yes", "on"}

# Suppression: which environments, and the raw HH:MM window bounds (semantics and
# validation are in the suppression section below).
# Empty SUPPRESSED_ENVIRONMENTS disables suppression.
# DEFAULT: "dev-,test-,prep-"
_SUPPRESSED_ENVIRONMENTS = tuple(
    p.strip() for p in os.environ.get("SUPPRESSED_ENVIRONMENTS", "dev-,test-,prep-").split(",") if p.strip()
)
# DEFAULT: 19:00
_SUPPRESSION_TIME_START = os.environ.get("SUPPRESSION_TIME_START", "19:00")
# DEFAULT: 07:00
_SUPPRESSION_TIME_END = os.environ.get("SUPPRESSION_TIME_END", "07:00")

logger = logging.getLogger()
logger.setLevel(logging.DEBUG if _DEBUG else logging.INFO)


def _emit_metric(name: str, event_type: str, value: int = 1) -> None:
    """Emit one CloudWatch EMF metric line (Count, dimensioned by EventType) to stdout.

    EMF requires a pure-JSON log line, so this uses `print` (the logging formatter would
    corrupt the JSON). No-op when METRICS_ENABLED is off.
    """
    if not _METRICS_ENABLED:
        return
    print(
        json.dumps(
            {
                "_aws": {
                    "Timestamp": int(time.time() * 1000),
                    "CloudWatchMetrics": [
                        {
                            "Namespace": _METRICS_NAMESPACE,
                            "Dimensions": [["EventType"]],
                            "Metrics": [{"Name": name, "Unit": "Count"}],
                        }
                    ],
                },
                "EventType": str(event_type),
                name: value,
            }
        )
    )


class SecretRetrievalError(Exception):
    """Raised when a secret cannot be retrieved or parsed from Secrets Manager."""


class SlackNotificationError(Exception):
    """Raised when posting a notification to Slack fails."""


class Source(StrEnum):
    """The AWS event `source` values this Lambda routes on."""

    GUARDDUTY = "aws.guardduty"
    S3 = "aws.s3"
    ACM = "aws.acm"
    CLOUDWATCH = "aws.cloudwatch"


class EventType(StrEnum):
    """The notification type handed to the payload builders / dispatch."""

    GUARDDUTY = "GuardDuty"
    CLOUDWATCH = "CloudWatch Alarm"
    S3 = "S3 Event"
    CERT = "Certificate Expiry"
    UNKNOWN = "Unknown"


# Suppression semantics (all times UTC; config is read in the env block at the top).
# CloudWatch alarms whose AlarmName starts with one of SUPPRESSED_ENVIRONMENTS are
# suppressed while the alarm time falls within the [START, END) window — silencing
# expected overnight noise from non-prod environments whose instances are stopped.
#   START <  END : same-day window
#   START >  END : overnight window (wraps past midnight)
#   START == END : 24-hour window (suppress all day, e.g. a holiday shutdown)
# If a SUPPRESSION_TIME_* value is invalid, suppression is disabled (fail-safe —
# alerts still flow) and affected notifications carry a config-error note so the
#  operator fixes it.

def _parse_hhmm(value: str | None) -> int | None:
    """Parse 'H:MM'/'HH:MM' into minutes since midnight [0, 1440); None if invalid."""
    if not value:
        return None
    parts = value.strip().split(":")
    if len(parts) != 2:
        return None
    try:
        hours, minutes = int(parts[0]), int(parts[1])
    except ValueError:
        return None
    if 0 <= hours <= 23 and 0 <= minutes <= 59:
        return hours * 60 + minutes
    return None


def _in_suppression_window(minute_of_day: int, start: int, end: int) -> bool:
    """Is `minute_of_day` (minutes since midnight) within the [start, end) window?

    start <  end : same-day window.
    start >  end : overnight window (wraps past midnight).
    start == end : 24-hour window (suppress all day, e.g. holiday shutdown).
    """
    if start == end:
        return True
    if start < end:
        return start <= minute_of_day < end
    return minute_of_day >= start or minute_of_day < end


def _load_suppression_config() -> tuple[tuple[int, int] | None, str | None]:
    """Return (window, config_error).

    `window` is (start_minute, end_minute), or None when a SUPPRESSION_TIME_* value
    is invalid (suppression disabled, fail-safe). `config_error` names the offending
    variable(s) for the operator, or is None when the config is valid.
    """
    start, end = _parse_hhmm(_SUPPRESSION_TIME_START), _parse_hhmm(_SUPPRESSION_TIME_END)

    bad = []
    if start is None:
        bad.append(f"SUPPRESSION_TIME_START={_SUPPRESSION_TIME_START!r}")
    if end is None:
        bad.append(f"SUPPRESSION_TIME_END={_SUPPRESSION_TIME_END!r}")
    if bad:
        error = f"Invalid {' and '.join(bad)} (expected HH:MM) — suppression mechanism inactive."
        logger.warning(error)
        return None, error

    assert start is not None and end is not None  # for the type checker; `bad` is empty here
    return (start, end), None


_SUPPRESSION_WINDOW, _SUPPRESSION_CONFIG_ERROR = _load_suppression_config()

if not _SUPPRESSED_ENVIRONMENTS:
    logger.info("Suppression off: SUPPRESSED_ENVIRONMENTS is empty")
elif _SUPPRESSION_WINDOW is not None:
    _start_min, _end_min = _SUPPRESSION_WINDOW
    logger.info(
        "Suppression active: environments=%s, window=%02d:%02d–%02d:%02d UTC%s",
        _SUPPRESSED_ENVIRONMENTS,
        _start_min // 60,
        _start_min % 60,
        _end_min // 60,
        _end_min % 60,
        " [24h/all-day]" if _start_min == _end_min else "",
    )


@dataclass
class ValidateConfig:
    """The three mandatory Slack webhook URLs, validated on construction."""

    slack_channel_webhook: str
    slack_channel_webhook_guardduty: str
    slack_channel_webhook_s3: str

    @classmethod
    def from_secrets(cls, secrets: SecretsData) -> ValidateConfig:
        """Extract and validate the three mandatory webhooks from a Secrets Manager payload."""

        def mandatory(key: str) -> str:
            value = secrets.get(key)
            if not value or not isinstance(value, str):
                raise ValueError(f"{key} must be a non-empty string in secrets, got: {value!r}")
            return value

        config = cls(
            slack_channel_webhook=mandatory("slack_channel_webhook"),
            slack_channel_webhook_guardduty=mandatory("slack_channel_webhook_guardduty"),
            slack_channel_webhook_s3=mandatory("slack_channel_webhook_s3"),
        )
        logger.info("Configuration validated")
        return config


@functools.cache
def _secretsmanager() -> SecretsManagerClient:
    """The Secrets Manager client — created once and reused across warm invocations."""
    logger.info("Initialized Secrets Manager client")
    return boto3.client("secretsmanager")


@functools.cache
def get_credentials(secret_name: str) -> SecretsData:
    """Retrieve and parse a secret from Secrets Manager.

    Cached for the container lifetime (the Slack webhooks rarely rotate; switch to a
    TTL cache if that changes). On a cold cache the value is fetched once; warm
    invocations reuse it. Failures are not cached, so they retry on the next call.
    """
    client = _secretsmanager()
    try:
        logger.info("Retrieving secret: %s", secret_name)
        response = client.get_secret_value(SecretId=secret_name)

        # Parse the secret string
        secret_data = json.loads(response["SecretString"])
        logger.info("Successfully retrieved credentials with %d keys", len(secret_data))

        return secret_data

    except ClientError as e:
        error_code = e.response["Error"]["Code"]
        error_msg = f"Failed to retrieve secret {secret_name}: {error_code}"
        logger.error(error_msg)
        raise SecretRetrievalError(error_msg) from e
    except json.JSONDecodeError as e:
        error_msg = f"Failed to parse secret JSON: {e}"
        logger.error(error_msg)
        raise SecretRetrievalError(error_msg) from e


_MAX_SECTION_TEXT = 2900  # Slack mrkdwn section limit is 3000; leave headroom for the ``` fences


def _truncate(text: str, limit: int = _MAX_SECTION_TEXT) -> str:
    """Truncate text to `limit` chars (plus a marker) so it fits within a Slack block."""
    if len(text) <= limit:
        return text
    return text[:limit] + "\n… (truncated)"


_MAX_POST_ATTEMPTS = 3  # total tries
_BACKOFF_BASE_SECONDS = 0.5  # 0.5s, then 1.0s between attempts
_RETRY_AFTER_CAP_SECONDS = 10  # cap a server-supplied Retry-After
_RETRY_DEADLINE_SECONDS = 25  # overall transport budget (Lambda timeout is 30s)


def _parse_retry_after(value: str | None) -> float | None:
    """Parse a Retry-After header (delta-seconds form) into capped seconds.

    Returns None for the HTTP-date form or unparseable values, so the caller falls
    back to exponential backoff.
    """
    if not value:
        return None
    try:
        return min(float(value), _RETRY_AFTER_CAP_SECONDS)
    except ValueError:
        return None


def _post(url: str, payload: dict, timeout: int = 10) -> int:
    """POST `payload` as JSON to `url`; return the HTTP status code.

    Transient failures are retried inside an overall deadline: HTTP 429 (honouring
    Retry-After), 5xx, and network errors (DNS/connection/timeout). Non-retryable 4xx
    are returned immediately. When retries are exhausted, the last HTTP status is
    returned (>= 400, so the caller treats it as failure) or the network error is
    re-raised. Each attempt's timeout is capped by the remaining budget so the total
    stays under the Lambda timeout.

    Note: retrying makes delivery at-least-once — if Slack accepted a post but the
    response was lost, a retry double-posts. For alerts a duplicate beats a drop.
    """
    data = json.dumps(payload).encode()
    req = urllib.request.Request(url, data=data, headers={"Content-Type": "application/json"}, method="POST")
    deadline = time.monotonic() + _RETRY_DEADLINE_SECONDS
    status: int | None = None
    error: Exception | None = None

    for attempt in range(1, _MAX_POST_ATTEMPTS + 1):
        remaining = deadline - time.monotonic()
        if remaining <= 0:
            break
        retry_after = None
        try:
            with urllib.request.urlopen(req, timeout=min(timeout, remaining)) as resp:
                return resp.status
        except urllib.error.HTTPError as e:
            if e.code != 429 and e.code < 500:
                return e.code  # non-retryable client error
            status, error = e.code, e
            retry_after = _parse_retry_after(e.headers.get("Retry-After"))
        except urllib.error.URLError as e:
            status, error = None, e  # network error — no HTTP status

        if attempt == _MAX_POST_ATTEMPTS:
            break
        delay = retry_after if retry_after is not None else _BACKOFF_BASE_SECONDS * 2 ** (attempt - 1)
        if time.monotonic() + delay > deadline:
            break
        logger.warning(
            "Slack post attempt %d/%d failed (status=%s); retrying in %.1fs",
            attempt,
            _MAX_POST_ATTEMPTS,
            status,
            delay,
        )
        time.sleep(delay)

    if status is not None:
        return status  # exhausted 429/5xx
    assert error is not None
    raise error  # exhausted network error — propagate


def format_event_time(raw: str | None, *, fallback: str | None = None) -> str:
    """Format an ISO-8601 timestamp as e.g. 'Mon, 22 Jun 2026 11:25:23 UTC'.

    Always includes the weekday so the Slack channel is quickly scannable. Accepts a
    trailing 'Z' and optional fractional seconds (via datetime.fromisoformat). Returns
    `fallback` (or the raw value, or 'N/A') when the value is missing or unparseable.
    """
    if not raw or raw == "N/A":
        return fallback or raw or "N/A"
    try:
        dt = datetime.fromisoformat(raw)
    except ValueError:
        logger.debug("Could not parse timestamp %r", raw)
        return fallback or raw
    return dt.strftime("%a, %d %b %Y %H:%M:%S UTC")


def format_expiry_date(raw_time: str | None, days: object) -> str | None:
    """Compute a certificate's expiry date as e.g. 'Thu, 09 Jul 2026'.

    Derived from the event time plus DaysToExpiry. Returns None if either input is
    unusable, so the caller can fall back to a generic 'expiring soon' message.
    """
    if not isinstance(raw_time, str) or not isinstance(days, (int, float)):
        return None
    try:
        base = datetime.fromisoformat(raw_time)
        return (base + timedelta(days=int(days))).strftime("%a, %d %b %Y")
    except ValueError:
        return None


_CONSOLE_BASE = "https://{region}.console.aws.amazon.com"  # commercial AWS (not GovCloud/China)


def _region_from_arn(arn: str) -> str | None:
    """Extract the region from an ARN (arn:aws:service:REGION:account:...)."""
    parts = arn.split(":")
    return parts[3] if len(parts) > 3 and parts[3] else None


def _cloudwatch_alarm_url(region: str | None, alarm_name: str) -> str | None:
    if not region or not alarm_name:
        return None
    base = _CONSOLE_BASE.format(region=region)
    return f"{base}/cloudwatch/home?region={region}#alarmsV2:alarm/{urllib.parse.quote(alarm_name, safe='')}"


def _guardduty_finding_url(region: str, finding_id: str) -> str | None:
    if not region or not finding_id:
        return None
    base = _CONSOLE_BASE.format(region=region)
    return (
        f"{base}/guardduty/home?region={region}#/findings?macros=current&fId={urllib.parse.quote(finding_id, safe='')}"
    )


def _s3_object_url(region: str, bucket: str, key: str) -> str | None:
    if not region or not bucket or not key:
        return None
    base = _CONSOLE_BASE.format(region=region)
    return f"{base}/s3/object/{urllib.parse.quote(bucket, safe='')}?region={region}&prefix={urllib.parse.quote(key, safe='')}"


def _link_button(text: str, url: str) -> dict[str, Any]:
    """A Slack `actions` block containing a single URL button."""
    return {
        "type": "actions",
        "elements": [{"type": "button", "text": {"type": "plain_text", "text": text}, "url": url}],
    }


def build_guardduty(details: dict) -> Payload:
    """Build the Slack payload for a GuardDuty finding."""
    detail = details.get("detail", {})
    severity = detail.get("severity", "Unknown Severity")
    if isinstance(severity, (int, float)):
        if severity < 4.0:
            emoji, strseverity = ":large_blue_circle:", "Low"
        elif severity < 7.0:
            emoji, strseverity = ":large_orange_circle:", "Medium"
        elif severity < 9.0:
            emoji, strseverity = ":small_red_triangle:", "High"
        else:
            emoji, strseverity = ":broken_heart:", "Critical"
    else:
        emoji, strseverity = ":grey_question:", "Unknown"

    finding_type = detail.get("type", "Unknown Finding")
    region = detail.get("region", "Unknown Region")
    account_id = detail.get("accountId", "Unknown Account")
    header = f"{emoji} | GuardDuty Finding | {region} | Account: {account_id}"
    description = detail.get("description", "No Title Provided")
    service = detail.get("service", {})
    threatcount = service.get("count", "N/A")
    firstseen = format_event_time(service.get("eventFirstSeen", "N/A"))
    lastseen = format_event_time(service.get("eventLastSeen", "N/A"))

    payload: Payload = {
        "blocks": [
            {"type": "header", "text": {"type": "plain_text", "text": header}},
            {"type": "section", "text": {"type": "mrkdwn", "text": f"*Finding Type* - {finding_type}"}},
            {"type": "section", "text": {"type": "mrkdwn", "text": "*Details*"}},
            {
                "type": "rich_text",
                "elements": [{"type": "rich_text_preformatted", "elements": [{"type": "text", "text": description}]}],
            },
            {"type": "divider"},
            {
                "type": "section",
                "fields": [
                    {"type": "mrkdwn", "text": f"*FirstSeen:* {firstseen}"},
                    {"type": "mrkdwn", "text": f"*LastSeen:* {lastseen}"},
                ],
            },
            {
                "type": "section",
                "fields": [
                    {"type": "mrkdwn", "text": f"*Severity:* {strseverity}"},
                    {"type": "mrkdwn", "text": f"*Threat Count:* {threatcount}"},
                ],
            },
        ]
    }
    url = _guardduty_finding_url(detail.get("region", ""), detail.get("id", ""))
    if url:
        payload["blocks"].append(_link_button("View finding in GuardDuty console", url))
    return payload


def build_cloudwatch(title: str, details: dict, timestamp: str, is_error: bool) -> Payload:
    """Build the Slack payload for a CloudWatch alarm."""
    alarm_name = details.get("AlarmName", "Unknown Alarm")
    region = details.get("Region", "")
    alarm_state = details.get("NewStateValue", "")
    reason = details.get("NewStateReason", "")
    trigger = details.get("Trigger", {})
    namespace = trigger.get("Namespace", "")
    metric_name = trigger.get("MetricName", "")
    dimensions = trigger.get("Dimensions", [])
    alarmdescription = details.get("AlarmDescription", "Alarm Description")

    dim_text = "\n".join([f"{d['name']} = {d['value']}" for d in dimensions])
    emoji = ":broken_heart:" if is_error else ":white_check_mark:"
    title = f"{emoji} | {title} | {alarm_name} | {region}"

    payload: Payload = {
        "blocks": [
            {"type": "header", "text": {"type": "plain_text", "text": f"{alarm_state} - {alarm_name}"}},
            {"type": "section", "text": {"type": "mrkdwn", "text": f"*{title}*"}},
            {"type": "divider"},
            {"type": "section", "text": {"type": "mrkdwn", "text": f"*Reason:* {reason}"}},
            {
                "type": "section",
                "fields": [
                    {"type": "mrkdwn", "text": f"*Namespace:* {namespace}"},
                    {"type": "mrkdwn", "text": f"*Metric:* {metric_name}"},
                ],
            },
            {
                "type": "section",
                "fields": [
                    {"type": "mrkdwn", "text": f"*Timestamp:* {timestamp}"},
                    {"type": "mrkdwn", "text": f"*Alarm Description:* {alarmdescription}"},
                ],
            },
            {"type": "section", "text": {"type": "mrkdwn", "text": f"*Resource Details:*\n {dim_text}"}},
        ]
    }

    url = _cloudwatch_alarm_url(_region_from_arn(details.get("AlarmArn", "")), alarm_name)
    if url:
        payload["blocks"].append(_link_button("View alarm in CloudWatch console", url))

    # Surface a broken suppression config on the alarms it would have governed, so the operator notices
    # and corrects the SUPPRESSION_TIME_* env vars.
    if _SUPPRESSION_CONFIG_ERROR and alarm_name.startswith(_SUPPRESSED_ENVIRONMENTS):
        payload["blocks"].append(
            {
                "type": "section",
                "text": {
                    "type": "mrkdwn",
                    "text": f":warning: *Suppression config error:* {_SUPPRESSION_CONFIG_ERROR}",
                },
            }
        )
    return payload


def build_s3(details: dict, timestamp: str) -> Payload:
    """Build the Slack payload for an S3 object event (detail or Records form)."""
    records = details.get("Records")
    if records:
        record = records[0]
        s3_info = record.get("s3", {})
        principal_id = record.get("userIdentity", {}).get("principalId", "Unknown Principal")
        region = record.get("awsRegion", "")
    else:
        s3_info = details.get("detail", {})
        principal_id = None  # detail form carries no principal
        region = details.get("region", "")  # EventBridge puts the region at the top level

    bucket_name = s3_info.get("bucket", {}).get("name", "Unknown Bucket")
    object_key = s3_info.get("object", {}).get("key", "Unknown Key")
    object_size = s3_info.get("object", {}).get("size", "Unknown Size")

    emoji = ":broken_heart:" if "rejected" in object_key.lower() else ":white_check_mark:"
    lines = [
        "*Details*",
        f" • *Object:* `s3://{bucket_name}/{object_key}`",
        f" • *Size (bytes):* {object_size} bytes",
    ]
    if principal_id is not None:
        lines.append(f" • *Principal:* {principal_id}")
    lines.append(f" • *Timestamp:* {timestamp}")

    payload: Payload = {
        "blocks": [
            {
                "type": "section",
                "text": {"type": "mrkdwn", "text": f"{emoji} *S3 Object Uploaded on bucket {bucket_name}.*"},
            },
            {"type": "section", "text": {"type": "mrkdwn", "text": "\n".join(lines)}},
        ]
    }
    url = _s3_object_url(region, bucket_name, object_key)
    if url:
        payload["blocks"].append(_link_button("View object in S3 console", url))
    return payload


def build_cert(details: dict) -> Payload:
    """Build the Slack payload for an ACM certificate-expiry event."""
    cert_info = details.get("detail", {})
    days_raw = cert_info.get("DaysToExpiry", "Unknown")
    try:
        days_to_expiry = int(float(days_raw))  # 17.0 -> 17
    except TypeError, ValueError:
        days_to_expiry = days_raw  # keep "Unknown" / unexpected as-is
    common_name = cert_info.get("CommonName", "Unknown")
    expiry_date = format_expiry_date(details.get("time"), days_to_expiry)
    emoji = ":rotating_light:"
    if expiry_date:
        header = f"{emoji} *Certificate {common_name} is expiring on {expiry_date}.*"
    else:
        header = f"{emoji} *Certificate {common_name} is expiring soon.*"

    return {
        "blocks": [
            {"type": "section", "text": {"type": "mrkdwn", "text": header}},
            {
                "type": "section",
                "text": {
                    "type": "mrkdwn",
                    "text": (f"*Details*\n • *Days to Expiry:* {days_to_expiry}\n • *Common Name:* {common_name}"),
                },
            },
        ]
    }


def build_fallback(title: str, details: dict) -> Payload:
    """Build a generic Slack payload for unrecognised / malformed events."""
    dump = _truncate(json.dumps(details, indent=2))
    return {
        "blocks": [
            {"type": "section", "text": {"type": "mrkdwn", "text": f"*{title}*"}},
            {"type": "section", "text": {"type": "mrkdwn", "text": f"```{dump}```"}},
        ]
    }


class NotificationService:
    """Service for sending notifications to Slack."""

    def __init__(self, webhook_url: str):
        if not webhook_url:
            raise ValueError("Slack webhook URL is required for notifications")

        self.webhook_url = webhook_url
        logger.info("Slack notifications configured")

    def send_notification(
        self, title: str, alarmdetails: dict, timestamp: str, event_type: str, is_error: bool = False
    ) -> bool:
        """Send a notification to Slack using the webhook."""
        logger.debug("alarmdetails: %s", alarmdetails)

        match event_type:
            case EventType.GUARDDUTY:
                payload = build_guardduty(alarmdetails)
            case EventType.CLOUDWATCH:
                payload = build_cloudwatch(title, alarmdetails, timestamp, is_error)
            case EventType.S3:
                payload = build_s3(alarmdetails, timestamp)
            case EventType.CERT if not alarmdetails.get("Records"):
                payload = build_cert(alarmdetails)
            case _:
                payload = build_fallback(title, alarmdetails)

        try:
            logger.debug("Prepared Slack payload: %s", payload)

            http_code = _post(self.webhook_url, payload)
            if http_code >= 400:
                raise SlackNotificationError(f"HTTP error {http_code}")

            logger.info("Slack notification sent successfully: %s", title)
            return True

        except Exception as e:
            logger.error("Failed to send Slack notification: %s", e, exc_info=True)
            return False


def _extract_message(event: dict) -> tuple[str, dict] | None:
    """Pull the notification message and SNS envelope out of the raw event.

    Returns (message_str, sns_message), or None to skip — an SNS control message or an
    unrecognised event shape. sns_message is {} for EventBridge (non-SNS) events.
    """
    records = event.get("Records")
    if records and "Sns" in records[0]:
        sns_message = records[0]["Sns"]
        message_str = sns_message["Message"]
        logger.debug("SNS message: %s", message_str)
        sns_type = sns_message.get("Type", "")
        if sns_type in ("SubscriptionConfirmation", "UnsubscribeConfirmation"):
            logger.info("Ignoring SNS control message Type=%s", sns_type)
            return None
        return message_str, sns_message

    detail = event.get("detail")
    if detail and "CommonName" in detail:
        logger.debug("Certificate %s expires in %s days", detail["CommonName"], detail.get("DaysToExpiry", "N/A"))
        return json.dumps(event), {}

    logger.warning(
        "Event matched no known shape (no SNS record, no EventBridge certificate detail); skipping notification."
    )
    return None


def _looks_like_cloudwatch_alarm(details: dict) -> bool:
    """CloudWatch Alarm SNS payloads often lack a 'source'; detect them by shape."""
    return isinstance(details, dict) and "AlarmName" in details and "NewStateValue" in details


def _detect_source(alarm_details: dict) -> str | None:
    """Return the routing source, or None if the event shape is unrecognised."""
    source = alarm_details.get("source")
    if not source and "Records" in alarm_details:
        first_record = alarm_details["Records"][0]
        if first_record.get("eventSource") == "aws:s3":
            source = Source.S3
    if not source:
        if _looks_like_cloudwatch_alarm(alarm_details):
            source = Source.CLOUDWATCH
        else:
            logger.warning(
                "Source not detected and payload does not look like a CloudWatch Alarm; skipping notification."
            )
            return None
    return source


def _s3_event_timestamp(alarm_details: dict) -> str | None:
    """The S3 event time — from the record (Records form) or top-level (detail form)."""
    records = alarm_details.get("Records")
    if records:
        return records[0].get("eventTime")
    return alarm_details.get("time")


def _should_suppress(alarm_name: str, alarm_time: datetime) -> bool:
    """True if a suppressed-environment alarm falls within the suppression window."""
    if _SUPPRESSION_WINDOW is None or not alarm_name.startswith(_SUPPRESSED_ENVIRONMENTS):
        return False
    if not _in_suppression_window(alarm_time.hour * 60 + alarm_time.minute, *_SUPPRESSION_WINDOW):
        return False
    start_min, end_min = _SUPPRESSION_WINDOW
    logger.info(
        "Suppressing alarm '%s' (suppressed environment) within suppression "
        "window %02d:%02d–%02d:%02d UTC (alarm at %02d:%02d). No Slack notification sent.",
        alarm_name,
        start_min // 60,
        start_min % 60,
        end_min // 60,
        end_min % 60,
        alarm_time.hour,
        alarm_time.minute,
    )
    return True


def lambda_handler(event: dict, context: Any) -> dict | None:
    """
    Main Lambda handler function.

    This function gets triggered by SNS Topic subscriptions to CloudWatch Alarms,
    GuardDuty findings, eventbridge and S3 events.
    """
    if _DEBUG:
        tracemalloc.start()

    notification_service = None
    formatted = datetime.now(timezone.utc).strftime("%a, %d %b %Y %H:%M:%S UTC")
    event_type = EventType.UNKNOWN
    is_error = True

    # Get secret name from environment or event
    secret_name = os.environ.get("SECRET_NAME", event.get("secret_name"))
    if not secret_name:
        raise ValueError("SECRET_NAME not found in environment or event")
    if not isinstance(secret_name, str):
        raise ValueError(f"SECRET_NAME must be a string, got: {type(secret_name).__name__}")

    secrets_data = get_credentials(secret_name)
    config = ValidateConfig.from_secrets(secrets_data)

    extracted = _extract_message(event)
    if extracted is None:
        _emit_metric("EventsSkipped", EventType.UNKNOWN)
        return None
    message_str, sns_message = extracted

    try:
        alarm_details = json.loads(message_str)
        logger.debug("alarm_details: %s", alarm_details)

        source = _detect_source(alarm_details)
        if source is None and not _NOTIFY_UNRECOGNISED:
            _emit_metric("EventsSkipped", EventType.UNKNOWN)
            return None
        logger.info("source: %s", source)

        match source:
            case Source.GUARDDUTY:
                formatted = format_event_time(alarm_details.get("time"), fallback=formatted)
                channelconfig = config.slack_channel_webhook_guardduty
                alarmnotification = "GuardDuty Finding Notification"
                event_type = EventType.GUARDDUTY
                is_error = True  # usually "bad" findings

            case Source.S3:
                formatted = format_event_time(_s3_event_timestamp(alarm_details), fallback=formatted)
                channelconfig = config.slack_channel_webhook_s3
                alarmnotification = "S3 Object Event Notification"
                event_type = EventType.S3
                is_error = False  # S3 put is informational

            case Source.ACM:
                formatted = format_event_time(alarm_details.get("time"), fallback=formatted)
                channelconfig = config.slack_channel_webhook
                alarmnotification = "Certificate Expiry Notification"
                event_type = EventType.CERT
                is_error = False  # Certificate expiry is informational

            case None:  # unclassifiable SNS message; NOTIFY_UNRECOGNISED is on → surface it
                _emit_metric("UnrecognisedEvents", EventType.UNKNOWN)
                channelconfig = config.slack_channel_webhook
                alarmnotification = "Unrecognised event received"
                event_type = EventType.UNKNOWN
                is_error = True

            case _:  # CloudWatch (default; also catches unknown sources)
                alarm_time = datetime.now(timezone.utc)  # fallback if timestamp is missing
                timestamp_str = sns_message.get("Timestamp")
                if timestamp_str:
                    formatted = format_event_time(timestamp_str, fallback=formatted)
                    try:
                        alarm_time = datetime.fromisoformat(timestamp_str)
                    except ValueError:
                        pass  # keep now() fallback; format_event_time already logged

                if _should_suppress(alarm_details.get("AlarmName", ""), alarm_time):
                    _emit_metric("AlarmsSuppressed", EventType.CLOUDWATCH)
                    return None

                channelconfig = config.slack_channel_webhook
                alarmnotification = "CloudWatch Alarm Notification"
                event_type = EventType.CLOUDWATCH
                is_error = alarm_details.get("NewStateValue", "") != "OK"

        # Initialize services
        notification_service = NotificationService(channelconfig)

        delivered = notification_service.send_notification(
            alarmnotification, alarm_details, formatted, event_type, is_error
        )
        if not delivered:
            # Fail the invocation so Lambda routes the event to the on-failure DLQ
            # rather than silently dropping the alert.
            _emit_metric("NotificationsFailed", event_type)
            raise SlackNotificationError(f"Slack delivery failed for {event_type} after retries")
        _emit_metric("NotificationsSent", event_type)

        # Prepare response
        response = {
            "statusCode": 200,
            "body": {"message": "Successfully completed publishing notifications"},
        }

        logger.info("Lambda execution completed successfully: %s", response)
        return response

    except Exception as e:
        error_msg = f"Lambda execution failed:\n{str(e)}"
        logger.error(error_msg, exc_info=True)

        # Best-effort: try to post an error notification to Slack.
        if notification_service is not None:
            try:
                notification_service.send_notification(
                    "Lambda Execution Failed", {"error": error_msg}, formatted, event_type, is_error=True
                )
            except Exception as notification_error:
                logger.error("Failed to send error notification: %s", notification_error)

        # Re-raise so the invocation fails and Lambda dead-letters the event.
        raise
    finally:
        if _DEBUG:
            current, peak = tracemalloc.get_traced_memory()
            logger.debug(
                "Memory usage: %.2f MB; Peak: %.2f MB",
                current / 1024 / 1024,
                peak / 1024 / 1024,
            )
            tracemalloc.stop()
