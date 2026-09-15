import hashlib
from concurrent.futures import ThreadPoolExecutor, as_completed
from dataclasses import dataclass
from urllib.parse import urlencode

from mft_file_mover.model import (
    S3_MAXIMUM_PARTS,
    S3_MAXIMUM_PART_SIZE_BYTES,
    S3_MINIMUM_PART_SIZE_BYTES,
    plan_multipart_copy,
)


CONTENT_HEADERS = {
    "CacheControl": "CacheControl",
    "ContentDisposition": "ContentDisposition",
    "ContentEncoding": "ContentEncoding",
    "ContentLanguage": "ContentLanguage",
    "ContentType": "ContentType",
    "Expires": "Expires",
    "WebsiteRedirectLocation": "WebsiteRedirectLocation",
}
CHECKSUM_FIELDS = ["ChecksumCRC32", "ChecksumCRC32C", "ChecksumSHA1", "ChecksumSHA256"]
RESERVED_METADATA = {
    "mft-correlation-id",
    "mft-receipt-token",
    "mft-route-copy-token",
    "mft-source-version-id",
    "mft-stage-copy-token",
}


@dataclass(frozen=True)
class SourceSnapshot:
    size_bytes: int
    metadata: dict
    tags: list
    headers: dict
    checksums: dict


