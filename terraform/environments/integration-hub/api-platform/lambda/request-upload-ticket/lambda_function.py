import base64
import json
import math
import os
import posixpath
import re
import uuid
from datetime import datetime, timezone
from pathlib import Path

import boto3


S3_CLIENT = boto3.client("s3")
DYNAMODB = boto3.resource("dynamodb")

TRANSFER_CLIENTS_TABLE = os.environ["TRANSFER_CLIENTS_TABLE"]
MULTIPART_SESSIONS_TABLE = os.environ["MULTIPART_SESSIONS_TABLE"]
UPLOAD_BUCKET_NAME = os.environ["UPLOAD_BUCKET_NAME"]
UPLOAD_BUCKET_KMS_KEY_ARN = os.environ["UPLOAD_BUCKET_KMS_KEY_ARN"]
DEFAULT_EXPIRY_SECONDS = int(os.environ["PRESIGNED_URL_EXPIRY_SECONDS"])
MAX_EXPIRY_SECONDS = int(os.environ["MAX_PRESIGNED_URL_EXPIRY_SECONDS"])
SINGLE_PUT_LIMIT_BYTES = int(os.environ["SINGLE_PUT_LIMIT_BYTES"])
MULTIPART_DEFAULT_PART_SIZE_BYTES = int(os.environ["MULTIPART_DEFAULT_PART_SIZE_BYTES"])
MULTIPART_INITIAL_PRESIGN_PARTS = int(os.environ["MULTIPART_INITIAL_PRESIGN_PARTS"])
MULTIPART_MAX_PARTS = int(os.environ["MULTIPART_MAX_PARTS"])

MIN_MULTIPART_PART_SIZE_BYTES = 5 * 1024 * 1024
MULTIPART_SESSION_TTL_SECONDS = 7 * 24 * 60 * 60


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
    today_prefix = datetime.now(timezone.utc).strftime("%Y/%m/%d")
    generated_name = f"{uuid.uuid4()}{_normalise_extension(file_name)}"
    return posixpath.join(prefix.strip("/"), today_prefix, generated_name)


def _authorizer_context(event):
    authorizer = event.get("requestContext", {}).get("authorizer", {})
    if isinstance(authorizer.get("lambda"), dict):
        return authorizer["lambda"]
    return authorizer


def _principal_context(event):
    context = _authorizer_context(event)
    return {
        "principal_id": context.get("principalId", ""),
        "role_name": context.get("roleName", ""),
        "auth_type": context.get("authType", ""),
    }


def _allowed_client_ids(event):
    context = _authorizer_context(event)
    raw_value = context.get("allowedClientIds", "")
    if not raw_value:
        return set()
    return {value for value in raw_value.split(",") if value}


def _get_transfer_client(client_id):
    table = DYNAMODB.Table(TRANSFER_CLIENTS_TABLE)
    return table.get_item(Key={"client_id": client_id}).get("Item")


def _get_multipart_session(transfer_ticket):
    table = DYNAMODB.Table(MULTIPART_SESSIONS_TABLE)
    return table.get_item(Key={"transfer_ticket": transfer_ticket}).get("Item")


def _update_multipart_session(transfer_ticket, status, extra_attributes=None):
    table = DYNAMODB.Table(MULTIPART_SESSIONS_TABLE)
    now_iso = datetime.now(timezone.utc).isoformat()
    extra_attributes = extra_attributes or {}
    expression_names = {"#status": "status", "#updated_at": "updated_at"}
    expression_values = {
        ":status": status,
        ":updated_at": now_iso,
    }
    update_terms = ["#status = :status", "#updated_at = :updated_at"]

    for key, value in extra_attributes.items():
        name_key = f"#attr_{key}"
        value_key = f":attr_{key}"
        expression_names[name_key] = key
        expression_values[value_key] = value
        update_terms.append(f"{name_key} = {value_key}")

    table.update_item(
        Key={"transfer_ticket": transfer_ticket},
        UpdateExpression="SET " + ", ".join(update_terms),
        ExpressionAttributeNames=expression_names,
        ExpressionAttributeValues=expression_values,
    )


def _validate_client_access(client_id, allowed_client_ids):
    if not allowed_client_ids or ("*" not in allowed_client_ids and client_id not in allowed_client_ids):
        return _response(403, {"message": f"Not authorised to access clientId '{client_id}'"})
    return None


