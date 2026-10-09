"""Retain an immutable clean version before notifying. Never issue download URLs."""
RETENTION_SECONDS = 7 * 86400
PART_SIZE = 512 * 1024 * 1024


def destination_key(pickup_id, data, route):
    # One isolated directory per recipient and execution; never overwrite another
    # transfer with the same original filename. Strip control characters in labels.
    filename = data["object"]["key"].rsplit("/", 1)[-1]
    filename = "".join(c for c in filename if ord(c) >= 32 and ord(c) != 127)
    if filename in ("", ".", ".."):
        filename = "download"
    prefix = f"{route['recipient_id']}/{pickup_id}/"
    budget = 1024 - len(prefix.encode("utf-8"))
    if budget <= 0:
        raise ValueError("Pickup prefix exceeds S3 key limit")
    filename = filename.encode("utf-8")[:budget].decode("utf-8", errors="ignore")
    if not filename:
        raise ValueError("No space for pickup filename")
    return prefix + filename


class Retainer:
    def __init__(self, s3, table, bucket, kms_key, remaining_ms=lambda: 900000):
        self.s3, self.table, self.bucket, self.kms_key = s3, table, bucket, kms_key
        self.remaining_ms = remaining_ms

    def prepare(self, pickup_id, data, route, now):
        version = data["object"].get("versionId")
        if not isinstance(version, str) or version in ("", "null"):
            raise ValueError("An immutable clean version is required")
        key = destination_key(pickup_id, data, route)
        receipt_key = {"id": "pickup:" + pickup_id}
        previous = self.table.get_item(Key=receipt_key, ConsistentRead=True).get("Item")
        if previous:
            # Notification retries keep the same version and collection deadline.
            if (previous["recipientId"] != route["recipient_id"] or previous["source"] != data["object"]
                    or previous["bucket"] != self.bucket or previous["key"] != key):
                raise ValueError("Receipt binding mismatch")
            if previous["collectUntil"] <= now:
                raise ValueError("Pickup expired")
            return previous
        obj = data["object"]
        source = {"Bucket": obj["bucket"], "Key": obj["key"], "VersionId": obj["versionId"]}
        size = self.s3.head_object(**source)["ContentLength"]
        if size != obj["sizeBytes"]:
            raise ValueError("Source size mismatch")
        dest = {"Bucket": self.bucket, "Key": key,
                "ServerSideEncryption": "aws:kms", "SSEKMSKeyId": self.kms_key,
                "ContentType": "application/octet-stream", "ContentDisposition": "attachment"}
        if size <= 5 * 1000**3:
            response = self.s3.copy_object(**dest, CopySource=source, MetadataDirective="REPLACE",
                                           TaggingDirective="REPLACE")
        else:
            if (size + PART_SIZE - 1) // PART_SIZE > 10000:
                raise ValueError("Object exceeds multipart limit")
            upload = self.s3.create_multipart_upload(**dest)["UploadId"]
            target = {"Bucket": self.bucket, "Key": key, "UploadId": upload}
            try:
                parts = []
                for start in range(0, size, PART_SIZE):
                    if self.remaining_ms() < 60000:
                        raise TimeoutError("Insufficient time for another copy part")
                    number = len(parts) + 1
                    part = self.s3.upload_part_copy(**target, PartNumber=number, CopySource=source,
                        CopySourceRange=f"bytes={start}-{min(start + PART_SIZE, size) - 1}")
                    parts.append({"PartNumber": number, "ETag": part["CopyPartResult"]["ETag"]})
                response = self.s3.complete_multipart_upload(**target, MultipartUpload={"Parts": parts})
            except Exception:
                self.s3.abort_multipart_upload(**target)
                raise
        version = response.get("VersionId")
        if not version or version == "null":
            raise ValueError("Pickup bucket must have versioning enabled")
        # Start at the copy attempt, not Slack delivery; retries cannot extend retention.
        receipt = {**receipt_key, "recipientId": route["recipient_id"], "source": obj,
                   "bucket": self.bucket, "key": key, "versionId": version,
                   "collectUntil": now + RETENTION_SECONDS, "expiresAt": now + 14 * 86400}
        self.table.put_item(Item=receipt, ConditionExpression="attribute_not_exists(id)")
        return receipt
