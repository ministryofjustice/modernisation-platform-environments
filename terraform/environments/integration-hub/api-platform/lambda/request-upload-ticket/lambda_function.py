import base64
import json
import os
import posixpath
import re
import uuid
from datetime import UTC, datetime
from pathlib import Path

import boto3


S3_CLIENT = boto3.client("s3")
DYNAMODB = boto3.resource("dynamodb")

TRANSFER_CLIENTS_TABLE = os.environ["TRANSFER_CLIENTS_TABLE"]
UPLOAD_BUCKET_NAME = os.environ["UPLOAD_BUCKET_NAME"]
UPLOAD_BUCKET_KMS_KEY_ARN = os.environ["UPLOAD_BUCKET_KMS_KEY_ARN"]
DEFAULT_EXPIRY_SECONDS = int(os.environ["PRESIGNED_URL_EXPIRY_SECONDS"])
MAX_EXPIRY_SECONDS = int(os.environ["MAX_PRESIGNED_URL_EXPIRY_SECONDS"])


def _response(status_code, body):
    return {
        "statusCode": status_code,
        "headers": {
            "content-type": "application/json",
            "cache-control": "no-store",
        },
        "body": json.dumps(body),
    }


def _load_body(event):
    body = event.get("body")
    if body is None:
        return {}

    if event.get("isBase64Encoded"):
        body = json.loads(base64.b64decode(body).decode("utf-8"))
    elif isinstance(body, str):
        body = json.loads(body)

    if not isinstance(body, dict):
        raise ValueError("Request body must be a JSON object")

    return body


def _normalise_extension(file_name):
    suffix = Path(file_name).suffix.lower()
    return suffix if re.fullmatch(r"\.[a-z0-9]{1,10}", suffix) else ""


def _build_object_key(prefix, file_name):
    today_prefix = datetime.now(UTC).strftime("%Y/%m/%d")
    generated_name = f"{uuid.uuid4()}{_normalise_extension(file_name)}"
    return posixpath.join(prefix.strip("/"), today_prefix, generated_name)


def _authorizer_context(event):
    authorizer = event.get("requestContext", {}).get("authorizer", {})
    if isinstance(authorizer.get("lambda"), dict):
        return authorizer["lambda"]
    return authorizer


def _allowed_client_ids(event):
    context = _authorizer_context(event)
    raw_value = context.get("allowedClientIds", "")
    if not raw_value:
        return set()
    return {value for value in raw_value.split(",") if value}


def lambda_handler(event, _context):
    try:
        request = _load_body(event)
    except (ValueError, json.JSONDecodeError) as exc:
        return _response(400, {"message": str(exc)})

    client_id = request.get("clientId")
    file_name = request.get("fileName")

    if not client_id or not file_name:
        return _response(400, {"message": "clientId and fileName are required"})

    allowed_client_ids = _allowed_client_ids(event)
    if not allowed_client_ids or ("*" not in allowed_client_ids and client_id not in allowed_client_ids):
        return _response(403, {"message": f"Not authorised to request tickets for clientId '{client_id}'"})

    table = DYNAMODB.Table(TRANSFER_CLIENTS_TABLE)
    record = table.get_item(Key={"client_id": client_id}).get("Item")

    if record is None:
        return _response(404, {"message": f"Unknown clientId '{client_id}'"})

    if not record.get("enabled", True):
        return _response(403, {"message": f"Client '{client_id}' is disabled"})

    content_type = request.get("contentType")
    allowed_content_types = record.get("allowed_content_types", [])
    if allowed_content_types and content_type not in allowed_content_types:
        return _response(
            400,
            {
                "message": "contentType is not allowed for this client",
                "allowedContentTypes": allowed_content_types,
            },
        )

    size_bytes = request.get("sizeBytes")
    try:
        size_bytes_int = int(size_bytes) if size_bytes is not None else None
    except (TypeError, ValueError):
        return _response(400, {"message": "sizeBytes must be an integer"})

    max_upload_size_bytes = int(record.get("max_upload_size_bytes", 0))
    if size_bytes_int is not None and max_upload_size_bytes and size_bytes_int > max_upload_size_bytes:
        return _response(
            400,
            {
                "message": "Requested file size exceeds the configured limit",
                "maxUploadSizeBytes": max_upload_size_bytes,
            },
        )

    try:
        requested_expiry_seconds = int(
            request.get("requestedExpirySeconds", DEFAULT_EXPIRY_SECONDS)
        )
    except (TypeError, ValueError):
        return _response(400, {"message": "requestedExpirySeconds must be an integer"})
    expiry_seconds = max(1, min(requested_expiry_seconds, MAX_EXPIRY_SECONDS))
    transfer_ticket = str(uuid.uuid4())
    object_key = _build_object_key(record["key_prefix"], file_name)
    content_md5 = request.get("contentMd5")

    put_object_params = {
        "Bucket": UPLOAD_BUCKET_NAME,
        "Key": object_key,
        "Metadata": {
            "client-id": client_id,
            "original-file-name": Path(file_name).name,
            "transfer-ticket": transfer_ticket,
        },
        "ServerSideEncryption": "aws:kms",
        "SSEKMSKeyId": UPLOAD_BUCKET_KMS_KEY_ARN,
    }
    required_headers = {
        "x-amz-server-side-encryption": "aws:kms",
        "x-amz-server-side-encryption-aws-kms-key-id": UPLOAD_BUCKET_KMS_KEY_ARN,
        "x-amz-meta-client-id": client_id,
        "x-amz-meta-original-file-name": Path(file_name).name,
        "x-amz-meta-transfer-ticket": transfer_ticket,
    }

    if content_type:
        put_object_params["ContentType"] = content_type
        required_headers["Content-Type"] = content_type

    if content_md5:
        put_object_params["ContentMD5"] = content_md5
        required_headers["Content-MD5"] = content_md5

    presigned_url = S3_CLIENT.generate_presigned_url(
        ClientMethod="put_object",
        Params=put_object_params,
        ExpiresIn=expiry_seconds,
        HttpMethod="PUT",
    )

    return _response(
        200,
        {
            "transferTicket": transfer_ticket,
            "clientId": client_id,
            "upload": {
                "method": "PUT",
                "url": presigned_url,
                "headers": required_headers,
                "expiresInSeconds": expiry_seconds,
            },
            "object": {
                "bucket": UPLOAD_BUCKET_NAME,
                "key": object_key,
            },
        },
    )
