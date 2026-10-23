import base64
import gzip
import json
import logging
import os
import xml.etree.ElementTree as ET
import urllib.request
from datetime import datetime

import boto3

logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Caches the Slack webhook URL for reuse within a Lambda container.
SLACK_WEBHOOK_URL_CACHE = None

# Sidebar colours used to signal the kind of change at a glance.
COLOUR_ADD = "#2EB67D"
COLOUR_CHANGE = "#FFA500"
COLOUR_REMOVE = "#E01E5A"
COLOUR_FAILED = "#808080"

# Header title and emoji for each CloudTrail event source.
EVENT_SOURCE_STYLES = {
    "workspaces.amazonaws.com": (":computer:", "WorkSpaces Change"),
    "ec2.amazonaws.com": (":shield:", "Security Group Change"),
    "iam.amazonaws.com": (":key:", "IAM Policy Change"),
}

REMOVE_PREFIXES = ("Delete", "Terminate", "Revoke", "Detach")
ADD_PREFIXES = ("Create", "Authorize", "Attach", "Put")


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
        parsed = datetime.fromisoformat(timestamp.replace("Z", "+00:00"))
        return parsed.strftime("%d %b %Y %H:%M:%S UTC")
    except ValueError:
        return timestamp


def _colour_for(event_name: str, failed: bool) -> str:
    if failed:
        return COLOUR_FAILED
    if event_name.startswith(REMOVE_PREFIXES):
        return COLOUR_REMOVE
    if event_name.startswith(ADD_PREFIXES):
        return COLOUR_ADD
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


def _describe_ip_permissions(params: dict) -> list[str]:
    """Summarises security-group rules as 'tcp 443 from 10.0.0.0/8' lines."""
    lines = []
    items = (params.get("ipPermissions") or {}).get("items") or []
    for item in items:
        protocol = item.get("ipProtocol", "any")
        from_port, to_port = item.get("fromPort"), item.get("toPort")
        if protocol == "-1":
            protocol, ports = "all", "traffic"
        elif from_port is None:
            ports = "all ports"
        elif from_port == to_port:
            ports = str(from_port)
        else:
            ports = f"{from_port}-{to_port}"

        sources = [r.get("cidrIp") for r in (item.get("ipRanges") or {}).get("items", [])]
        sources += [r.get("cidrIpv6") for r in (item.get("ipv6Ranges") or {}).get("items", [])]
        sources += [g.get("groupId") for g in (item.get("groups") or {}).get("items", [])]
        sources += [p.get("prefixListId") for p in (item.get("prefixListIds") or {}).get("items", [])]
        sources = [s for s in sources if s] or ["unspecified"]

        lines.append(f"{protocol} {ports} ↔ {', '.join(sources)}")
    return lines


def _describe_resources(detail: dict) -> list[str]:
    """Builds 'Label: value' lines for the resources touched by the API call."""
    params = detail.get("requestParameters") or {}
    response = detail.get("responseElements") or {}
    lines = []

    # WorkSpaces
    for ws in params.get("workspaces") or []:
        lines.append(
            f"*User:* {_escape(ws.get('userName', 'unknown'))} "
            f"(directory `{_escape(ws.get('directoryId', 'unknown'))}`)"
        )
    for request in (response.get("pendingRequests") or []):
        if request.get("workspaceId"):
            lines.append(f"*WorkSpace:* `{_escape(request['workspaceId'])}`")
    for request in params.get("terminateWorkspaceRequests") or []:
        lines.append(f"*WorkSpace:* `{_escape(request.get('workspaceId', 'unknown'))}`")
    workspace_ids = params.get("WorkSpaceIds") or params.get("workspaceIds")
    if isinstance(workspace_ids, list):
        lines.extend(f"*WorkSpace:* `{_escape(ws_id)}`" for ws_id in workspace_ids)

    # Security groups
    group_id = params.get("groupId") or response.get("groupId")
    if group_id:
        lines.append(f"*Security group:* `{_escape(group_id)}`")
    if params.get("groupName") and detail.get("eventSource") == "ec2.amazonaws.com":
        lines.append(f"*Group name:* {_escape(params['groupName'])}")
    rules = _describe_ip_permissions(params)
    if rules:
        lines.append("*Rules:*\n" + "\n".join(f"• `{_escape(rule)}`" for rule in rules))

    # IAM
    for key, label in (
        ("policyArn", "Policy"),
        ("policyName", "Policy name"),
        ("roleName", "Role"),
        ("userName", "User"),
        ("groupName", "Group"),
        ("versionId", "Version"),
    ):
        if key == "groupName" and detail.get("eventSource") != "iam.amazonaws.com":
            continue
        if params.get(key):
            lines.append(f"*{label}:* `{_escape(params[key])}`")

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


