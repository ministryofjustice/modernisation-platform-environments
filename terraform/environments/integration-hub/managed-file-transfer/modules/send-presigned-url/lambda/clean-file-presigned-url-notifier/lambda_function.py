import hashlib
import json
import os
from datetime import UTC, datetime, timedelta
from urllib.parse import unquote_plus

import boto3
import requests
from botocore.config import Config
from aws_lambda_powertools import Logger
from aws_lambda_powertools.utilities.idempotency import (
    DynamoDBPersistenceLayer,
    IdempotencyConfig,
    idempotent_function,
)

AWS_REGION = os.environ.get("AWS_REGION", "eu-west-2")
secrets_manager = boto3.client("secretsmanager")
s3 = boto3.client(
    "s3",
    region_name=AWS_REGION,
    endpoint_url=f"https://s3.{AWS_REGION}.amazonaws.com",
    config=Config(signature_version="s3v4", s3={"addressing_style": "virtual"}),
)
sns = boto3.client("sns")
CLIENT_NOTIFICATION_SNS_TOPIC_ARN = os.environ["CLIENT_NOTIFICATION_SNS_TOPIC_ARN"]
CLIENT_DESTINATION_DELIVERY_CONFIG = json.loads(os.environ.get("CLIENT_DESTINATION_DELIVERY_CONFIG_JSON", "{}"))
DOWNLOAD_BUCKET_NAME = os.environ["DOWNLOAD_BUCKET_NAME"]
DOWNLOAD_URL_EXPIRY_SECONDS = int(os.environ["DOWNLOAD_URL_EXPIRY_SECONDS"])
IDEMPOTENCY_TABLE = os.environ["IDEMPOTENCY_TABLE"]
MAX_DOWNLOAD_URL_EXPIRY_SECONDS = int(os.environ["MAX_DOWNLOAD_URL_EXPIRY_SECONDS"])
SLACK_SNS_TOPIC_ARN = os.environ["SLACK_SNS_TOPIC_ARN"]
CLIENT_ID_METADATA_KEY = "client-id"
ORIGINAL_FILE_NAME_METADATA_KEY = "original-file-name"
TRANSFER_TICKET_METADATA_KEY = "transfer-ticket"
CLIENT_NOTIFICATION_EVENT_TYPE = "clean-file-ready-for-download"
TTL_METADATA_KEY = "presigned-url-expiry-seconds"
logger = Logger(service="managed-file-transfer-clean-file-presigned-url-notifier")
LOG_KEY_PATH_HASH_LENGTH = 12
DEFAULT_DESTINATION_REQUEST_TIMEOUT_SECONDS = 30

persistence_layer = DynamoDBPersistenceLayer(table_name=IDEMPOTENCY_TABLE)
idempotency_config = IdempotencyConfig(
    event_key_jmespath="[operation, bucket_name, object_key, version_id, notification_topic_arn]"
)


def iter_s3_events(event):
    if "Records" not in event:
        yield event
        return

    for record in event["Records"]:
        payload = record
        if "body" in record:
            payload = json.loads(record["body"])

        if "Records" in payload:
            for nested_record in payload["Records"]:
                yield nested_record
            continue

        yield payload


def normalise_record(record):
    if record.get("eventSource") != "aws:s3":
        raise ValueError(f"Unsupported event source: {record.get('eventSource')}")

    bucket_name = record["s3"]["bucket"]["name"]
    object_details = record["s3"]["object"]

    return {
        "operation": "clean-file-presigned-url-notification",
        "bucket_name": bucket_name,
        "object_key": unquote_plus(object_details["key"]),
        "version_id": object_details.get("versionId"),
        "notification_topic_arn": SLACK_SNS_TOPIC_ARN,
    }


def get_log_fields(operation):
    object_key = operation["object_key"]

    return {
        "bucket_name": operation["bucket_name"],
        "object_key": object_key.rsplit("/", 1)[-1],
        "object_key_path_hash": hashlib.sha256(object_key.encode("utf-8")).hexdigest()[:LOG_KEY_PATH_HASH_LENGTH],
        "version_id": operation["version_id"],
    }


