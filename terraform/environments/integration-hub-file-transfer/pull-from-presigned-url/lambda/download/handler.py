import base64
import json
import os
import secrets
from pathlib import Path
from urllib.parse import urlsplit

import boto3
from botocore.config import Config
from broker import AccessDenied, issue

CONFIG = json.loads(os.environ["CONFIG"])
AWS_CONFIG = Config(signature_version="s3v4", connect_timeout=3, read_timeout=5, retries={"max_attempts": 2})
TABLE = boto3.resource("dynamodb", config=AWS_CONFIG).Table(os.environ["PICKUP_TABLE"])
S3 = boto3.client("s3", config=AWS_CONFIG)
PAGE = Path(__file__).with_name("index.html").read_text()
HEADERS = {"Cache-Control": "no-store", "Pragma": "no-cache", "Referrer-Policy": "no-referrer",
           "X-Content-Type-Options": "nosniff", "X-Frame-Options": "DENY",
           "Strict-Transport-Security": "max-age=31536000; includeSubDomains"}


def lambda_handler(event, context):
    route = event.get("routeKey")
    if route in ("GET /pickups/{id}", "GET /callback"):
        if not CONFIG.get("sso"):
            return {"statusCode": 503, "headers": HEADERS, "body": "Pickup is not configured yet."}
        # Only public OIDC application settings are sent to the browser.
        public = {k: CONFIG["sso"][k] for k in ("client_id", "authorization_endpoint", "token_endpoint", "download_scope")}
        public["redirect_uri"] = CONFIG["portal_url"] + "/callback"
        nonce = secrets.token_urlsafe(24)
        settings = base64.b64encode(json.dumps(public).encode()).decode()
        token = urlsplit(public["token_endpoint"])
        token_origin = f"{token.scheme}://{token.netloc}"
        csp = f"default-src 'none'; script-src 'nonce-{nonce}'; connect-src 'self' {token_origin}; base-uri 'none'; frame-ancestors 'none'; form-action 'none'"
        return {"statusCode": 200, "headers": {**HEADERS, "Content-Type": "text/html; charset=utf-8", "Content-Security-Policy": csp},
                "body": PAGE.replace("__NONCE__", nonce).replace("__SETTINGS__", settings)}
    try:
        result = issue(event, CONFIG, TABLE, S3)
        # Audit the successful issuance, never the bearer token or generated URL.
        print(json.dumps({"outcome": "download_url_issued", "requestId": event.get("requestContext", {}).get("requestId")}))
        return {"statusCode": 200, "headers": {**HEADERS, "Content-Type": "application/json"}, "body": json.dumps(result)}
    except AccessDenied:
        print(json.dumps({"outcome": "download_denied"}))
        return {"statusCode": 403, "headers": HEADERS, "body": "File unavailable or access denied."}
    # Unexpected SDK failures propagate for Lambda error alarms. No request/body logging.
