import base64
import gzip
import json
import logging
import os
import urllib.request
from datetime import datetime

import boto3

logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Caches the Slack webhook URL for reuse within a Lambda container.
SLACK_WEBHOOK_URL_CACHE = None

# Sidebar colours used to signal the kind of change at a glance.
COLOUR_ALERT = "#E01E5A"
COLOUR_CHANGE = "#FFA500"
COLOUR_OK = "#2EB67D"
COLOUR_FAILED = "#808080"

# Header title and emoji for each CloudTrail event source.
EVENT_SOURCE_STYLES = {
    "secretsmanager.amazonaws.com": (":key:", "EDW DB Credentials Secret Change"),
    "rds.amazonaws.com": (":file_cabinet:", "EDW RDS Instance Change"),
}

# Request parameters that change the master password on the instance directly.
RDS_PASSWORD_PARAMETERS = ("masterUserPassword", "manageMasterUserPassword", "rotateMasterUserPassword")

# Request parameters worth showing for Secrets Manager calls. Secret values are never logged by CloudTrail.
SECRET_PARAMETERS = (
    ("versionStages", "Version stages"),
    ("versionStage", "Version stage"),
    ("moveToVersionId", "Move to version"),
    ("removeFromVersionId", "Remove from version"),
    ("kmsKeyId", "KMS key"),
    ("rotationLambdaARN", "Rotation Lambda"),
    ("recoveryWindowInDays", "Recovery window (days)"),
    ("forceDeleteWithoutRecovery", "Force delete without recovery"),
)


def get_secret(secret_name: str) -> str:
    client = boto3.client("secretsmanager")
    response = client.get_secret_value(SecretId=secret_name)
    secret_value = response.get("SecretString", "")

    if not secret_value:
        raise ValueError(f"Secret {secret_name} is empty")

    try:
        parsed = json.loads(secret_value)
        if isinstance(parsed, dict):
            webhook = (
                parsed.get("webhook_url")
                or parsed.get("slack_webhook_url")
                or parsed.get("url")
            )
            if webhook:
                return webhook
        return str(parsed)
    except json.JSONDecodeError:
        return secret_value


def get_webhook_url() -> str:
    global SLACK_WEBHOOK_URL_CACHE
    if not SLACK_WEBHOOK_URL_CACHE:
        SLACK_WEBHOOK_URL_CACHE = get_secret(os.environ["SLACK_WEBHOOK_SECRET"])
    if not SLACK_WEBHOOK_URL_CACHE:
        raise ValueError("Slack webhook URL not configured")
    return SLACK_WEBHOOK_URL_CACHE


def _escape(value) -> str:
    """Escapes the characters Slack mrkdwn treats as control characters."""
    return str(value).replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")


def _format_time(timestamp: str | None) -> str:
    if not timestamp:
        return "unknown"
    try:
        # CloudWatch alarms use "+0000" offsets, CloudTrail uses "Z".
        normalised = timestamp.replace("Z", "+00:00").replace("+0000", "+00:00")
        parsed = datetime.fromisoformat(normalised)
        return parsed.strftime("%d %b %Y %H:%M:%S UTC")
    except ValueError:
        return timestamp


def _changes_db_password(detail: dict) -> bool:
    params = detail.get("requestParameters") or {}
    return any(key in params for key in RDS_PASSWORD_PARAMETERS)


def _colour_for(detail: dict) -> str:
    if detail.get("errorCode"):
        return COLOUR_FAILED
    if detail.get("eventSource") == "secretsmanager.amazonaws.com" or _changes_db_password(detail):
        return COLOUR_ALERT
    return COLOUR_CHANGE


def _describe_actor(user_identity: dict) -> str:
    """Turns a CloudTrail userIdentity into a short role/user name plus session."""
    identity_type = user_identity.get("type")
    arn = user_identity.get("arn", "")

    if identity_type == "AssumedRole":
        issuer = user_identity.get("sessionContext", {}).get("sessionIssuer", {})
        role_name = issuer.get("userName") or (arn.split("/")[-2] if arn.count("/") >= 2 else arn)
        session_name = arn.split("/")[-1] if "/" in arn else ""
        actor = f"*{_escape(role_name)}*"
        if session_name:
            actor += f"\nSession: `{_escape(session_name)}`"
        return actor
    if identity_type == "IAMUser":
        return f"*{_escape(user_identity.get('userName') or arn)}* (IAM user)"
    if identity_type == "Root":
        return "*root* :warning:"
    if identity_type == "AWSService":
        return f"*{_escape(user_identity.get('invokedBy', 'AWS service'))}*"
    return f"`{_escape(arn or 'unknown')}`"