def _load_and_validate_client(client_id, allowed_client_ids):
    access_error = _validate_client_access(client_id, allowed_client_ids)
    if access_error:
        return None, access_error

    record = _get_transfer_client(client_id)
    if record is None:
        return None, _response(404, {"message": f"Unknown clientId '{client_id}'"})

    if not record.get("enabled", True):
        return None, _response(403, {"message": f"Client '{client_id}' is disabled"})

    return record, None


def _parse_optional_int(request, field_name):
    value = request.get(field_name)
    if value is None:
        return None, None

    try:
        return int(value), None
    except (TypeError, ValueError):
        return None, _response(400, {"message": f"{field_name} must be an integer"})


def _resolve_expiry_seconds(request):
    try:
        requested_expiry_seconds = int(request.get("requestedExpirySeconds", DEFAULT_EXPIRY_SECONDS))
    except (TypeError, ValueError):
        return None, _response(400, {"message": "requestedExpirySeconds must be an integer"})

    return max(1, min(requested_expiry_seconds, MAX_EXPIRY_SECONDS)), None


def _validate_content_type(content_type, record):
    allowed_content_types = record.get("allowed_content_types", [])
    if allowed_content_types and content_type not in allowed_content_types:
        return _response(
            400,
            {
                "message": "contentType is not allowed for this client",
                "allowedContentTypes": allowed_content_types,
            },
        )
    return None


def _validate_file_size(size_bytes, max_upload_size_bytes):
    if size_bytes is None:
        return _response(400, {"message": "sizeBytes is required"})

    if size_bytes < 0:
        return _response(400, {"message": "sizeBytes must be greater than or equal to 0"})

    if max_upload_size_bytes and size_bytes > max_upload_size_bytes:
        return _response(
            400,
            {
                "message": "Requested file size exceeds the configured limit",
                "maxUploadSizeBytes": max_upload_size_bytes,
            },
        )
    return None


def _select_upload_mode(size_bytes):
    return "multipart" if size_bytes > SINGLE_PUT_LIMIT_BYTES else "single"


def _round_up(value, increment):
    return int(math.ceil(value / increment) * increment)


def _resolve_part_size_bytes(size_bytes):
    required_part_size = max(
        MULTIPART_DEFAULT_PART_SIZE_BYTES,
        MIN_MULTIPART_PART_SIZE_BYTES,
        int(math.ceil(size_bytes / MULTIPART_MAX_PARTS)),
    )
    part_size_bytes = _round_up(required_part_size, MIN_MULTIPART_PART_SIZE_BYTES)
    total_parts = int(math.ceil(size_bytes / part_size_bytes))

    if total_parts > MULTIPART_MAX_PARTS:
        return None, _response(
            400,
            {
                "message": "Requested file size exceeds multipart part limits",
                "multipartMaxParts": MULTIPART_MAX_PARTS,
            },
        )

    return part_size_bytes, None


