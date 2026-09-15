from dataclasses import dataclass

from mft_file_mover.model import SUPPORTED_SCAN_RESULTS


EVENT_SOURCE = "uk.gov.justice.service.managed-file-transfer"


@dataclass(frozen=True)
class FileMoverEvent:
    event_id: str
    file_id: str
    correlation_id: str
    source_bucket: str
    source_key: str
    source_version_id: str
    source_size_bytes: int
    scan_result_status: str = None
    scan_result_status_matches_tag: bool = None


def parse_file_mover_event(event, operation, account_id, expected_bucket):
    expected_detail_type = {
        "STAGE": "FileReceived.v1",
        "ROUTE": "FileScanResultRecorded.v1",
    }[operation]
    if event.get("source") != EVENT_SOURCE:
        raise ValueError(f"Event source must be {EVENT_SOURCE}")
    if event.get("detail-type") != expected_detail_type:
        raise ValueError(f"Event detail-type must be {expected_detail_type}")
    if event.get("account") != account_id:
        raise ValueError("Event account does not match the configured account")

    detail = _required(event.get("detail"), "detail")
    metadata = _required(detail.get("metadata"), "detail.metadata")
    data = _required(detail.get("data"), "detail.data")
    source_object = _required(data.get("object"), "detail.data.object")
    source_bucket = _required(source_object.get("bucket"), "detail.data.object.bucket")
    if source_bucket != expected_bucket:
        raise ValueError("Event object bucket does not match the configured source bucket")

    source_size_bytes = _required(
        source_object.get("sizeBytes"), "detail.data.object.sizeBytes"
    )
    if (
        isinstance(source_size_bytes, bool)
        or not isinstance(source_size_bytes, int)
        or source_size_bytes < 0
    ):
        raise ValueError("detail.data.object.sizeBytes must be a non-negative integer")

    parsed = FileMoverEvent(
        event_id=_required(event.get("id"), "id"),
        file_id=_required(data.get("fileId"), "detail.data.fileId"),
        correlation_id=_required(
            metadata.get("correlationId"), "detail.metadata.correlationId"
        ),
        source_bucket=source_bucket,
        source_key=_required(source_object.get("key"), "detail.data.object.key"),
        source_version_id=_required(
            source_object.get("versionId"), "detail.data.object.versionId"
        ),
        source_size_bytes=source_size_bytes,
        scan_result_status=data.get("scanResultStatus"),
        scan_result_status_matches_tag=data.get("scanResultStatusMatchesTag"),
    )
    if operation == "ROUTE":
        if parsed.scan_result_status not in SUPPORTED_SCAN_RESULTS:
            raise ValueError("Event contains an unsupported scan result status")
        if not isinstance(parsed.scan_result_status_matches_tag, bool):
            raise ValueError("scanResultStatusMatchesTag must be a boolean")
    return parsed


def _required(value, field_name):
    if value is None or value == "":
        raise ValueError(f"Missing required field: {field_name}")
    return value