def _describe_resources(detail: dict) -> list[str]:
    """Builds 'Label: value' lines for the resources touched by the API call."""
    params = detail.get("requestParameters") or {}
    lines = []

    # Secrets Manager
    if detail.get("eventSource") == "secretsmanager.amazonaws.com":
        if params.get("secretId"):
            lines.append(f"*Secret:* `{_escape(params['secretId'])}`")
        for key, label in SECRET_PARAMETERS:
            if key in params:
                lines.append(f"*{label}:* `{_escape(params[key])}`")

    # RDS
    if detail.get("eventSource") == "rds.amazonaws.com":
        if params.get("dBInstanceIdentifier"):
            lines.append(f"*DB instance:* `{_escape(params['dBInstanceIdentifier'])}`")
        if _changes_db_password(detail):
            lines.append(":rotating_light: *Master password change requested on the instance*")
        # Values are left out because CloudTrail masks some and others add noise.
        changed = sorted(key for key in params if key != "dBInstanceIdentifier")
        if changed:
            lines.append("*Changed settings:* " + ", ".join(f"`{_escape(key)}`" for key in changed))

    return lines or ["unknown"]


def _cloudtrail_url(region: str, event_id: str | None) -> str | None:
    if not event_id or not region:
        return None
    return (
        f"https://{region}.console.aws.amazon.com/cloudtrailv2/home"
        f"?region={region}#/events/{event_id}"
    )


def _build_message(colour: str, summary: str, blocks: list) -> dict:
    # Top-level text is what Slack shows in notifications and previews.
    return {"text": summary, "attachments": [{"color": colour, "blocks": blocks}]}


def _build_cloudtrail_message(payload: dict, account: str, environment: str) -> dict:
    detail = payload.get("detail", {})
    event_name = detail.get("eventName") or "unknown"
    event_source = detail.get("eventSource") or "unknown"
    region = detail.get("awsRegion") or payload.get("region") or os.environ.get("AWS_REGION", "")
    account = payload.get("account") or account
    error_code = detail.get("errorCode")

    emoji, title = EVENT_SOURCE_STYLES.get(event_source, (":bell:", "EDW AWS Change"))
    if event_source == "rds.amazonaws.com" and _changes_db_password(detail):
        emoji, title = (":rotating_light:", "EDW DB Master Password Changed")
    if error_code:
        title += " (failed)"

    fields = [
        {"type": "mrkdwn", "text": f"*Action:*\n`{_escape(event_name)}`"},
        {"type": "mrkdwn", "text": f"*Service:*\n{_escape(event_source)}"},
        {"type": "mrkdwn", "text": f"*Environment:*\n{_escape(environment)}"},
        {"type": "mrkdwn", "text": f"*Account:*\n{_escape(account)}"},
        {"type": "mrkdwn", "text": f"*Region:*\n{_escape(region or 'unknown')}"},
        {"type": "mrkdwn", "text": f"*Time:*\n{_format_time(detail.get('eventTime') or payload.get('time'))}"},
    ]

    blocks = [
        {
            "type": "header",
            "text": {"type": "plain_text", "text": f"{emoji} {title}", "emoji": True},
        },
        {"type": "divider"},
        {"type": "section", "fields": fields},
        {
            "type": "section",
            "text": {
                "type": "mrkdwn",
                "text": "*Resource:*\n" + "\n".join(_describe_resources(detail))[:2900],
            },
        },
        {
            "type": "section",
            "text": {"type": "mrkdwn", "text": f"*Actor:*\n{_describe_actor(detail.get('userIdentity') or {})}"},
        },
    ]

    if error_code:
        error_message = detail.get("errorMessage") or ""
        blocks.append(
            {
                "type": "section",
                "text": {
                    "type": "mrkdwn",
                    "text": f"*Error:*\n`{_escape(error_code)}` {_escape(error_message)[:1000]}",
                },
            }
        )

    context_parts = []
    if detail.get("sourceIPAddress"):
        context_parts.append(f"Source: {_escape(detail['sourceIPAddress'])}")
    cloudtrail_url = _cloudtrail_url(region, detail.get("eventID"))
    if cloudtrail_url:
        context_parts.append(f":mag: <{cloudtrail_url}|View in CloudTrail>")
    context_parts.append("If this change was not expected, the application may fail to connect to the database")
    blocks.extend(
        [
            {"type": "divider"},
            {"type": "context", "elements": [{"type": "mrkdwn", "text": "  ·  ".join(context_parts)}]},
        ]
    )

    summary = f"{title}: {event_name} in {environment} ({account})"
    return _build_message(_colour_for(detail), summary, blocks)