class S3CopyEngine:
    def __init__(self, client, account_id, part_size_bytes, maximum_parts, workers):
        if not S3_MINIMUM_PART_SIZE_BYTES <= part_size_bytes <= S3_MAXIMUM_PART_SIZE_BYTES:
            raise ValueError("Multipart part size must be between 5 MiB and 5 GiB")
        if not 1 <= maximum_parts <= S3_MAXIMUM_PARTS:
            raise ValueError(f"Multipart maximum parts must be between 1 and {S3_MAXIMUM_PARTS}")
        if not 1 <= workers <= 32:
            raise ValueError("Multipart workers must be between 1 and 32")
        self.client = client
        self.account_id = account_id
        self.part_size_bytes = part_size_bytes
        self.maximum_parts = maximum_parts
        self.workers = workers

    def inspect_source(self, operation_event, operation):
        response = self.client.head_object(
            Bucket=operation_event.source_bucket,
            Key=operation_event.source_key,
            VersionId=operation_event.source_version_id,
            ExpectedBucketOwner=self.account_id,
            ChecksumMode="ENABLED",
        )
        if response["ContentLength"] != operation_event.source_size_bytes:
            raise ValueError("Source object size does not match the canonical event")
        tag_response = self.client.get_object_tagging(
            Bucket=operation_event.source_bucket,
            Key=operation_event.source_key,
            VersionId=operation_event.source_version_id,
            ExpectedBucketOwner=self.account_id,
        )
        metadata = response.get("Metadata", {})
        if operation == "STAGE" and RESERVED_METADATA.intersection(metadata):
            raise ValueError("Incoming object contains reserved mover metadata")
        if operation == "ROUTE":
            if metadata.get("mft-correlation-id") != operation_event.correlation_id:
                raise ValueError("Processing object correlation metadata does not match the event")
            if "mft-route-copy-token" in metadata:
                raise ValueError("Processing object contains reserved ROUTE metadata")
        return SourceSnapshot(
            size_bytes=response["ContentLength"],
            metadata=metadata,
            tags=tag_response.get("TagSet", []),
            headers={
                destination_name: response[source_name]
                for source_name, destination_name in CONTENT_HEADERS.items()
                if source_name in response
            },
            checksums={
                field: response[field] for field in CHECKSUM_FIELDS if field in response
            },
        )

    @staticmethod
    def is_receipt(operation_event, snapshot):
        return operation_event.source_key.endswith(".receipt") and any(
            tag["Key"] == "Receipt" and tag["Value"] == "TRUE" for tag in snapshot.tags
        )

    @staticmethod
    def copy_token(operation_event, operation, destination_bucket):
        value = ":".join(
            [
                operation,
                operation_event.correlation_id,
                operation_event.source_bucket,
                operation_event.source_key,
                operation_event.source_version_id,
                destination_bucket,
            ]
        )
        return hashlib.sha256(value.encode("utf-8")).hexdigest()

    def copy(self, item, owner, store, snapshot, destination, token, operation):
        token_field = f"mft-{operation.lower()}-copy-token"
        metadata = {
            **snapshot.metadata,
            "mft-correlation-id": item["correlation_id"],
            token_field: token,
        }
        common = {
            "Bucket": destination.bucket,
            "Key": item["source_key"],
            "ExpectedBucketOwner": self.account_id,
            "ServerSideEncryption": "aws:kms",
            "SSEKMSKeyId": destination.kms_key_arn,
            "Metadata": metadata,
            "Tagging": urlencode([(tag["Key"], tag["Value"]) for tag in snapshot.tags]),
            **snapshot.headers,
        }

        if item["status"] in {
            "IN_PROGRESS",
            "MULTIPART_CREATED",
            "MULTIPART_ABORTED",
        }:
            reconciled = self.find_destination_version(
                destination.bucket, item["source_key"], token_field, token
            )
            if reconciled:
                return store.transition(
                    item,
                    owner,
                    [item["status"]],
                    "COPIED",
                    self._destination_fields(destination.bucket, reconciled, token),
                    remove=["multipart_upload_id"],
                )

        if snapshot.size_bytes == 0 and item["status"] == "IN_PROGRESS":
            response = self.client.copy_object(
                **common,
                CopySource={
                    "Bucket": item["source_bucket"],
                    "Key": item["source_key"],
                    "VersionId": item["source_version_id"],
                },
                ExpectedSourceBucketOwner=self.account_id,
                MetadataDirective="REPLACE",
                TaggingDirective="REPLACE",
            )
            return self._checkpoint_completed_copy(
                item,
                owner,
                store,
                destination.bucket,
                token_field,
                token,
                response.get("VersionId"),
            )

        parts = plan_multipart_copy(
            snapshot.size_bytes, self.part_size_bytes, self.maximum_parts
        )
        if item["status"] in {"IN_PROGRESS", "MULTIPART_ABORTED"}:
            response = self.client.create_multipart_upload(**common)
            upload_id = response["UploadId"]
            try:
                item = store.transition(
                    item,
                    owner,
                    [item["status"]],
                    "MULTIPART_CREATED",
                    {
                        "multipart_upload_id": upload_id,
                        "multipart_part_size_bytes": self.part_size_bytes,
                        "multipart_part_count": len(parts),
                    },
                )
            except Exception:
                self._abort(destination.bucket, item["source_key"], upload_id)
                raise

        if item["status"] != "MULTIPART_CREATED":
            return item

        upload_id = item["multipart_upload_id"]
        if (
            item["multipart_part_size_bytes"] != self.part_size_bytes
            or item["multipart_part_count"] != len(parts)
        ):
            raise RuntimeError("Stored multipart geometry does not match the current configuration")
        try:
            completed_parts = self._existing_parts(
                destination.bucket, item["source_key"], upload_id, parts
            )
            missing_parts = [part for part in parts if part.part_number not in completed_parts]
            with ThreadPoolExecutor(max_workers=self.workers) as executor:
                futures = {
                    executor.submit(
                        self._copy_part,
                        item,
                        destination.bucket,
                        upload_id,
                        part,
                    ): part.part_number
                    for part in missing_parts
                }
                for future in as_completed(futures):
                    part_number, etag = future.result()
                    completed_parts[part_number] = etag
        except Exception:
            self._abort(destination.bucket, item["source_key"], upload_id)
            store.transition(
                item,
                owner,
                ["MULTIPART_CREATED"],
                "MULTIPART_ABORTED",
                remove=["multipart_upload_id"],
            )
            raise

        response = self.client.complete_multipart_upload(
            Bucket=destination.bucket,
            Key=item["source_key"],
            UploadId=upload_id,
            MultipartUpload={
                "Parts": [
                    {"PartNumber": part_number, "ETag": completed_parts[part_number]}
                    for part_number in sorted(completed_parts)
                ]
            },
            ExpectedBucketOwner=self.account_id,
        )

        return self._checkpoint_completed_copy(
            item,
            owner,
            store,
            destination.bucket,
            token_field,
            token,
            response.get("VersionId"),
        )

    def verify(self, item, snapshot, destination, operation):
        response = self.client.head_object(
            Bucket=destination.bucket,
            Key=item["source_key"],
            VersionId=item["destination_version_id"],
            ExpectedBucketOwner=self.account_id,
            ChecksumMode="ENABLED",
        )
        expected_metadata = {
            **snapshot.metadata,
            "mft-correlation-id": item["correlation_id"],
            f"mft-{operation.lower()}-copy-token": item["copy_token"],
        }
        mismatches = []
        if response.get("ContentLength") != snapshot.size_bytes:
            mismatches.append("size")
        if response.get("Metadata", {}) != expected_metadata:
            mismatches.append("metadata")
        if response.get("ServerSideEncryption") != "aws:kms":
            mismatches.append("server-side encryption")
        if response.get("SSEKMSKeyId") != destination.kms_key_arn:
            mismatches.append("KMS key")
        for name in CONTENT_HEADERS.values():
            if response.get(name) != snapshot.headers.get(name):
                mismatches.append(name)
        if snapshot.size_bytes == 0:
            for name, value in snapshot.checksums.items():
                if name in response and response[name] != value:
                    mismatches.append(name)
        tags = self.client.get_object_tagging(
            Bucket=destination.bucket,
            Key=item["source_key"],
            VersionId=item["destination_version_id"],
            ExpectedBucketOwner=self.account_id,
        ).get("TagSet", [])
        if _normalise_tags(tags) != _normalise_tags(snapshot.tags):
            mismatches.append("tags")
        if mismatches:
            raise RuntimeError(
                f"Destination verification failed for: {', '.join(sorted(set(mismatches)))}"
            )

    def delete_source(self, item):
        self.client.delete_object(
            Bucket=item["source_bucket"],
            Key=item["source_key"],
            VersionId=item["source_version_id"],
            ExpectedBucketOwner=self.account_id,
        )

    def create_receipt(self, item, kms_key_arn):
        key = f"{item['source_key']}.receipt"
        token = hashlib.sha256(
            f"RECEIPT:{item['correlation_id']}:{item['source_version_id']}".encode(
                "utf-8"
            )
        ).hexdigest()
        existing = self.find_destination_version(
            item["source_bucket"], key, "mft-receipt-token", token
        )
        if existing:
            return key, existing, token
        response = self.client.put_object(
            Bucket=item["source_bucket"],
            Key=key,
            Body=b"",
            ExpectedBucketOwner=self.account_id,
            ServerSideEncryption="aws:kms",
            SSEKMSKeyId=kms_key_arn,
            Metadata={
                "mft-correlation-id": item["correlation_id"],
                "mft-source-version-id": item["source_version_id"],
                "mft-receipt-token": token,
            },
            Tagging="Receipt=TRUE",
            ContentType="application/octet-stream",
        )
        version_id = response.get("VersionId") or self.find_destination_version(
            item["source_bucket"], key, "mft-receipt-token", token
        )
        if not version_id:
            raise RuntimeError("S3 did not return a receipt version ID")
        return key, version_id, token

    def find_destination_version(self, bucket, key, token_field, token):
        matches = []
        paginator = self.client.get_paginator("list_object_versions")
        for page in paginator.paginate(Bucket=bucket, Prefix=key, ExpectedBucketOwner=self.account_id):
            for version in page.get("Versions", []):
                if version["Key"] != key:
                    continue
                response = self.client.head_object(
                    Bucket=bucket,
                    Key=key,
                    VersionId=version["VersionId"],
                    ExpectedBucketOwner=self.account_id,
                )
                if response.get("Metadata", {}).get(token_field) == token:
                    matches.append(version["VersionId"])
        if len(matches) > 1:
            raise RuntimeError("Multiple destination versions match the deterministic copy token")
        return matches[0] if matches else None

    def _checkpoint_completed_copy(
        self, item, owner, store, destination_bucket, token_field, token, version_id
    ):
        if not version_id:
            version_id = self.find_destination_version(
                destination_bucket, item["source_key"], token_field, token
            )
        if not version_id:
            raise RuntimeError("S3 did not return a destination version ID")
        return store.transition(
            item,
            owner,
            [item["status"]],
            "COPIED",
            self._destination_fields(destination_bucket, version_id, token),
            remove=["multipart_upload_id"],
        )

    def _existing_parts(self, bucket, key, upload_id, planned_parts):
        completed = {}
        expected_sizes = {part.part_number: part.size for part in planned_parts}
        paginator = self.client.get_paginator("list_parts")
        for page in paginator.paginate(
            Bucket=bucket,
            Key=key,
            UploadId=upload_id,
            ExpectedBucketOwner=self.account_id,
        ):
            for part in page.get("Parts", []):
                if expected_sizes.get(part["PartNumber"]) != part["Size"]:
                    raise RuntimeError("Existing multipart part does not match the copy plan")
                completed[part["PartNumber"]] = part["ETag"]
        return completed

    def _copy_part(self, item, destination_bucket, upload_id, part):
        response = self.client.upload_part_copy(
            Bucket=destination_bucket,
            Key=item["source_key"],
            UploadId=upload_id,
            PartNumber=part.part_number,
            CopySource={
                "Bucket": item["source_bucket"],
                "Key": item["source_key"],
                "VersionId": item["source_version_id"],
            },
            CopySourceRange=f"bytes={part.range_start}-{part.range_end}",
            ExpectedBucketOwner=self.account_id,
            ExpectedSourceBucketOwner=self.account_id,
        )
        return part.part_number, response["CopyPartResult"]["ETag"]

    def _abort(self, bucket, key, upload_id):
        try:
            self.client.abort_multipart_upload(
                Bucket=bucket,
                Key=key,
                UploadId=upload_id,
                ExpectedBucketOwner=self.account_id,
            )
        except Exception as error:
            code = getattr(error, "response", {}).get("Error", {}).get("Code")
            if code != "NoSuchUpload":
                raise

    @staticmethod
    def _destination_fields(bucket, version_id, token):
        return {
            "destination_bucket": bucket,
            "destination_version_id": version_id,
            "copy_token": token,
        }


def _normalise_tags(tags):
    return sorted((tag["Key"], tag["Value"]) for tag in tags)