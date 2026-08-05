import unittest

from mft_file_mover.events import parse_file_mover_event


class FileMoverEventTest(unittest.TestCase):
    def setUp(self):
        self.event = {
            "id": "event-id",
            "account": "123456789012",
            "source": "uk.gov.justice.service.managed-file-transfer",
            "detail-type": "FileReceived.v1",
            "detail": {
                "metadata": {"correlationId": "correlation-id"},
                "data": {
                    "fileId": "file-id",
                    "object": {
                        "bucket": "incoming",
                        "key": "example/report.csv",
                        "versionId": "source-version",
                        "sizeBytes": 1,
                    },
                },
            },
        }

    def test_parses_a_stage_event(self):
        parsed = parse_file_mover_event(
            self.event, "STAGE", "123456789012", "incoming"
        )

        self.assertEqual(parsed.source_version_id, "source-version")
        self.assertEqual(parsed.source_size_bytes, 1)

    def test_rejects_a_boolean_object_size(self):
        self.event["detail"]["data"]["object"]["sizeBytes"] = True

        with self.assertRaisesRegex(ValueError, "non-negative integer"):
            parse_file_mover_event(self.event, "STAGE", "123456789012", "incoming")

    def test_route_requires_a_supported_result_and_tag_match(self):
        self.event["detail-type"] = "FileScanResultRecorded.v1"
        self.event["detail"]["data"].update(
            {
                "scanResultStatus": "NO_THREATS_FOUND",
                "scanResultStatusMatchesTag": True,
            }
        )

        parsed = parse_file_mover_event(
            self.event, "ROUTE", "123456789012", "incoming"
        )

        self.assertEqual(parsed.scan_result_status, "NO_THREATS_FOUND")


if __name__ == "__main__":
    unittest.main()