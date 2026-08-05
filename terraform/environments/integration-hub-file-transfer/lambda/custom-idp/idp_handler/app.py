import hmac
import json
import logging
import os

import boto3

from custom_idp_common import (
    ip_in_cidr_list,
    normalise_home_directory_details,
    replace_response_variables,
    server_id_in_allow_list,
)


LOG_LEVEL = os.environ.get("LOGLEVEL", "INFO")
SECRET_PREFIX = os.environ["SECRET_PREFIX"]
AWS_ACCOUNT_ID = os.environ["AWS_ACCOUNT_ID"]
TRANSFER_ROLE_ARN = os.environ["TRANSFER_ROLE_ARN"]
TRANSFER_SESSION_POLICY = os.environ["TRANSFER_SESSION_POLICY"]
TRANSFER_HOME_DIRECTORY_DETAILS = os.environ["TRANSFER_HOME_DIRECTORY_DETAILS"]

logger = logging.getLogger()
logger.setLevel(LOG_LEVEL)

secretsmanager_client = boto3.client("secretsmanager")


class AuthenticationError(Exception):
    pass


def lambda_handler(event, context):
    try:
        username = parse_username(event)
        logger.info(
            "Processing authentication request for user %s on server %s using protocol %s",
            username,
            event.get("serverId"),
            event.get("protocol"),
        )

        user_record = get_user_record(username)
        validate_user_record(username, user_record)
        validate_request_context(event, username, user_record)
        response_data = build_transfer_response()

        password = event.get("password")
        if isinstance(password, str) and password.strip():
            authenticate_password(password, user_record)
        else:
            public_keys = user_record["publicKeys"]
            if not public_keys:
                raise AuthenticationError("No public keys configured for user")
            response_data["PublicKeys"] = public_keys

        response_data = normalise_home_directory_details(response_data)
        response_data = replace_response_variables(response_data, username, AWS_ACCOUNT_ID, event["serverId"])
        logger.info("Authentication succeeded for user %s", username)
        return response_data
    except AuthenticationError as error:
        logger.warning("Authentication failed: %s", error)
        return {}
    except Exception:
        logger.exception("Unexpected custom IdP error")
        return {}


def parse_username(event):
    if "username" not in event or "serverId" not in event:
        raise AuthenticationError("Incoming username or serverId is missing")

    input_username = event["username"]
    if not isinstance(input_username, str) or not input_username:
        raise AuthenticationError("Incoming username is invalid")

    username = input_username.lower()
    if username in {"$", "$default$"}:
        raise AuthenticationError("Reserved username cannot authenticate")

    return username


def get_user_record(username):
    try:
        secret = secretsmanager_client.get_secret_value(SecretId=f"{SECRET_PREFIX}{username}")
    except secretsmanager_client.exceptions.ResourceNotFoundException as error:
        raise AuthenticationError("User secret does not exist") from error

    secret_string = secret.get("SecretString")
    if not isinstance(secret_string, str) or not secret_string:
        raise AuthenticationError("User secret is empty")

    try:
        user_record = json.loads(secret_string)
    except json.JSONDecodeError as error:
        raise AuthenticationError("User secret is not valid JSON") from error

    if not isinstance(user_record, dict):
        raise AuthenticationError("User secret must contain a JSON object")

    return user_record


def validate_user_record(username, user_record):
    if user_record.get("username") != username:
        raise AuthenticationError("User secret username does not match request")

    password = user_record.get("password")
    if password is not None and not isinstance(password, str):
        raise AuthenticationError("User password is invalid")

    for field_name in ["publicKeys", "ipv4_allow_list", "server_id_allow_list"]:
        field_value = user_record.get(field_name)
        if not isinstance(field_value, list) or not all(isinstance(value, str) for value in field_value):
            raise AuthenticationError(f"User {field_name} is invalid")

def validate_request_context(event, username, user_record):
    server_id = event["serverId"]
    source_ip = event.get("sourceIp")

    if not source_ip:
        raise AuthenticationError("Source IP is missing")

    if not server_id_in_allow_list(server_id, user_record["server_id_allow_list"]):
        raise AuthenticationError(f"User {username} is not allowed on this server")

    if not ip_in_cidr_list(source_ip, user_record["ipv4_allow_list"]):
        raise AuthenticationError("Source IP is not allowed for this user")


def build_transfer_response():
    try:
        home_directory_details = json.loads(TRANSFER_HOME_DIRECTORY_DETAILS)
    except json.JSONDecodeError as error:
        raise AuthenticationError("Transfer home directory configuration is invalid") from error

    if not isinstance(home_directory_details, list) or not home_directory_details:
        raise AuthenticationError("Transfer home directory configuration is invalid")

    return {
        "Role": TRANSFER_ROLE_ARN,
        "Policy": TRANSFER_SESSION_POLICY,
        "HomeDirectoryType": "LOGICAL",
        "HomeDirectoryDetails": home_directory_details,
    }


def authenticate_password(input_password, user_record):
    expected_password = user_record.get("password")
    if not expected_password:
        raise AuthenticationError("Password is not configured for user")

    if not hmac.compare_digest(expected_password, input_password):
        raise AuthenticationError("Password does not match")