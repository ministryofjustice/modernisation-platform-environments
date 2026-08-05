from dataclasses import dataclass


S3_MAXIMUM_OBJECT_SIZE_BYTES = 5 * 1024**4
S3_MAXIMUM_PARTS = 10_000
S3_MAXIMUM_PART_SIZE_BYTES = 5 * 1024**3
S3_MINIMUM_PART_SIZE_BYTES = 5 * 1024**2
SUPPORTED_SCAN_RESULTS = {
    "ACCESS_DENIED",
    "FAILED",
    "NO_THREATS_FOUND",
    "THREATS_FOUND",
    "UNSUPPORTED",
}


@dataclass(frozen=True)
class CopyPart:
    part_number: int
    range_start: int
    range_end: int

    @property
    def size(self):
        return self.range_end - self.range_start + 1


def plan_multipart_copy(size_bytes, part_size_bytes, maximum_parts):
    if size_bytes <= 0:
        raise ValueError("Multipart copy requires a positive object size")
    if part_size_bytes <= 0:
        raise ValueError("Multipart part size must be positive")
    if maximum_parts <= 0 or maximum_parts > S3_MAXIMUM_PARTS:
        raise ValueError(
            f"Multipart maximum parts must be between 1 and {S3_MAXIMUM_PARTS}"
        )
    if size_bytes > S3_MAXIMUM_OBJECT_SIZE_BYTES:
        raise ValueError("Object exceeds the S3 5 TiB object-size limit")

    part_count = (size_bytes + part_size_bytes - 1) // part_size_bytes
    if part_count > maximum_parts:
        raise ValueError(
            f"Object requires {part_count} parts, exceeding the configured "
            f"maximum of {maximum_parts}"
        )

    return [
        CopyPart(
            part_number=index + 1,
            range_start=index * part_size_bytes,
            range_end=min(((index + 1) * part_size_bytes) - 1, size_bytes - 1),
        )
        for index in range(part_count)
    ]


def select_route(scan_result_status, scan_result_status_matches_tag):
    if scan_result_status not in SUPPORTED_SCAN_RESULTS:
        raise ValueError(f"Unsupported scan result status: {scan_result_status}")
    if scan_result_status_matches_tag and scan_result_status == "NO_THREATS_FOUND":
        return "clean"
    if scan_result_status_matches_tag and scan_result_status == "THREATS_FOUND":
        return "quarantine"
    return "investigation"