def get_object_details(operation):
    head_object_kwargs = {
        "Bucket": operation["bucket_name"],
        "Key": operation["object_key"],
    }

    if operation["version_id"]:
        head_object_kwargs["VersionId"] = operation["version_id"]

    return s3.head_object(**head_object_kwargs)


def normalise_metadata(object_details):
    # Metadata is copied forward by the existing file-mover Lambdas, which lets
    # callers request a shorter TTL without changing infrastructure config.
    metadata = object_details.get("Metadata", {})
    return {key.lower(): value for key, value in metadata.items()}


def get_expiry_seconds(operation, metadata):
    expiry_value = metadata.get(TTL_METADATA_KEY, DOWNLOAD_URL_EXPIRY_SECONDS)

    try:
        expiry_seconds = int(expiry_value)
    except (TypeError, ValueError) as error:
        raise ValueError(
            f"Invalid {TTL_METADATA_KEY} metadata value for {operation['object_key']}: {expiry_value}"
        ) from error

    if expiry_seconds <= 0:
        raise ValueError(
            f"{TTL_METADATA_KEY} metadata must be a positive integer for {operation['object_key']}"
        )

    return min(expiry_seconds, MAX_DOWNLOAD_URL_EXPIRY_SECONDS)


def build_notification_message(operation, metadata, expiry_seconds, presigned_url):
    expires_at = datetime.now(UTC) + timedelta(seconds=expiry_seconds)
    expiry_minutes = max(1, (expiry_seconds + 59) // 60)
    file_name = metadata.get(ORIGINAL_FILE_NAME_METADATA_KEY) or operation["object_key"].rsplit("/", 1)[-1]
    lines = [
        "*Managed file transfer: clean file ready for download*",
        f"*File name:* `{file_name}`",
        f"*Bucket:* `{operation['bucket_name']}`",
        f"*Key:* `{operation['object_key']}`",
    ]

    if operation["version_id"]:
        lines.append(f"*VersionId:* `{operation['version_id']}`")

    lines.extend(
        [
            f"*Link valid for:* {expiry_minutes} minutes",
            f"*Expires at (UTC):* {expires_at.strftime('%Y-%m-%d %H:%M:%S')}",
            f"Download URL: <{presigned_url}|{file_name}>",
        ]
    )

    return {
        "version": "1.0",
        "source": "custom",
        "content": {
            "textType": "client-markdown",
            "description": "\n".join(lines),
        },
    }


def build_client_notification_message(operation, metadata, expiry_seconds, presigned_url):
    expires_at = datetime.now(UTC) + timedelta(seconds=expiry_seconds)
    file_name = metadata.get(ORIGINAL_FILE_NAME_METADATA_KEY) or operation["object_key"].rsplit("/", 1)[-1]

    return {
        "eventType": CLIENT_NOTIFICATION_EVENT_TYPE,
        "clientId": metadata.get(CLIENT_ID_METADATA_KEY),
        "transferTicket": metadata.get(TRANSFER_TICKET_METADATA_KEY),
        "fileName": file_name,
        "bucket": operation["bucket_name"],
        "key": operation["object_key"],
        "versionId": operation["version_id"],
        "downloadUrl": presigned_url,
        "downloadUrlExpiresInSeconds": expiry_seconds,
        "downloadUrlExpiresAtUtc": expires_at.strftime("%Y-%m-%dT%H:%M:%SZ"),
    }


def publish_client_notification(operation, metadata, expiry_seconds, presigned_url):
    client_id = metadata.get(CLIENT_ID_METADATA_KEY)
    if not client_id:
        logger.info(
            "Skipping client notification because client metadata is not present",
            extra=get_log_fields(operation),
        )
        return None

    notification_message = build_client_notification_message(operation, metadata, expiry_seconds, presigned_url)
    sns.publish(
        TopicArn=CLIENT_NOTIFICATION_SNS_TOPIC_ARN,
        Message=json.dumps(notification_message),
        MessageAttributes={
            "clientId": {
                "DataType": "String",
                "StringValue": client_id,
            },
            "eventType": {
                "DataType": "String",
                "StringValue": CLIENT_NOTIFICATION_EVENT_TYPE,
            },
        },
    )
    logger.info("Published client download notification", extra=get_log_fields(operation))
    return notification_message


def get_destination_delivery_config(client_id):
    config = CLIENT_DESTINATION_DELIVERY_CONFIG.get(client_id) or {}
    if not config or not config.get("enabled", False):
        return None

    request_url = config.get("request_url")
    if not request_url:
        raise ValueError(f"Missing request_url in destination delivery config for client {client_id}")

    from urllib.parse import urlsplit

    if urlsplit(request_url).scheme != "https":
        raise ValueError(f"Destination delivery request_url for client {client_id} must use https")

    return {
        "client_id": client_id,
        "request_auth_secret_name": config.get("request_auth_secret_name"),
        "request_headers": config.get("request_headers") or {},
        "request_method": str(config.get("request_method", "POST")).upper(),
        "request_timeout_seconds": int(
            config.get("request_timeout_seconds", DEFAULT_DESTINATION_REQUEST_TIMEOUT_SECONDS)
        ),
        "request_url": request_url,
    }


def load_secret_json(secret_id):
    response = secrets_manager.get_secret_value(SecretId=secret_id)
    secret_string = response.get("SecretString") or ""
    return json.loads(secret_string) if secret_string else {}


def build_destination_request_headers(config):
    headers = {
        "Accept": "application/json",
        "Content-Type": "application/json",
    }

    request_headers = config.get("request_headers") or {}
    if not isinstance(request_headers, dict):
        raise ValueError(
            f"request_headers in destination delivery config for client {config.get('client_id')} must be a JSON object"
        )

    headers.update({str(key): str(value) for key, value in request_headers.items()})

    secret_name = config.get("request_auth_secret_name")
    if not secret_name:
        return headers

    secret_payload = load_secret_json(secret_name)
    secret_headers = secret_payload.get("headers") or {}
    if not isinstance(secret_headers, dict):
        raise ValueError(f"headers in secret {secret_name} must be a JSON object")

    return {
        **headers,
        **{str(key): str(value) for key, value in secret_headers.items()},
    }


def build_destination_request_payload(operation, metadata, object_details):
    return {
        "clientId": metadata.get(CLIENT_ID_METADATA_KEY),
        "transferTicket": metadata.get(TRANSFER_TICKET_METADATA_KEY),
        "fileName": metadata.get(ORIGINAL_FILE_NAME_METADATA_KEY) or operation["object_key"].rsplit("/", 1)[-1],
        "contentLengthBytes": object_details.get("ContentLength"),
        "contentType": object_details.get("ContentType"),
        "source": {
            "bucket": operation["bucket_name"],
            "key": operation["object_key"],
            "versionId": operation["version_id"],
        },
    }


def request_destination_upload_target(operation, metadata, object_details, config):
    payload = json.dumps(build_destination_request_payload(operation, metadata, object_details))
    headers = build_destination_request_headers(config)
    logger.info(
        "Requesting destination presigned upload URL",
        extra={
            **get_log_fields(operation),
            "client_id": config["client_id"],
            "request_url": config["request_url"],
        },
    )
    response = requests.request(
        config["request_method"],
        config["request_url"],
        data=payload,
        headers=headers,
        timeout=config["request_timeout_seconds"],
    )
    response.raise_for_status()

    response_payload = response.json()
    upload_target = response_payload.get("upload", response_payload)
    upload_url = upload_target.get("url")
    if not upload_url:
        raise ValueError(
            f"Destination API for client {config['client_id']} did not return an upload URL"
        )

    upload_headers = upload_target.get("headers") or {}
    if not isinstance(upload_headers, dict):
        raise ValueError(
            f"Destination API for client {config['client_id']} returned non-object upload headers"
        )

    return {
        "headers": {str(key): str(value) for key, value in upload_headers.items()},
        "method": str(upload_target.get("method", "PUT")).upper(),
        "url": upload_url,
    }


class StreamingBodyWithLength:
    def __init__(self, body, content_length):
        self._body = body
        self._content_length = content_length

    def __len__(self):
        return self._content_length

    def read(self, amt=None):
        return self._body.read(amt)


def deliver_clean_file_to_destination(operation, metadata, object_details):
    client_id = metadata.get(CLIENT_ID_METADATA_KEY)
    if not client_id:
        logger.info(
            "Skipping client destination delivery because client metadata is not present",
            extra=get_log_fields(operation),
        )
        return None

    config = get_destination_delivery_config(client_id)
    if not config:
        logger.info(
            "Skipping client destination delivery because no client delivery config is present",
            extra={**get_log_fields(operation), "client_id": client_id},
        )
        return None

    upload_target = request_destination_upload_target(operation, metadata, object_details, config)
    get_object_kwargs = {
        "Bucket": operation["bucket_name"],
        "Key": operation["object_key"],
    }
    if operation["version_id"]:
        get_object_kwargs["VersionId"] = operation["version_id"]

    logger.info(
        "Uploading clean object to client destination",
        extra={**get_log_fields(operation), "client_id": client_id},
    )
    get_object_response = s3.get_object(**get_object_kwargs)
    body = get_object_response["Body"]
    upload_headers = dict(upload_target["headers"])
    upload_header_names = {header_name.lower() for header_name in upload_headers}
    if object_details.get("ContentType") and "content-type" not in upload_header_names:
        upload_headers["Content-Type"] = object_details["ContentType"]
    if "content-length" not in upload_header_names:
        upload_headers["Content-Length"] = str(object_details["ContentLength"])

    try:
        response = requests.request(
            upload_target["method"],
            upload_target["url"],
            data=StreamingBodyWithLength(body, object_details["ContentLength"]),
            headers=upload_headers,
            timeout=config["request_timeout_seconds"],
        )
        response.raise_for_status()
    finally:
        body.close()

    logger.info(
        "Uploaded clean object to client destination",
        extra={**get_log_fields(operation), "client_id": client_id},
    )
    return {
        "client_id": client_id,
        "destination_request_url": config["request_url"],
        "upload_method": upload_target["method"],
    }


@idempotent_function(
    data_keyword_argument="operation",
    persistence_store=persistence_layer,
    config=idempotency_config,
    key_prefix="managed-file-transfer/clean-file-presigned-url-notifier",
)
def process_record(*, operation):
    logger.info("Generating presigned URL for clean S3 object", extra=get_log_fields(operation))

    if operation["bucket_name"] != DOWNLOAD_BUCKET_NAME:
        raise ValueError(
            f"Received clean file notification for unexpected bucket {operation['bucket_name']}"
        )

    object_details = get_object_details(operation)
    metadata = normalise_metadata(object_details)
    expiry_seconds = get_expiry_seconds(operation, metadata)
    presign_params = {
        "Bucket": operation["bucket_name"],
        "Key": operation["object_key"],
    }

    if operation["version_id"]:
        presign_params["VersionId"] = operation["version_id"]

    presigned_url = s3.generate_presigned_url(
        "get_object",
        Params=presign_params,
        ExpiresIn=expiry_seconds,
    )
    destination_delivery = deliver_clean_file_to_destination(operation, metadata, object_details)

    notification_message = build_notification_message(operation, metadata, expiry_seconds, presigned_url)
    sns.publish(
        TopicArn=operation["notification_topic_arn"],
        Message=json.dumps(notification_message),
    )

    logger.info("Published presigned URL notification", extra=get_log_fields(operation))
    client_notification = publish_client_notification(operation, metadata, expiry_seconds, presigned_url)

    return {
        "bucket_name": operation["bucket_name"],
        "client_id": metadata.get(CLIENT_ID_METADATA_KEY),
        "expiry_seconds": expiry_seconds,
        "client_notification_topic_arn": CLIENT_NOTIFICATION_SNS_TOPIC_ARN if client_notification else None,
        "notification_topic_arn": operation["notification_topic_arn"],
        "object_key": operation["object_key"],
        "destination_delivery": destination_delivery,
        "version_id": operation["version_id"],
    }


@logger.inject_lambda_context(clear_state=True, log_event=False)
def lambda_handler(event, context):
    idempotency_config.register_lambda_context(context)

    for record in iter_s3_events(event):
        operation = None

        try:
            operation = normalise_record(record)
            process_record(operation=operation)
        except Exception:
            logger.exception(
                "Failed to generate presigned URL notification",
                extra=get_log_fields(operation) if operation else {},
            )
            raise
