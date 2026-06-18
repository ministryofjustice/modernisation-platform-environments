import base64
import binascii
import hmac
import json
import os

import boto3


DYNAMODB = boto3.resource("dynamodb")
SECRETS_MANAGER = boto3.client("secretsmanager")

AUTH_PRINCIPALS_TABLE = os.environ["AUTH_PRINCIPALS_TABLE"]
AUTH_ROLES_TABLE = os.environ["AUTH_ROLES_TABLE"]


def _deny():
    return {"isAuthorized": False, "context": {}}


def _get_header(event, header_name):
    headers = event.get("headers") or {}
    for key, value in headers.items():
        if key.lower() == header_name.lower():
            return value
    return None


def _get_principal(lookup_key):
    table = DYNAMODB.Table(AUTH_PRINCIPALS_TABLE)
    return table.get_item(Key={"auth_lookup_key": lookup_key}).get("Item")


def _get_role(role_name):
    table = DYNAMODB.Table(AUTH_ROLES_TABLE)
    return table.get_item(Key={"role_name": role_name}).get("Item")


def _load_secret_json(secret_id):
    try:
        response = SECRETS_MANAGER.get_secret_value(SecretId=secret_id)
        secret_string = response.get("SecretString") or ""
        return json.loads(secret_string) if secret_string else {}
    except Exception:
        return {}

def _authenticate_basic(token):
    try:
        username, password = base64.b64decode(token).decode("utf-8").split(":", 1)
    except (ValueError, UnicodeDecodeError, binascii.Error):
        return None

    principal = _get_principal(f"basic#{username}")
    if principal is None or not principal.get("enabled", True):
        return None

    secret = _load_secret_json(principal.get("secret_name", ""))
    expected_password = secret.get("password")
    if not expected_password or expected_password == "replace-me" or not hmac.compare_digest(password, str(expected_password)):
        return None

    return principal


def _authenticate_bearer(token):
    token_id, separator, token_secret = token.partition(".")
    if not separator or not token_id or not token_secret:
        return None

    principal = _get_principal(f"bearer#{token_id}")
    if principal is None or not principal.get("enabled", True):
        return None

    secret = _load_secret_json(principal.get("secret_name", ""))
    expected_token = secret.get("bearerToken")
    if not expected_token or expected_token == "replace-me" or not hmac.compare_digest(str(expected_token), token_secret):
        return None

    return principal


def _build_context(principal, role):
    allowed_client_ids = role.get("allowed_client_ids") or []
    allowed_client_ids_csv = ",".join(str(value) for value in allowed_client_ids if value is not None)
    return {
        "isAuthorized": True,
        "context": {
            "principalId": principal["principal_id"],
            "roleName": principal["role_name"],
            "authType": principal["auth_type"],
            "allowedClientIds": allowed_client_ids_csv,
        },
    }


def lambda_handler(event, _context):
    authorization = _get_header(event, "authorization")
    if not authorization:
        return _deny()

    try:
        scheme, token = authorization.split(" ", 1)
    except ValueError:
        return _deny()
    token = token.strip()

    if scheme.lower() == "basic":
        principal = _authenticate_basic(token)
    elif scheme.lower() == "bearer":
        principal = _authenticate_bearer(token)
    else:
        principal = None

    if principal is None:
        return _deny()

    role = _get_role(principal["role_name"])
    if role is None:
        return _deny()

    return _build_context(principal, role)
