import json
import os
import urllib.request
import urllib.error
import boto3
from typing import Any, Dict, Optional, List
import logging

logger = logging.getLogger()
logger.setLevel(logging.INFO)

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


def _pick_webhooks(secret_json: Dict[str, Any]) -> List[str]:
    """
    Return ALL webhook URLs found in the secret.
    - If SLACK_WEBHOOK_KEY is set, only that key is used.
    - Otherwise, use known keys (maatdb_dbas/crimeapps/fallback) AND any other non-empty string values in the secret.
    """
    preferred_key = os.environ.get("SLACK_WEBHOOK_KEY", "").strip()

    if preferred_key:
        v = (secret_json.get(preferred_key) or "").strip()
        if not v:
            raise ValueError(
                f"SLACK_WEBHOOK_KEY is set to '{preferred_key}' but the value is empty/missing in the secret."
            )
        return [v]

    # First, grab known keys in stable order (so logs are predictable)
    keys_in_order = [
        "slack_channel_webhook_maatdb_dbas",
        "slack_channel_webhook_crimeapps",
        "slack_webhook",
    ]

    urls: List[str] = []
    seen = set()

    for k in keys_in_order:
        v = (secret_json.get(k) or "").strip()
        if v and v not in seen:
            urls.append(v)
            seen.add(v)

    # Then add any other non-empty string values from the secret (optional, future-proof)
    for v in secret_json.values():
        if isinstance(v, str):
            vv = v.strip()
            if vv and vv not in seen:
                urls.append(vv)
                seen.add(vv)

    if not urls:
        raise ValueError(
            "No Slack webhook URLs found in secret. "
            "Expected keys like slack_channel_webhook_maatdb_dbas / slack_channel_webhook_crimeapps."
        )

    return urls


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
    webhook_urls = _pick_webhooks(secret_json)

    results = []
    for url in webhook_urls:
        results.append(_post_to_slack(url, slack_text))

    logger.info(
        "Slack notification results",
        extra={
            "slack_post_results": results,
            "message_id": info.get("message_id"),
            "timestamp": info.get("timestamp"),
            "parsed": info.get("parsed"),
        },
    )

    # Fail only if ALL posts failed
    if not any(r.get("ok") for r in results):
        raise RuntimeError(f"Slack post failed for all webhooks: {results}")

    return {"statusCode": 200, "body": "Notification sent to Slack (all configured webhooks)"}