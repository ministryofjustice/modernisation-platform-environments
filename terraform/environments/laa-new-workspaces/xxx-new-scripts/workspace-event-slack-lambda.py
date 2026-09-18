import base64
import gzip
import json
import os
import urllib.request

import boto3


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


def _extract_workspace_message(log_message: str) -> dict:
    try:
        payload = json.loads(log_message)
    except json.JSONDecodeError:
        return {"text": log_message}

    detail = payload.get("detail", {})
    event_name = detail.get("eventName")
    user_identity = detail.get("userIdentity", {})
    username = user_identity.get("arn") or user_identity.get("userName") or "unknown"
    request_params = detail.get("requestParameters") or {}
    workspace_id = request_params.get("WorkSpaceIds") or request_params.get("workspaceIds") or "unknown"

    if isinstance(workspace_id, list):
        workspace_id = ", ".join(workspace_id)

    if event_name == "CreateWorkspaces":
        action = "created"
    elif event_name == "TerminateWorkspaces":
        action = "terminated"
    else:
        action = "updated"

    return {
        "text": (
            f"WorkSpaces event: {event_name or 'unknown'}\n"
            f"Action: {action}\n"
            f"User: {username}\n"
            f"WorkSpace: {workspace_id}\n"
            f"Account: {payload.get('account', 'unknown')}"
        )
    }


def _decode_cloudwatch_logs(event):
    payload = event["awslogs"]["data"]
    payload_bytes = base64.b64decode(payload)
    log_data = gzip.decompress(payload_bytes).decode("utf-8")
    return json.loads(log_data)


def lambda_handler(event, context):
    secret_name = os.environ["SLACK_WEBHOOK_SECRET"]
    webhook_url = get_secret(secret_name)

    if not webhook_url:
        raise ValueError("Slack webhook URL not configured")

    log_data = _decode_cloudwatch_logs(event)
    messages = []

    for log_event in log_data.get("logEvents", []):
        message = _extract_workspace_message(log_event.get("message", ""))
        messages.append(message)

    if not messages:
        return {"statusCode": 200, "body": "No WorkSpaces events found"}

    for message in messages:
        post_body = json.dumps(message).encode("utf-8")
        request = urllib.request.Request(
            webhook_url,
            data=post_body,
            headers={"Content-Type": "application/json"},
            method="POST",
        )
        with urllib.request.urlopen(request, timeout=10) as response:
            response.read()

    return {"statusCode": 200, "body": "Slack notifications sent"}
