import math
from collections.abc import Mapping
from typing import Any

from mft_writer.diagnostics import (
    _aws_error_fields,
    _remaining_millis,
    _update_log_fields,
    ensure_time,
    logger,
)
from mft_writer.errors import InvalidMessage

MAX_COPY_OBJECT_BYTES = 5 * 1000**3
MULTIPART_PART_BYTES = 512 * 1024**2
MIN_MULTIPART_PART_BYTES = 5 * 1024**2
MAX_MULTIPART_PART_BYTES = 5 * 1024**3
MAX_S3_PARTS = 10_000
MAX_MULTIPART_OBJECT_BYTES = MAX_S3_PARTS * MAX_MULTIPART_PART_BYTES
MIN_ABORT_REMAINING_MILLIS = 50_000


def _copy_source(source: Mapping[str, Any]) -> dict[str, str]:
    return {
        "Bucket": source["bucket"],
        "Key": source["key"],
        "VersionId": source["versionId"],
    }


def _copy_metadata(head: Mapping[str, Any]) -> dict[str, Any]:
    return {
        key: head[key]
        for key in (
            "CacheControl",
            "ContentDisposition",
            "ContentEncoding",
            "ContentLanguage",
            "ContentType",
            "Expires",
            "Metadata",
        )
        if key in head
    }


def _multipart_part_size(size: int) -> int:
    if size > MAX_MULTIPART_OBJECT_BYTES:
        raise InvalidMessage("source object exceeds the supported S3 object size limit")
    required = max(MULTIPART_PART_BYTES, math.ceil(size / MAX_S3_PARTS))
    part_size = math.ceil(required / (1024 * 1024)) * 1024 * 1024
    if part_size > MAX_MULTIPART_PART_BYTES:
        raise InvalidMessage("source object exceeds the supported multipart copy limits")
    return max(part_size, MIN_MULTIPART_PART_BYTES)


def copy_versioned_object(
    s3: Any,
    source: Mapping[str, Any],
    route: Mapping[str, Any],
    action_name: str,
    context: Any,
    log_fields: dict[str, Any] | None = None,
) -> tuple[str | None, int]:
    ensure_time(context, "source head")
    _update_log_fields(log_fields, operation="HeadObject")
    head = s3.head_object(
        Bucket=source["bucket"], Key=source["key"], VersionId=source["versionId"]
    )
    size = int(head["ContentLength"])
    if size != source["sizeBytes"]:
        raise InvalidMessage("source object size does not match the requested version")
    if size > MAX_MULTIPART_OBJECT_BYTES:
        raise InvalidMessage("source object exceeds the supported S3 object size limit")

    encryption = {
        "ServerSideEncryption": "aws:kms",
        "SSEKMSKeyId": route["kms_key_arn"],
    }
    if action_name == "push-to-s3-with-hosted-pickup":
        encryption["BucketKeyEnabled"] = True
    destination = {"Bucket": route["destination_bucket"], "Key": route["destination_key"]}

    if size <= MAX_COPY_OBJECT_BYTES:
        ensure_time(context, "CopyObject")
        _update_log_fields(log_fields, operation="CopyObject")
        response = s3.copy_object(
            **destination,
            CopySource=_copy_source(source),
            MetadataDirective="COPY",
            TaggingDirective="REPLACE",
            **encryption,
        )
        return response.get("VersionId"), size

    part_size = _multipart_part_size(size)
    total_parts = math.ceil(size / part_size)
    ensure_time(context, "CreateMultipartUpload")
    _update_log_fields(log_fields, operation="CreateMultipartUpload")
    created = s3.create_multipart_upload(
        **destination,
        **_copy_metadata(head),
        **encryption,
    )
    upload_id = created["UploadId"]
    _update_log_fields(log_fields, uploadId=upload_id, bytesCopied=0)
    completed_parts: list[dict[str, Any]] = []
    try:
        for part_number in range(1, total_parts + 1):
            ensure_time(context, "UploadPartCopy")
            start = (part_number - 1) * part_size
            end = min(start + part_size, size) - 1
            _update_log_fields(
                log_fields,
                operation="UploadPartCopy",
                partNumber=part_number,
                totalParts=total_parts,
            )
            response = s3.upload_part_copy(
                **destination,
                UploadId=upload_id,
                PartNumber=part_number,
                CopySource=_copy_source(source),
                CopySourceRange=f"bytes={start}-{end}",
            )
            completed_parts.append(
                {"PartNumber": part_number, "ETag": response["CopyPartResult"]["ETag"]}
            )
            _update_log_fields(log_fields, bytesCopied=end + 1)
        ensure_time(context, "CompleteMultipartUpload")
        _update_log_fields(log_fields, operation="CompleteMultipartUpload")
        response = s3.complete_multipart_upload(
            **destination,
            UploadId=upload_id,
            MultipartUpload={"Parts": completed_parts},
        )
        return response.get("VersionId"), size
    except Exception:
        if _remaining_millis(context) >= MIN_ABORT_REMAINING_MILLIS:
            try:
                s3.abort_multipart_upload(**destination, UploadId=upload_id)
            except Exception as abort_error:  # noqa: BLE001
                logger.warning(
                    "multipart abort failed",
                    **_aws_error_fields(abort_error),
                    sourceBucket=source["bucket"],
                    sourceKey=source["key"],
                    destinationBucket=route["destination_bucket"],
                    destinationKey=route["destination_key"],
                )
        raise