def _build_alarm_message(alarm: dict, environment: str) -> dict:
    alarm_name = alarm.get("AlarmName") or "unknown"
    state = alarm.get("NewStateValue") or "unknown"
    account = alarm.get("AWSAccountId") or "unknown"
    region = alarm.get("Region") or "unknown"

    if state == "ALARM":
        emoji, colour = ":rotating_light:", COLOUR_ALERT
    elif state == "OK":
        emoji, colour = ":white_check_mark:", COLOUR_OK
    else:
        emoji, colour = ":grey_question:", COLOUR_FAILED

    title = f"{emoji} EDW Security Alarm: {state}"
    aws_region = os.environ.get("AWS_REGION", "eu-west-2")
    alarm_url = (
        f"https://{aws_region}.console.aws.amazon.com/cloudwatch/home"
        f"?region={aws_region}#alarmsV2:alarm/{alarm_name}"
    )

    blocks = [
        {
            "type": "header",
            "text": {"type": "plain_text", "text": title, "emoji": True},
        },
        {"type": "divider"},
        {
            "type": "section",
            "fields": [
                {"type": "mrkdwn", "text": f"*Alarm:*\n`{_escape(alarm_name)}`"},
                {"type": "mrkdwn", "text": f"*State:*\n{_escape(alarm.get('OldStateValue', 'unknown'))} → {_escape(state)}"},
                {"type": "mrkdwn", "text": f"*Environment:*\n{_escape(environment)}"},
                {"type": "mrkdwn", "text": f"*Account:*\n{_escape(account)}"},
                {"type": "mrkdwn", "text": f"*Region:*\n{_escape(region)}"},
                {"type": "mrkdwn", "text": f"*Time:*\n{_format_time(alarm.get('StateChangeTime'))}"},
            ],
        },
        {
            "type": "section",
            "text": {"type": "mrkdwn", "text": f"*Description:*\n{_escape(alarm.get('AlarmDescription') or 'none')[:1500]}"},
        },
        {
            "type": "section",
            "text": {"type": "mrkdwn", "text": f"*Reason:*\n{_escape(alarm.get('NewStateReason') or 'unknown')[:1500]}"},
        },
        {"type": "divider"},
        {
            "type": "context",
            "elements": [{"type": "mrkdwn", "text": f":mag: <{alarm_url}|View alarm in CloudWatch>"}],
        },
    ]
    return _build_message(colour, f"EDW security alarm {alarm_name} is {state} in {environment}", blocks)


def _build_raw_message(log_message: str, log_group: str) -> dict:
    blocks = [
        {
            "type": "header",
            "text": {"type": "plain_text", "text": ":bell: CloudWatch Log Event", "emoji": True},
        },
        {"type": "divider"},
        {
            "type": "section",
            "text": {"type": "mrkdwn", "text": f"*Log group:*\n`{_escape(log_group)}`"},
        },
        {
            "type": "section",
            "text": {"type": "mrkdwn", "text": f"*Details:*\n```{_escape(log_message[:2800])}```"},
        },
    ]
    return _build_message(COLOUR_CHANGE, f"CloudWatch log event from {log_group}", blocks)


def _decode_cloudwatch_logs(event):
    payload = event["awslogs"]["data"]
    payload_bytes = base64.b64decode(payload)
    log_data = gzip.decompress(payload_bytes).decode("utf-8")
    return json.loads(log_data)


def _messages_from_logs(event, environment: str) -> list[dict]:
    log_data = _decode_cloudwatch_logs(event)
    log_group = log_data.get("logGroup", "")
    account = log_data.get("owner") or "unknown"
    messages = []

    for log_event in log_data.get("logEvents", []):
        log_message = log_event.get("message", "")
        try:
            payload = json.loads(log_message)
        except json.JSONDecodeError:
            messages.append(_build_raw_message(log_message, log_group))
            continue
        messages.append(_build_cloudtrail_message(payload, account, environment))

    return messages


def _messages_from_sns(event, environment: str) -> list[dict]:
    messages = []
    for record in event.get("Records", []):
        sns_message = (record.get("Sns") or {}).get("Message", "")
        try:
            alarm = json.loads(sns_message)
        except json.JSONDecodeError:
            logger.warning("Ignoring non-JSON SNS message: %s", sns_message[:500])
            continue
        if isinstance(alarm, dict) and alarm.get("AlarmName"):
            messages.append(_build_alarm_message(alarm, environment))
    return messages


def _post_to_slack(webhook_url: str, message: dict) -> None:
    request = urllib.request.Request(
        webhook_url,
        data=json.dumps(message).encode("utf-8"),
        headers={"Content-Type": "application/json"},
        method="POST",
    )
    with urllib.request.urlopen(request, timeout=10) as response:
        response.read()


def lambda_handler(event, context):
    webhook_url = get_webhook_url()
    environment = os.environ.get("ENVIRONMENT", "unknown")

    # CloudWatch Logs subscriptions deliver CloudTrail events; SNS delivers alarm state changes.
    if "awslogs" in event:
        messages = _messages_from_logs(event, environment)
    else:
        messages = _messages_from_sns(event, environment)

    if not messages:
        return {"statusCode": 200, "body": "No tracked EDW events found"}

    for message in messages:
        try:
            _post_to_slack(webhook_url, message)
        except Exception:
            logger.exception("Failed to post message to Slack: %s", message.get("text"))
            raise

    return {"statusCode": 200, "body": "Slack notifications sent"}