def _build_lockout_message(log_message: str, account: str, environment: str) -> dict | None:
    try:
        event = ET.fromstring(log_message)
    except ET.ParseError:
        return None

    event_id = next(
        (node.text for node in event.iter() if node.tag.endswith("EventID")),
        None,
    )
    if event_id != "4740":
        return None

    event_data = {
        node.get("Name"): node.text
        for node in event.iter()
        if node.tag.endswith("Data") and node.get("Name")
    }
    time_created = next(
        (node.get("SystemTime") for node in event.iter() if node.tag.endswith("TimeCreated")),
        None,
    )
    domain_controller = next(
        (node.text for node in event.iter() if node.tag.endswith("Computer")),
        None,
    )
    username = event_data.get("TargetUserName") or "unknown user"
    # For event 4740, TargetDomainName holds the machine the bad attempts came from.
    caller = event_data.get("TargetDomainName") or "unknown"

    blocks = [
        {
            "type": "header",
            "text": {"type": "plain_text", "text": ":lock: WorkSpaces Account Locked", "emoji": True},
        },
        {"type": "divider"},
        {
            "type": "section",
            "fields": [
                {"type": "mrkdwn", "text": f"*User:*\n{_escape(username)}"},
                {"type": "mrkdwn", "text": f"*Locked out from:*\n{_escape(caller)}"},
                {"type": "mrkdwn", "text": f"*Environment:*\n{_escape(environment)}"},
                {"type": "mrkdwn", "text": f"*Account:*\n{_escape(account)}"},
                {"type": "mrkdwn", "text": f"*Domain controller:*\n{_escape(domain_controller or 'unknown')}"},
                {"type": "mrkdwn", "text": f"*Time:*\n{_format_time(time_created)}"},
            ],
        },
        {"type": "divider"},
        {
            "type": "context",
            "elements": [
                {"type": "mrkdwn", "text": "Windows Security event 4740 · unlock the account in AD if the lockout is expected"}
            ],
        },
    ]
    return _build_message(COLOUR_REMOVE, f"WorkSpaces account locked: {username}", blocks)


def _build_cloudtrail_message(payload: dict, account: str, environment: str) -> dict:
    detail = payload.get("detail", {})
    event_name = detail.get("eventName") or "unknown"
    event_source = detail.get("eventSource") or "unknown"
    region = detail.get("awsRegion") or payload.get("region") or os.environ.get("AWS_REGION", "")
    account = payload.get("account") or account
    error_code = detail.get("errorCode")

    emoji, title = EVENT_SOURCE_STYLES.get(event_source, (":bell:", "AWS Change"))
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
    if context_parts:
        blocks.extend(
            [
                {"type": "divider"},
                {"type": "context", "elements": [{"type": "mrkdwn", "text": "  ·  ".join(context_parts)}]},
            ]
        )

    summary = f"{title}: {event_name} in {environment} ({account})"
    return _build_message(_colour_for(event_name, bool(error_code)), summary, blocks)


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


def _extract_workspace_message(
    log_message: str, log_group: str = "", account: str = "unknown", environment: str = "unknown"
) -> dict | None:
    if "/aws/directoryservice/" in log_group:
        return _build_lockout_message(log_message, account, environment)

    try:
        payload = json.loads(log_message)
    except json.JSONDecodeError:
        return _build_raw_message(log_message, log_group)

    return _build_cloudtrail_message(payload, account, environment)


def _decode_cloudwatch_logs(event):
    payload = event["awslogs"]["data"]
    payload_bytes = base64.b64decode(payload)
    log_data = gzip.decompress(payload_bytes).decode("utf-8")
    return json.loads(log_data)


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

    log_data = _decode_cloudwatch_logs(event)
    log_group = log_data.get("logGroup", "")
    account = log_data.get("owner") or "unknown"
    messages = []

    for log_event in log_data.get("logEvents", []):
        message = _extract_workspace_message(
            log_event.get("message", ""), log_group, account, environment
        )
        if message:
            messages.append(message)

    if not messages:
        return {"statusCode": 200, "body": "No tracked AWS events found"}

    for message in messages:
        try:
            _post_to_slack(webhook_url, message)
        except Exception:
            logger.exception("Failed to post message to Slack: %s", message.get("text"))
            raise

    return {"statusCode": 200, "body": "Slack notifications sent"}
