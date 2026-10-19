import unittest
from unittest.mock import Mock
from retention import Retainer, PART_SIZE, RETENTION_SECONDS, destination_key


class RetentionTests(unittest.TestCase):
    def setUp(self):
        self.s3 = Mock()
        self.table = Mock()
        self.table.get_item.return_value = {}
        self.s3.head_object.return_value = {"ContentLength": 5}
        self.s3.copy_object.return_value = {"VersionId": "retained-v1"}
        self.retainer = Retainer(self.s3, self.table, "pickup", "kms")
        self.data = {"object": {"bucket": "clean", "key": "team/file.txt", "versionId": "clean-v1", "sizeBytes": 5}}
        self.route = {"recipient_id": "team"}

    def test_copies_exact_version_and_saves_fixed_deadline(self):
        item = self.retainer.prepare("id", self.data, self.route, 100)
        self.assertEqual(item["versionId"], "retained-v1")
        self.assertEqual(item["collectUntil"], 100 + RETENTION_SECONDS)
        args = self.s3.copy_object.call_args.kwargs
        self.assertEqual(args["CopySource"]["VersionId"], "clean-v1")
        self.assertEqual(args["MetadataDirective"], "REPLACE")
        self.assertEqual(args["TaggingDirective"], "REPLACE")
        self.assertNotIn("Tagging", args)
        self.assertEqual(args["ContentDisposition"], "attachment")

    def test_retry_reuses_receipt_without_copy_or_retention_extension(self):
        first = self.retainer.prepare("id", self.data, self.route, 100)
        self.s3.reset_mock()
        self.table.get_item.return_value = {"Item": first}
        second = self.retainer.prepare("id", self.data, self.route, 200)
        self.assertEqual(first, second)
        self.s3.copy_object.assert_not_called()

    def test_expired_or_wrong_recipient_receipt_fails_closed(self):
        first = self.retainer.prepare("id", self.data, self.route, 100)
        self.table.get_item.return_value = {"Item": first}
        with self.assertRaises(ValueError): self.retainer.prepare("id", self.data, self.route, first["collectUntil"])
        with self.assertRaises(ValueError): self.retainer.prepare("id", self.data, {"recipient_id": "other"}, 200)

    def test_size_mismatch_and_missing_version_fail(self):
        self.s3.head_object.return_value = {"ContentLength": 6}
        with self.assertRaises(ValueError): self.retainer.prepare("id", self.data, self.route, 100)
        self.s3.head_object.return_value = {"ContentLength": 5}
        self.s3.copy_object.return_value = {}
        with self.assertRaises(ValueError): self.retainer.prepare("id", self.data, self.route, 100)
        self.table.put_item.assert_not_called()

    def prepare_large(self):
        size = 6 * 1024**3 + 1
        self.data["object"]["sizeBytes"] = size
        self.s3.head_object.return_value = {"ContentLength": size}
        self.s3.create_multipart_upload.return_value = {"UploadId": "upload"}
        self.s3.upload_part_copy.return_value = {"CopyPartResult": {"ETag": "etag"}}
        self.s3.complete_multipart_upload.return_value = {"VersionId": "large-v1"}
        return size

    def test_large_copy_uses_ranges_and_exact_source_version(self):
        size = self.prepare_large()
        result = self.retainer.prepare("id", self.data, self.route, 100)
        calls = self.s3.upload_part_copy.call_args_list
        self.assertEqual(len(calls), 13)
        self.assertEqual(calls[0].kwargs["CopySourceRange"], f"bytes=0-{PART_SIZE-1}")
        self.assertEqual(calls[-1].kwargs["CopySourceRange"], f"bytes={size-1}-{size-1}")
        self.assertTrue(all(call.kwargs["CopySource"]["VersionId"] == "clean-v1" for call in calls))
        self.assertEqual(result["versionId"], "large-v1")

    def test_failed_or_timed_out_multipart_aborts_without_receipt(self):
        self.prepare_large()
        self.retainer.remaining_ms = lambda: 50000
        with self.assertRaises(TimeoutError): self.retainer.prepare("id", self.data, self.route, 100)
        self.s3.abort_multipart_upload.assert_called_once()
        self.s3.complete_multipart_upload.assert_not_called()
        self.table.put_item.assert_not_called()

    def test_recipient_directories_isolate_same_filename(self):
        first = destination_key("execution", self.data, {"recipient_id": "one"})
        second = destination_key("execution", self.data, {"recipient_id": "two"})
        self.assertEqual(first, "one/execution/file.txt")
        self.assertEqual(second, "two/execution/file.txt")
        self.assertNotEqual(first, second)

    def test_separate_transfers_never_overwrite_same_filename(self):
        self.assertNotEqual(destination_key("first", self.data, self.route),
                            destination_key("second", self.data, self.route))

    def test_legacy_unscoped_receipt_cannot_be_announced(self):
        first = self.retainer.prepare("id", self.data, self.route, 100)
        first["key"] = "id"
        self.table.get_item.return_value = {"Item": first}
        with self.assertRaises(ValueError): self.retainer.prepare("id", self.data, self.route, 200)

    def test_dot_names_and_control_characters_are_safe_labels(self):
        for name in (".", "..", ""):
            self.data["object"]["key"] = "team/" + name
            self.assertEqual(destination_key("id", self.data, self.route), "team/id/download")
        self.data["object"]["key"] = "team/test\r\n.txt"
        self.assertEqual(destination_key("id", self.data, self.route), "team/id/test.txt")

    def test_null_source_version_never_reaches_s3(self):
        self.data["object"]["versionId"] = "null"
        with self.assertRaises(ValueError): self.retainer.prepare("id", self.data, self.route, 100)
        self.s3.head_object.assert_not_called()
        self.s3.copy_object.assert_not_called()

    def test_long_ascii_and_unicode_filenames_fit_s3_byte_limit(self):
        for filename in ("a" * 1019, "文" * 339):
            self.data["object"]["key"] = "team/" + filename
            key = destination_key("a" * 64, self.data, self.route)
            self.assertLessEqual(len(key.encode("utf-8")), 1024)
            self.assertTrue(key.startswith("team/" + "a" * 64 + "/"))
            self.assertEqual(key.encode("utf-8").decode("utf-8"), key)
