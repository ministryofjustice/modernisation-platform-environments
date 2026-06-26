import hashlib
import json
import os
from datetime import UTC, datetime, timedelta
from urllib.parse import unquote_plus

import boto3
from aws_lambda_powertools import Logger
from aws_lambda_powertools.utilities.idempotency import (
    DynamoDBPersistenceLayer,
    IdempotencyConfig,
    idempotent_function,
)

s3 = boto3.client("s3")
sns = boto3.client("sns")
CLIENT_NOTIFICATION_SNS_TOPIC_ARN = os.environ["CLIENT_NOTIFICATION_SNS_TOPIC_ARN"]
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


def get_object_metadata(operation):
    head_object_kwargs = {
        "Bucket": operation["bucket_name"],
        "Key": operation["object_key"],
    }

    if operation["version_id"]:
        head_object_kwargs["VersionId"] = operation["version_id"]

    # Metadata is copied forward by the existing file-mover Lambdas, which lets
    # callers request a shorter TTL without changing infrastructure config.
    metadata = s3.head_object(**head_object_kwargs).get("Metadata", {})
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


def build_notification_message(operation, expiry_seconds, presigned_url):
    expires_at = datetime.now(UTC) + timedelta(seconds=expiry_seconds)
    expiry_minutes = max(1, (expiry_seconds + 59) // 60)
    file_name = operation["object_key"].rsplit("/", 1)[-1]
    lines = [
        "*Managed file transfer: clean file ready for download*",
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

    metadata = get_object_metadata(operation)
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
    notification_message = build_notification_message(operation, expiry_seconds, presigned_url)

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
