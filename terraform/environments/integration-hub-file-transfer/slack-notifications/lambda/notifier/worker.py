"""Send an SSO portal link. Never sign, fetch or proxy an S3 object."""
import hashlib
import json
import re
import time
import urllib.request
from datetime import datetime, timezone
from uuid import UUID

SOURCE = "uk.gov.justice.service.managed-file-transfer"
MAX_EVENT_AGE = 12 * 60 * 60


class InvalidNotification(ValueError):
    pass


def validate(record, config, now):
    if record.get("eventSource") != "aws:sqs" or record.get("eventSourceARN") != config["queue_arn"]:
        raise InvalidNotification("Unexpected queue")
    envelope = json.loads(record["body"])
    if envelope.get("Type") != "Notification" or envelope.get("TopicArn") != config["topic_arn"]:
        raise InvalidNotification("Unexpected topic")
    event = json.loads(envelope["Message"])
    if (event.get("source") != SOURCE or event.get("account") != config["account"]
            or event.get("region") != "eu-west-2"
            or event.get("detail-type") != "FileActionExecutionRequested.v1"):
        raise InvalidNotification("Unexpected event")
    data = event["detail"]["data"]
    UUID(data["actionExecutionId"])
    UUID(data["fileId"])
    if "slack" not in data["notifications"]:
        raise InvalidNotification("Slack not requested")
    ref = data["configurationReference"]
    route = config["routes"].get(ref["secretArn"])
    if not route or not ref.get("secretVersionId"):
        raise InvalidNotification("Unknown configuration")
    obj = data["object"]
    if (obj.get("bucket") != config["clean_bucket"] or not obj.get("versionId")
            or not isinstance(obj.get("key"), str) or not obj["key"].startswith(route["prefix"])):
        raise InvalidNotification("Object outside authorised clean prefix")
    requested = datetime.fromisoformat(data["requestedAt"].replace("Z", "+00:00"))
    if requested.tzinfo is None:
        raise InvalidNotification("Timestamp needs timezone")
    age = now - requested.timestamp()
    if age < -300:
        raise InvalidNotification("Future event")
    # Do not notify from old DLQs once the one-day clean retention is likely exhausted.
    if age > MAX_EVENT_AGE:
        return None
    portal = config["portal_url"]
    if not re.fullmatch(r"https://web(?:\.(?:development|test|preproduction))?\.file-transfer\.service\.justice\.gov\.uk", portal):
        raise InvalidNotification("Unexpected portal")
    key = hashlib.sha256(json.dumps([data["actionExecutionId"], ref["secretArn"],
                                    ref["secretVersionId"], route["recipient_id"]]).encode()).hexdigest()
    return data, route, key


def message(data, portal):
    # User-controlled names belong in plain_text, not Slack markdown or link labels.
    location = data["object"]["key"]
    return {
        "text": "MFT: a clean file is available. Sign in to the MFT web app to download it.",
        "unfurl_links": False,
        "unfurl_media": False,
        "blocks": [
            {"type": "section", "text": {"type": "plain_text", "text": "A clean file is available in MFT."}},
            {"type": "section", "text": {"type": "plain_text", "text": f"Location: {location}"[:2900]}},
            {"type": "actions", "elements": [{"type": "button", "action_id": "open_mft_pickup",
                "text": {"type": "plain_text", "text": "Open MFT to download"}, "url": portal}]},
            {"type": "context", "elements": [{"type": "plain_text", "text":
                "Sign in with your organisation account. Access is limited to authorised recipients. "
                "Files follow MFT retention; this link does not extend availability."}]},
        ],
    }


class NoRedirect(urllib.request.HTTPRedirectHandler):
    def redirect_request(self, req, fp, code, msg, headers, newurl):
        return None


def post_slack(url, payload):
    if not isinstance(url, str) or not re.fullmatch(r"https://hooks\.slack\.com/services/[A-Za-z0-9_-]+/[A-Za-z0-9_-]+/[A-Za-z0-9_-]+", url):
        raise InvalidNotification("Invalid Slack webhook")
    request = urllib.request.Request(url, data=json.dumps(payload).encode(),
                                     headers={"Content-Type": "application/json"}, method="POST")
    # Redirects cannot leak the webhook request to another destination.
    with urllib.request.build_opener(NoRedirect()).open(request, timeout=10) as response:
        if response.status != 200 or response.read(64).strip() != b"ok":
            raise RuntimeError("Slack rejected notification")


def process(record, config, store, secrets, send=post_slack, clock=time.time):
    now = int(clock())
    validated = validate(record, config, now)
    if validated is None:
        return "expired"
    data, route, key = validated
    ref = data["configurationReference"]
    dispatch = json.loads(secrets.get_secret_value(SecretId=ref["secretArn"],
                          VersionId=ref["secretVersionId"])["SecretString"])
    if dispatch.get("notifications", {}).get("slack") != {
            "type": "authenticated-pickup", "recipient": route["recipient_id"]}:
        raise InvalidNotification("Dispatch recipient mismatch")
    if not store.claim(key, now):
        return "duplicate"
    # Leave the lease on failure, including ambiguous Slack outcomes. A later retry
    # can send again after expiry; exactly-once delivery to Slack is not guaranteed.
    webhook = json.loads(secrets.get_secret_value(SecretId=route["webhook_secret_arn"])["SecretString"])
    send(webhook["url"], message(data, config["portal_url"]))
    store.complete(key)
    return "sent"


class Store:
    def __init__(self, table):
        self.table = table

    def claim(self, key, now):
        try:
            self.table.put_item(Item={"id": key, "status": "IN_PROGRESS", "leaseUntil": now + 120,
                                      "expiresAt": now + 14 * 86400},
                ConditionExpression="attribute_not_exists(id) OR (#s = :working AND leaseUntil < :now)",
                ExpressionAttributeNames={"#s": "status"},
                ExpressionAttributeValues={":working": "IN_PROGRESS", ":now": now})
            return True
        except Exception as error:
            if getattr(error, "response", {}).get("Error", {}).get("Code") != "ConditionalCheckFailedException":
                raise
            item = self.table.get_item(Key={"id": key}, ConsistentRead=True).get("Item", {})
            if item.get("status") == "SENT":
                return False
            raise RuntimeError("Notification already in progress") from None

    def complete(self, key):
        self.table.update_item(Key={"id": key}, UpdateExpression="SET #s = :sent",
                               ExpressionAttributeNames={"#s": "status"},
                               ExpressionAttributeValues={":sent": "SENT"})
