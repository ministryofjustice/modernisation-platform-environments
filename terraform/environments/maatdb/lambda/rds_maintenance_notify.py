import json
import os
import urllib.request
import urllib.error
import boto3
from typing import Any, Dict, Optional


secrets_client = boto3.client("secretsmanager")


def _get_secret_json(secret_name: str) -> Dict[str, Any]:
    """
    Reads SECRET_NAME from Secrets Manager and parses SecretString as JSON.
    """
    resp = secrets_client.get_secret_value(SecretId=secret_name)
    secret_str = resp.get("SecretString")
    if not secret_str:
        raise ValueError("SecretString is empty or missing for the given secret.")
    try:
        return json.loads(secret_str)
    except json.JSONDecodeError as e:
        raise ValueError("SecretString is not valid JSON.") from e


def _pick_webhook(secret_json: Dict[str, Any]) -> str:
    """
    Choose which webhook to use. Preference order:
    1) SLACK_WEBHOOK_KEY env var (optional) -> e.g. 'slack_channel_webhook_appops'
    2) slack_channel_webhook_appops
    3) slack_channel_webhook_crimeapps
    4) slack_webhook (fallback common key)
    """
    preferred_key = os.environ.get("SLACK_WEBHOOK_KEY", "").strip()
    candidates = []
    if preferred_key:
        candidates.append(preferred_key)
    candidates += [
        "slack_channel_webhook_appops",
        "slack_channel_webhook_crimeapps",
        "slack_webhook",
    ]

    for k in candidates:
        v = (secret_json.get(k) or "").strip()
        if v:
            return v

    raise ValueError(
        "No Slack webhook URL found in secret. "
        "Set one of: SLACK_WEBHOOK_KEY target, slack_channel_webhook_appops, slack_channel_webhook_crimeapps, slack_webhook."
    )


def _extract_sns_message(event: Dict[str, Any]) -> Dict[str, Any]:
    """
    Extract a single SNS record and attempt to parse the Message as JSON.
    If Message isn't JSON, return it as raw text in a dict.
    SNS->Lambda event shape includes event['Records'][i]['Sns']['Message'].
    """
    records = event.get("Records") or []
    if not records:
        return {"raw_message": "No Records in event", "parsed": False}

    # SNS triggers typically send one record, but treat it as iterable
    record0 = records[0]
    sns = record0.get("Sns", {})
    message = sns.get("Message", "")
    subject = sns.get("Subject", "")
    topic_arn = sns.get("TopicArn", "")
    message_id = sns.get("MessageId", "")
    timestamp = sns.get("Timestamp", "")

    parsed_payload: Optional[Dict[str, Any]] = None
    parsed = False
    if isinstance(message, str):
        try:
            parsed_payload = json.loads(message)
            parsed = isinstance(parsed_payload, dict)
        except json.JSONDecodeError:
            parsed_payload = None

    return {
        "subject": subject,
        "topic_arn": topic_arn,
        "message_id": message_id,
        "timestamp": timestamp,
        "raw_message": message,
        "parsed": parsed,
        "payload": parsed_payload if parsed_payload else {},
    }


def _build_slack_text(info: Dict[str, Any]) -> str:
    """
    Build a readable Slack message.
    RDS event notifications published to SNS may be plain text; we handle both.
    """
    header = ":warning: *RDS Maintenance Notification*"
    meta_lines = []
    if info.get("message_id"):
        meta_lines.append(f"*MessageId:* `{info['message_id']}`")
    if info.get("timestamp"):
        meta_lines.append(f"*Timestamp:* `{info['timestamp']}`")
    if info.get("topic_arn"):
        meta_lines.append(f"*Topic:* `{info['topic_arn']}`")
    if info.get("subject"):
        meta_lines.append(f"*Subject:* {info['subject']}")

    if info.get("parsed"):
        # If the SNS message was JSON, show it compactly
        payload = info.get("payload", {})
        pretty = json.dumps(payload, indent=2, sort_keys=True)
        body = f"*Details (JSON):*\n```{pretty}```"
    else:
        raw = (info.get("raw_message") or "").strip()
        if not raw:
            raw = "No message body."
        body = f"*Details:*\n```{raw}```"

    meta = "\n".join(meta_lines)
    if meta:
        return f"{header}\n{meta}\n{body}"
    return f"{header}\n{body}"


def _post_to_slack(webhook_url: str, text: str) -> Dict[str, Any]:
    """
    Post message to Slack Incoming Webhook.
    Uses standard library urllib to avoid external dependencies.
    """
    payload = {"text": text}
    data = json.dumps(payload).encode("utf-8")

    req = urllib.request.Request(
        webhook_url,
        data=data,
        headers={"Content-Type": "application/json"},
        method="POST",
    )

    try:
        with urllib.request.urlopen(req, timeout=10) as resp:
            resp_body = resp.read().decode("utf-8", errors="replace")
            return {"ok": True, "status": resp.status, "response": resp_body}
    except urllib.error.HTTPError as e:
        err_body = e.read().decode("utf-8", errors="replace") if e.fp else str(e)
        return {"ok": False, "status": e.code, "error": err_body}
    except Exception as e:
        return {"ok": False, "status": None, "error": str(e)}


def lambda_handler(event, context):
    """
    Entry point configured in Terraform: handler = "rds_maintenance_notify.lambda_handler"
    """
    secret_name = os.environ.get("SECRET_NAME", "").strip()
    if not secret_name:
        raise ValueError("SECRET_NAME environment variable is not set.")

    info = _extract_sns_message(event)
    slack_text = _build_slack_text(info)

    secret_json = _get_secret_json(secret_name)
    webhook_url = _pick_webhook(secret_json)

    result = _post_to_slack(webhook_url, slack_text)

    # Always log outcome; Lambda basic logging is enabled by your IAM policy
    print(json.dumps(
        {
            "slack_post_result": result,
            "message_id": info.get("message_id"),
            "timestamp": info.get("timestamp"),
            "parsed": info.get("parsed"),
        },
        sort_keys=True
    ))

    # If Slack fails, raise to let SNS/Lambda retry (note duplicates possible)
    if not result.get("ok"):
        raise RuntimeError(f"Slack post failed: {result}")

    return {"statusCode": 200, "body": "Notification sent to Slack"}