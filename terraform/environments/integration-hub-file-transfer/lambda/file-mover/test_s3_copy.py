import unittest
from types import SimpleNamespace
from unittest.mock import MagicMock

from mft_file_mover.config import Destination
from mft_file_mover.s3_copy import S3CopyEngine, SourceSnapshot


class NoSuchUpload(Exception):
    response = {"Error": {"Code": "NoSuchUpload"}}


class S3CopyEngineTest(unittest.TestCase):
    def setUp(self):
        self.s3 = MagicMock()
        self.part_size_bytes = 5 * 1024**2
        self.engine = S3CopyEngine(
            self.s3, "123456789012", self.part_size_bytes, 1000, 2
        )
        self.destination = Destination("processing", "kms-key-arn")
        self.store = MagicMock()
        self.item = {
            "concurrencyId": "correlation-id",
            "operation": "STAGE",
            "status": "IN_PROGRESS",
            "correlation_id": "correlation-id",
            "source_bucket": "incoming",
            "source_key": "report.csv",
            "source_version_id": "source-version",
        }
        self.snapshot = SourceSnapshot(
            size_bytes=0,
            metadata={"business": "value"},
            tags=[{"Key": "Classification", "Value": "OFFICIAL"}],
            headers={"ContentType": "text/csv"},
            checksums={"ChecksumSHA256": "checksum"},
        )
        self.store.transition.return_value = {**self.item, "status": "COPIED"}
        paginator = MagicMock()
        paginator.paginate.return_value = []
        self.s3.get_paginator.return_value = paginator

    def test_zero_byte_copy_preserves_exact_source_version_and_attributes(self):
        self.s3.copy_object.return_value = {"VersionId": "destination-version"}

        self.engine.copy(
            self.item,
            "request-id",
            self.store,
            self.snapshot,
            self.destination,
            "copy-token",
            "STAGE",
        )

        arguments = self.s3.copy_object.call_args.kwargs
        self.assertEqual(arguments["CopySource"]["VersionId"], "source-version")
        self.assertEqual(arguments["ExpectedSourceBucketOwner"], "123456789012")
        self.assertEqual(arguments["SSEKMSKeyId"], "kms-key-arn")
        self.assertEqual(arguments["Metadata"]["business"], "value")
        self.assertEqual(arguments["Metadata"]["mft-stage-copy-token"], "copy-token")
        self.assertEqual(arguments["ContentType"], "text/csv")

    def test_positive_size_copy_uses_multipart_even_when_smaller_than_a_part(self):
        snapshot = SourceSnapshot(1, {}, [], {}, {})
        self.s3.create_multipart_upload.return_value = {"UploadId": "upload-id"}
        self.s3.complete_multipart_upload.return_value = {
            "VersionId": "destination-version"
        }
        self.s3.upload_part_copy.return_value = {
            "CopyPartResult": {"ETag": "part-etag"}
        }
        multipart_item = {
            **self.item,
            "status": "MULTIPART_CREATED",
            "multipart_upload_id": "upload-id",
            "multipart_part_size_bytes": self.part_size_bytes,
            "multipart_part_count": 1,
        }
        copied_item = {**multipart_item, "status": "COPIED"}
        self.store.transition.side_effect = [multipart_item, copied_item]

        self.engine.copy(
            self.item,
            "request-id",
            self.store,
            snapshot,
            self.destination,
            "copy-token",
            "STAGE",
        )

        self.s3.copy_object.assert_not_called()
        self.s3.upload_part_copy.assert_called_once()
        self.assertEqual(
            self.s3.upload_part_copy.call_args.kwargs["CopySourceRange"], "bytes=0-0"
        )

    def test_reconciles_a_completed_multipart_upload_before_listing_parts(self):
        item = {
            **self.item,
            "status": "MULTIPART_CREATED",
            "multipart_upload_id": "completed-upload-id",
            "multipart_part_size_bytes": self.part_size_bytes,
            "multipart_part_count": 1,
        }
        snapshot = SourceSnapshot(1, {}, [], {}, {})
        self.engine.find_destination_version = MagicMock(
            return_value="destination-version"
        )

        self.engine.copy(
            item,
            "request-id",
            self.store,
            snapshot,
            self.destination,
            "copy-token",
            "STAGE",
        )

        self.s3.get_paginator.assert_not_called()
        self.store.transition.assert_called_once()
        self.assertEqual(self.store.transition.call_args.args[3], "COPIED")

    def test_ambiguous_completion_retains_the_multipart_checkpoint(self):
        snapshot = SourceSnapshot(1, {}, [], {}, {})
        item = {
            **self.item,
            "status": "MULTIPART_CREATED",
            "multipart_upload_id": "upload-id",
            "multipart_part_size_bytes": self.part_size_bytes,
            "multipart_part_count": 1,
        }
        self.s3.upload_part_copy.return_value = {
            "CopyPartResult": {"ETag": "part-etag"}
        }
        self.s3.complete_multipart_upload.side_effect = TimeoutError("response lost")

        with self.assertRaises(TimeoutError):
            self.engine.copy(
                item,
                "request-id",
                self.store,
                snapshot,
                self.destination,
                "copy-token",
                "STAGE",
            )

        self.s3.abort_multipart_upload.assert_not_called()
        self.store.transition.assert_not_called()

    def test_missing_upload_is_checkpointed_as_aborted_after_part_failure(self):
        snapshot = SourceSnapshot(1, {}, [], {}, {})
        item = {
            **self.item,
            "status": "MULTIPART_CREATED",
            "multipart_upload_id": "upload-id",
            "multipart_part_size_bytes": self.part_size_bytes,
            "multipart_part_count": 1,
        }
        self.s3.upload_part_copy.side_effect = RuntimeError("part copy failed")
        self.s3.abort_multipart_upload.side_effect = NoSuchUpload()

        with self.assertRaisesRegex(RuntimeError, "part copy failed"):
            self.engine.copy(
                item,
                "request-id",
                self.store,
                snapshot,
                self.destination,
                "copy-token",
                "STAGE",
            )

        self.store.transition.assert_called_once()
        self.assertEqual(self.store.transition.call_args.args[3], "MULTIPART_ABORTED")

    def test_verification_failure_prevents_exact_source_deletion(self):
        copied = {
            **self.item,
            "destination_version_id": "destination-version",
            "copy_token": "copy-token",
        }
        self.s3.head_object.return_value = {
            "ContentLength": 0,
            "Metadata": {},
            "ServerSideEncryption": "aws:kms",
            "SSEKMSKeyId": "kms-key-arn",
            "ContentType": "text/csv",
        }
        self.s3.get_object_tagging.return_value = {"TagSet": self.snapshot.tags}

        with self.assertRaisesRegex(RuntimeError, "metadata"):
            self.engine.verify(copied, self.snapshot, self.destination, "STAGE")

        self.s3.delete_object.assert_not_called()

    def test_deletes_only_the_exact_source_version(self):
        self.engine.delete_source(self.item)

        self.s3.delete_object.assert_called_once_with(
            Bucket="incoming",
            Key="report.csv",
            VersionId="source-version",
            ExpectedBucketOwner="123456789012",
        )

    def test_receipt_requires_both_the_suffix_and_exact_tag(self):
        receipt_event = SimpleNamespace(source_key="report.csv.receipt")
        receipt_snapshot = SourceSnapshot(
            0, {}, [{"Key": "Receipt", "Value": "TRUE"}], {}, {}
        )

        self.assertTrue(self.engine.is_receipt(receipt_event, receipt_snapshot))
        self.assertFalse(
            self.engine.is_receipt(
                SimpleNamespace(source_key="report.csv"), receipt_snapshot
            )
        )
        self.assertFalse(
            self.engine.is_receipt(
                receipt_event,
                SourceSnapshot(0, {}, [{"Key": "Receipt", "Value": "FALSE"}], {}, {}),
            )
        )

    def test_ordinary_zero_byte_business_object_is_not_a_receipt(self):
        self.assertFalse(
            self.engine.is_receipt(
                SimpleNamespace(source_key="empty.csv"),
                SourceSnapshot(0, {}, [], {}, {}),
            )
        )


if __name__ == "__main__":
    unittest.main()