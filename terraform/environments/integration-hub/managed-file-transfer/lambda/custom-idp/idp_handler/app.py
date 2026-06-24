import hmac
import json
import logging
import os

import boto3
from boto3.dynamodb.conditions import Key

from custom_idp_common import (
    ip_in_cidr_list,
    normalise_home_directory_details,
    replace_response_variables,
    server_id_in_allow_list,
)


LOG_LEVEL = os.environ.get("LOGLEVEL", "INFO")
USER_NAME_DELIMITER = os.environ.get("USER_NAME_DELIMITER", "@@")
USERS_TABLE_NAME = os.environ["USERS_TABLE"]
IDENTITY_PROVIDERS_TABLE_NAME = os.environ["IDENTITY_PROVIDERS_TABLE"]

logger = logging.getLogger()
logger.setLevel(LOG_LEVEL)

sts_client = boto3.client("sts")
secretsmanager_client = boto3.client("secretsmanager")
dynamodb_resource = boto3.resource("dynamodb")
users_table = dynamodb_resource.Table(USERS_TABLE_NAME)
identity_providers_table = dynamodb_resource.Table(IDENTITY_PROVIDERS_TABLE_NAME)
account_id = sts_client.get_caller_identity()["Account"]


class AuthenticationError(Exception):
    pass


def lambda_handler(event, context):
    try:
        username, identity_provider_name = parse_username(event)
        logger.info(
            "Processing authentication request for user %s on server %s using protocol %s",
            username,
            event.get("serverId"),
            event.get("protocol"),
        )

        user_record = get_user_record(username, identity_provider_name)
        identity_provider_record = get_identity_provider_record(user_record["identity_provider_key"])
        validate_request_context(event, username, user_record, identity_provider_record)

        idp_username = user_record.get("idp_username") or username
        response_data = build_transfer_response(user_record, identity_provider_record)

        if event.get("password", "").strip():
            authenticate_password(event["password"], idp_username, identity_provider_record)
        else:
            public_keys = get_public_keys(idp_username, user_record, identity_provider_record)
            if not public_keys:
                raise AuthenticationError("No public keys configured for user")
            response_data["PublicKeys"] = public_keys

        response_data = normalise_home_directory_details(response_data)
        response_data = replace_response_variables(response_data, username, account_id, event["serverId"])
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

    input_username = event["username"].lower()
    if input_username in {"$", "$default$"}:
        raise AuthenticationError("Reserved username cannot authenticate")

    parsed_username = input_username.split(USER_NAME_DELIMITER)
    if len(parsed_username) > 1:
        return USER_NAME_DELIMITER.join(parsed_username[:-1]), parsed_username[-1]

    return input_username, None


def get_user_record(username, identity_provider_name):
    if identity_provider_name:
        user_record = users_table.get_item(
            Key={"user": username, "identity_provider_key": identity_provider_name}
        ).get("Item")
    else:
        user_records = users_table.query(KeyConditionExpression=Key("user").eq(username)).get("Items", [])
        user_record = user_records[0] if user_records else None

    if not user_record:
        default_records = users_table.query(KeyConditionExpression=Key("user").eq("$default$")).get("Items", [])
        user_record = default_records[0] if default_records else None

    if not user_record:
        raise AuthenticationError("No matching user record found")

    return user_record


def get_identity_provider_record(identity_provider_name):
    identity_provider_record = identity_providers_table.get_item(
        Key={"provider": identity_provider_name}
    ).get("Item")

    if not identity_provider_record:
        raise AuthenticationError("Identity provider is not defined")

    if identity_provider_record.get("disabled", False):
        raise AuthenticationError("Identity provider is disabled")

    return identity_provider_record


def validate_request_context(event, username, user_record, identity_provider_record):
    server_id = event["serverId"]
    source_ip = event.get("sourceIp", "0.0.0.0")

    if not server_id_in_allow_list(server_id, user_record.get("server_id_allow_list")):
        raise AuthenticationError(f"User {username} is not allowed on this server")

    if not server_id_in_allow_list(server_id, identity_provider_record.get("server_id_allow_list")):
        raise AuthenticationError("Identity provider is not allowed on this server")

    if not ip_in_cidr_list(source_ip, user_record.get("ipv4_allow_list")):
        raise AuthenticationError("Source IP is not allowed for this user")

    if not ip_in_cidr_list(source_ip, identity_provider_record.get("ipv4_allow_list")):
        raise AuthenticationError("Source IP is not allowed for this identity provider")


def build_transfer_response(user_record, identity_provider_record):
    response_data = {}
    identity_provider_config = identity_provider_record.get("config", {})
    user_config = user_record.get("config", {})

    for field_name in ["Role", "Policy", "HomeDirectoryDetails", "HomeDirectory", "PosixProfile"]:
        if field_name in identity_provider_config:
            response_data[field_name] = identity_provider_config[field_name]
        if field_name in user_config:
            response_data[field_name] = user_config[field_name]

    if "HomeDirectoryDetails" in response_data:
        response_data["HomeDirectoryType"] = "LOGICAL"
    elif "HomeDirectory" in response_data:
        response_data["HomeDirectoryType"] = "PATH"

    if not response_data.get("Role"):
        raise AuthenticationError("Transfer role is not configured")

    return response_data


def authenticate_password(input_password, username, identity_provider_record):
    secret_value = get_user_secret(username, identity_provider_record)
    expected_password = secret_value.get("Password")

    if not expected_password:
        raise AuthenticationError("Password is not configured for user")

    if not hmac.compare_digest(str(expected_password), input_password):
        raise AuthenticationError("Password does not match")


def get_public_keys(username, user_record, identity_provider_record):
    if not identity_provider_record.get("public_key_support", False):
        return user_record.get("config", {}).get("PublicKeys", [])

    secret_value = get_user_secret(username, identity_provider_record)
    public_keys = secret_value.get("PublicKeys", [])
    if isinstance(public_keys, str):
        public_keys = json.loads(public_keys)

    if public_keys:
        return public_keys

    key_secret_name = f"{get_secret_prefix(identity_provider_record)}{username}/keys"
    try:
        key_secret = secretsmanager_client.get_secret_value(SecretId=key_secret_name)
        key_secret_value = json.loads(key_secret["SecretString"])
        return key_secret_value.get("PublicKeys", [])
    except secretsmanager_client.exceptions.ResourceNotFoundException:
        return []


def get_user_secret(username, identity_provider_record):
    secret_name = f"{get_secret_prefix(identity_provider_record)}{username}"
    try:
        secret = secretsmanager_client.get_secret_value(SecretId=secret_name)
    except secretsmanager_client.exceptions.ResourceNotFoundException as error:
        raise AuthenticationError("User secret does not exist") from error

    return json.loads(secret["SecretString"])


def get_secret_prefix(identity_provider_record):
    return identity_provider_record.get("config", {}).get("secret_prefix", "transfer/")