def _generate_single_upload(record, request, expiry_seconds):
    file_name = request["fileName"]
    client_id = request["clientId"]
    transfer_ticket = str(uuid.uuid4())
    object_key = _build_object_key(record["key_prefix"], file_name)
    content_type = request.get("contentType")
    content_md5 = request.get("contentMd5")

    put_object_params = {
        "Bucket": UPLOAD_BUCKET_NAME,
        "Key": object_key,
        "Metadata": {
            "client-id": client_id,
            "declared-size-bytes": str(request["sizeBytes"]),
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
        "x-amz-meta-declared-size-bytes": str(request["sizeBytes"]),
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


def _build_session_item(request, principal, transfer_ticket, upload_id, object_key, expiry_seconds, part_size_bytes, total_parts):
    now = datetime.now(timezone.utc)
    item = {
        "transfer_ticket": transfer_ticket,
        "status": "initiated",
        "client_id": request["clientId"],
        "file_name": Path(request["fileName"]).name,
        "bucket": UPLOAD_BUCKET_NAME,
        "object_key": object_key,
        "upload_id": upload_id,
        "principal_id": principal["principal_id"],
        "role_name": principal["role_name"],
        "auth_type": principal["auth_type"],
        "declared_size_bytes": request["sizeBytes"],
        "expires_in_seconds": expiry_seconds,
        "part_size_bytes": part_size_bytes,
        "created_at": now.isoformat(),
        "updated_at": now.isoformat(),
        "expires_at_epoch": int(now.timestamp()) + MULTIPART_SESSION_TTL_SECONDS,
    }

    if request.get("contentType"):
        item["content_type"] = request["contentType"]
    if total_parts is not None:
        item["total_parts"] = total_parts
    return item


def _build_multipart_part_presign(transfer_ticket, upload_id, object_key, part_number, expiry_seconds):
    presigned_url = S3_CLIENT.generate_presigned_url(
        ClientMethod="upload_part",
        Params={
            "Bucket": UPLOAD_BUCKET_NAME,
            "Key": object_key,
            "PartNumber": part_number,
            "UploadId": upload_id,
        },
        ExpiresIn=expiry_seconds,
        HttpMethod="PUT",
    )
    return {
        "partNumber": part_number,
        "method": "PUT",
        "url": presigned_url,
        "headers": {},
        "expiresInSeconds": expiry_seconds,
    }


def _persist_multipart_session(item):
    table = DYNAMODB.Table(MULTIPART_SESSIONS_TABLE)
    table.put_item(Item=item)


def _generate_initial_parts(transfer_ticket, upload_id, object_key, expiry_seconds, total_parts):
    if MULTIPART_INITIAL_PRESIGN_PARTS <= 0:
        return []

    if total_parts is None:
        upper_bound = MULTIPART_INITIAL_PRESIGN_PARTS
    else:
        upper_bound = min(total_parts, MULTIPART_INITIAL_PRESIGN_PARTS)

    return [
        _build_multipart_part_presign(transfer_ticket, upload_id, object_key, part_number, expiry_seconds)
        for part_number in range(1, upper_bound + 1)
    ]


def _generate_multipart_upload(record, request, principal, expiry_seconds, size_bytes):
    if request.get("contentMd5"):
        return _response(
            400,
            {"message": "contentMd5 is only supported for single-part uploads"},
        )

    part_size_bytes, error_response = _resolve_part_size_bytes(size_bytes)
    if error_response:
        return error_response

    total_parts = int(math.ceil(size_bytes / part_size_bytes)) if size_bytes else None
    transfer_ticket = str(uuid.uuid4())
    object_key = _build_object_key(record["key_prefix"], request["fileName"])

    create_request = {
        "Bucket": UPLOAD_BUCKET_NAME,
        "Key": object_key,
        "Metadata": {
            "client-id": request["clientId"],
            "declared-size-bytes": str(request["sizeBytes"]),
            "original-file-name": Path(request["fileName"]).name,
            "transfer-ticket": transfer_ticket,
        },
        "ServerSideEncryption": "aws:kms",
        "SSEKMSKeyId": UPLOAD_BUCKET_KMS_KEY_ARN,
    }
    if request.get("contentType"):
        create_request["ContentType"] = request["contentType"]

    multipart_response = S3_CLIENT.create_multipart_upload(**create_request)
    upload_id = multipart_response["UploadId"]

    session_item = _build_session_item(
        request=request,
        principal=principal,
        transfer_ticket=transfer_ticket,
        upload_id=upload_id,
        object_key=object_key,
        expiry_seconds=expiry_seconds,
        part_size_bytes=part_size_bytes,
        total_parts=total_parts,
    )
    _persist_multipart_session(session_item)

    return _response(
        200,
        {
            "transferTicket": transfer_ticket,
            "clientId": request["clientId"],
            "object": {
                "bucket": UPLOAD_BUCKET_NAME,
                "key": object_key,
            },
            "multipart": {
                "uploadId": upload_id,
                "partSizeBytes": part_size_bytes,
                "totalParts": total_parts,
                "maxParts": MULTIPART_MAX_PARTS,
                "expiresInSeconds": expiry_seconds,
                "initialParts": _generate_initial_parts(
                    transfer_ticket=transfer_ticket,
                    upload_id=upload_id,
                    object_key=object_key,
                    expiry_seconds=expiry_seconds,
                    total_parts=total_parts,
                ),
                "operations": {
                    "presignPartsPath": f"/transfer-tickets/{transfer_ticket}/parts",
                    "completePath": f"/transfer-tickets/{transfer_ticket}/complete",
                    "abortPath": f"/transfer-tickets/{transfer_ticket}",
                },
            },
        },
    )


def _normalise_part_numbers(request, session):
    part_numbers = request.get("partNumbers")
    part_number_start = request.get("partNumberStart")
    part_number_end = request.get("partNumberEnd")

    if part_numbers is not None and (part_number_start is not None or part_number_end is not None):
        return None, _response(400, {"message": "Use either partNumbers or partNumberStart/partNumberEnd"})

    if part_numbers is not None:
        if not isinstance(part_numbers, list) or not part_numbers:
            return None, _response(400, {"message": "partNumbers must be a non-empty array"})
        values = part_numbers
    else:
        if part_number_start is None or part_number_end is None:
            return None, _response(400, {"message": "Provide partNumbers or both partNumberStart and partNumberEnd"})
        try:
            start_value = int(part_number_start)
            end_value = int(part_number_end)
        except (TypeError, ValueError):
            return None, _response(400, {"message": "partNumberStart and partNumberEnd must be integers"})
        if start_value > end_value:
            return None, _response(400, {"message": "partNumberStart must be less than or equal to partNumberEnd"})
        values = list(range(start_value, end_value + 1))

    try:
        normalised = sorted({int(value) for value in values})
    except (TypeError, ValueError):
        return None, _response(400, {"message": "Part numbers must be integers"})

    if not normalised:
        return None, _response(400, {"message": "At least one part number is required"})

    if any(part_number < 1 or part_number > MULTIPART_MAX_PARTS for part_number in normalised):
        return None, _response(
            400,
            {"message": f"Part numbers must be between 1 and {MULTIPART_MAX_PARTS}"},
        )

    total_parts = session.get("total_parts")
    if total_parts is not None and any(part_number > int(total_parts) for part_number in normalised):
        return None, _response(
            400,
            {
                "message": "Requested part number exceeds the number of parts for this upload",
                "totalParts": int(total_parts),
            },
        )

    return normalised, None


def _load_active_session(transfer_ticket, allowed_client_ids):
    session = _get_multipart_session(transfer_ticket)
    if session is None:
        return None, _response(404, {"message": f"Unknown transfer ticket '{transfer_ticket}'"})

    expires_at_epoch = session.get("expires_at_epoch")
    if expires_at_epoch is not None and int(expires_at_epoch) <= int(datetime.now(timezone.utc).timestamp()):
        return None, _response(409, {"message": f"Transfer ticket '{transfer_ticket}' has expired"})

    access_error = _validate_client_access(session["client_id"], allowed_client_ids)
    if access_error:
        return None, access_error

    if session.get("status") != "initiated":
        return None, _response(
            409,
            {
                "message": f"Transfer ticket '{transfer_ticket}' is not active",
                "status": session.get("status"),
            },
        )

    return session, None


def _handle_create_transfer_ticket(event):
    try:
        request = _load_body(event)
    except (ValueError, json.JSONDecodeError) as exc:
        return _response(400, {"message": str(exc)})

    client_id = request.get("clientId")
    file_name = request.get("fileName")
    if not client_id or not file_name:
        return _response(400, {"message": "clientId and fileName are required"})

    allowed_client_ids = _allowed_client_ids(event)
    record, error_response = _load_and_validate_client(client_id, allowed_client_ids)
    if error_response:
        return error_response

    content_type = request.get("contentType")
    error_response = _validate_content_type(content_type, record)
    if error_response:
        return error_response

    size_bytes, error_response = _parse_optional_int(request, "sizeBytes")
    if error_response:
        return error_response

    max_upload_size_bytes = int(record.get("max_upload_size_bytes", 0))
    error_response = _validate_file_size(size_bytes, max_upload_size_bytes)
    if error_response:
        return error_response

    upload_mode = _select_upload_mode(size_bytes)

    expiry_seconds, error_response = _resolve_expiry_seconds(request)
    if error_response:
        return error_response

    if upload_mode == "multipart":
        return _generate_multipart_upload(
            record=record,
            request=request,
            principal=_principal_context(event),
            expiry_seconds=expiry_seconds,
            size_bytes=size_bytes,
        )

    return _generate_single_upload(record=record, request=request, expiry_seconds=expiry_seconds)


def _handle_presign_parts(event):
    transfer_ticket = (event.get("pathParameters") or {}).get("transferTicket")
    if not transfer_ticket:
        return _response(400, {"message": "transferTicket path parameter is required"})

    try:
        request = _load_body(event)
    except (ValueError, json.JSONDecodeError) as exc:
        return _response(400, {"message": str(exc)})

    session, error_response = _load_active_session(transfer_ticket, _allowed_client_ids(event))
    if error_response:
        return error_response

    part_numbers, error_response = _normalise_part_numbers(request, session)
    if error_response:
        return error_response

    parts = [
        _build_multipart_part_presign(
            transfer_ticket=transfer_ticket,
            upload_id=session["upload_id"],
            object_key=session["object_key"],
            part_number=part_number,
            expiry_seconds=int(session["expires_in_seconds"]),
        )
        for part_number in part_numbers
    ]

    return _response(
        200,
        {
            "transferTicket": transfer_ticket,
            "clientId": session["client_id"],
            "uploadId": session["upload_id"],
            "parts": parts,
        },
    )


def _handle_complete_multipart(event):
    transfer_ticket = (event.get("pathParameters") or {}).get("transferTicket")
    if not transfer_ticket:
        return _response(400, {"message": "transferTicket path parameter is required"})

    try:
        request = _load_body(event)
    except (ValueError, json.JSONDecodeError) as exc:
        return _response(400, {"message": str(exc)})

    session, error_response = _load_active_session(transfer_ticket, _allowed_client_ids(event))
    if error_response:
        return error_response

    parts = request.get("parts")
    if not isinstance(parts, list) or not parts:
        return _response(400, {"message": "parts must be a non-empty array"})

    normalised_parts = []
    try:
        for entry in parts:
            part_number = int(entry["partNumber"])
            etag = str(entry["eTag"]).strip()
            if not etag:
                raise ValueError("ETag must not be empty")
            normalised_parts.append({"PartNumber": part_number, "ETag": etag})
    except (KeyError, TypeError, ValueError) as exc:
        return _response(400, {"message": f"Invalid multipart completion payload: {exc}"})

    normalised_parts.sort(key=lambda item: item["PartNumber"])
    if len({item["PartNumber"] for item in normalised_parts}) != len(normalised_parts):
        return _response(400, {"message": "Duplicate partNumber values are not allowed"})

    if any(item["PartNumber"] < 1 or item["PartNumber"] > MULTIPART_MAX_PARTS for item in normalised_parts):
        return _response(400, {"message": f"partNumber must be between 1 and {MULTIPART_MAX_PARTS}"})

    complete_response = S3_CLIENT.complete_multipart_upload(
        Bucket=session["bucket"],
        Key=session["object_key"],
        UploadId=session["upload_id"],
        MultipartUpload={"Parts": normalised_parts},
    )

    _update_multipart_session(
        transfer_ticket,
        "completed",
        {
            "completed_at": datetime.now(timezone.utc).isoformat(),
            "completed_etag": complete_response.get("ETag", ""),
        },
    )

    return _response(
        200,
        {
            "transferTicket": transfer_ticket,
            "clientId": session["client_id"],
            "status": "completed",
            "object": {
                "bucket": session["bucket"],
                "key": session["object_key"],
            },
            "result": {
                "eTag": complete_response.get("ETag"),
                "location": complete_response.get("Location"),
                "partCount": len(normalised_parts),
            },
        },
    )


def _handle_abort_multipart(event):
    transfer_ticket = (event.get("pathParameters") or {}).get("transferTicket")
    if not transfer_ticket:
        return _response(400, {"message": "transferTicket path parameter is required"})

    session, error_response = _load_active_session(transfer_ticket, _allowed_client_ids(event))
    if error_response:
        return error_response

    S3_CLIENT.abort_multipart_upload(
        Bucket=session["bucket"],
        Key=session["object_key"],
        UploadId=session["upload_id"],
    )

    _update_multipart_session(
        transfer_ticket,
        "aborted",
        {"aborted_at": datetime.now(timezone.utc).isoformat()},
    )

    return _response(
        200,
        {
            "transferTicket": transfer_ticket,
            "clientId": session["client_id"],
            "status": "aborted",
        },
    )


def lambda_handler(event, _context):
    route_key = event.get("routeKey")

    if route_key == "POST /transfer-tickets":
        return _handle_create_transfer_ticket(event)
    if route_key == "POST /transfer-tickets/{transferTicket}/parts":
        return _handle_presign_parts(event)
    if route_key == "POST /transfer-tickets/{transferTicket}/complete":
        return _handle_complete_multipart(event)
    if route_key == "DELETE /transfer-tickets/{transferTicket}":
        return _handle_abort_multipart(event)

    return _response(404, {"message": f"Unsupported route '{route_key}'"})
