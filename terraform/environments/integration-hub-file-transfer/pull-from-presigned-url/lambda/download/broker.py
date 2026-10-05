"""Issue a bounded S3 URL only from API Gateway's verified access-token claims."""
import json
import re
import time

URL_SECONDS = 300


class AccessDenied(Exception):
    pass


def allowed(claims, recipient, groups_claim):
    subject = claims.get("sub")
    if not isinstance(subject, str) or not subject:
        return False
    groups = claims.get(groups_claim, [])
    # HTTP API authorizer stringifies array claims. Require JSON; never substring-match.
    if isinstance(groups, str):
        try:
            groups = json.loads(groups)
        except (ValueError, TypeError):
            groups = []
    if not isinstance(groups, list) or not all(isinstance(group, str) for group in groups):
        groups = []
    return any((p["type"] == "USER" and p["id"] == subject) or
               (p["type"] == "GROUP" and p["id"] in groups)
               for p in recipient.get("principals", {}).values())


def issue(event, config, table, s3, clock=time.time):
    sso = config.get("sso")
    if not sso or event.get("routeKey") != "POST /pickups/{id}/download":
        raise AccessDenied()
    claims = event.get("requestContext", {}).get("authorizer", {}).get("jwt", {}).get("claims", {})
    # JWT signature, issuer, audience, expiry and required scope are checked at the gateway.
    # Never trust a token decoded from headers, body or query parameters here.
    if not claims.get("sub"):
        raise AccessDenied()
    pickup_id = event.get("pathParameters", {}).get("id", "")
    if not re.fullmatch("[a-f0-9]{64}", pickup_id):
        raise AccessDenied()
    item = table.get_item(Key={"id": "pickup:" + pickup_id}, ConsistentRead=True).get("Item", {})
    recipient = config["recipients"].get(item.get("recipientId"))
    if not recipient or not allowed(claims, recipient, sso["groups_claim"]):
        raise AccessDenied()
    # Current mappings govern old notifications too. Removing a recipient or changing
    # its prefix withdraws future URL issuance for existing receipts.
    if (item.get("bucket") != config["pickup_bucket"] or item.get("key") != pickup_id
            or not item.get("versionId") or item["versionId"] == "null"
            or not item.get("source", {}).get("key", "").startswith(recipient["prefix"])):
        raise AccessDenied()
    now = int(clock())
    expires_in = min(URL_SECONDS, int(item.get("collectUntil", 0)) - now)
    if expires_in <= 0:
        raise AccessDenied()
    url = s3.generate_presigned_url("get_object", Params={"Bucket": item["bucket"], "Key": item["key"],
        "VersionId": item["versionId"], "ResponseContentDisposition": "attachment",
        "ResponseContentType": "application/octet-stream"}, ExpiresIn=expires_in)
    return {"url": url, "expiresIn": expires_in}
