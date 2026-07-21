import importlib
import json
import os
import sys
import unittest
from datetime import datetime, timezone
from types import SimpleNamespace
from unittest.mock import MagicMock, patch


PROCESSING_BUCKET = "integration-hub-file-transfer-development-processing"
IDEMPOTENCY_CACHE = {}


class FakeLogger:
    def __init__(self, **_kwargs):
        pass

    def info(self, *_args, **_kwargs):
        return None

    def inject_lambda_context(self, **_kwargs):
        return lambda function: function


class FakeIdempotencyConfig:
    def __init__(self, **kwargs):
        self.options = kwargs


def fake_idempotent(**_kwargs):
    def decorator(function):
        def wrapped(event, context):
            event_id = event.get("id")
            if event_id in IDEMPOTENCY_CACHE:
                return IDEMPOTENCY_CACHE[event_id]

            result = function(event, context)
            IDEMPOTENCY_CACHE[event_id] = result
            return result

        return wrapped

    return decorator


class FileScanResultRecordedAdapterTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.events_client = MagicMock()
        cls.dynamodb_client = MagicMock()
        cls.s3_client = MagicMock()
        boto3 = MagicMock()
        boto3.client.side_effect = lambda name: {
            "events": cls.events_client,
            "dynamodb": cls.dynamodb_client,
            "s3": cls.s3_client,
        }[name]
        cls.modules_patch = patch.dict(
            sys.modules,
            {
                "boto3": boto3,
                "aws_lambda_powertools": SimpleNamespace(Logger=FakeLogger),
                "aws_lambda_powertools.utilities.idempotency": SimpleNamespace(
                    DynamoDBPersistenceLayer=lambda **_kwargs: SimpleNamespace(),
                    IdempotencyConfig=FakeIdempotencyConfig,
                    idempotent=fake_idempotent,
                ),
            },
        )
        cls.modules_patch.start()
        os.environ.update(
            {
                "AWS_ACCOUNT_ID": "123456789012",
                "EVENT_BUS_ARN": "arn:aws:events:eu-west-2:123456789012:event-bus/file-transfer",
                "IDEMPOTENCY_EXPIRY_SECONDS": "2592000",
                "IDEMPOTENCY_TABLE": "adapter-idempotency",
                "WORKFLOW_IDEMPOTENCY_TABLE": "workflow-idempotency",
            }
        )
        cls.adapter = importlib.import_module("lambda_function")

    @classmethod
    def tearDownClass(cls):
        cls.modules_patch.stop()

    def setUp(self):
        IDEMPOTENCY_CACHE.clear()
        self.events_client.reset_mock()
        self.dynamodb_client.reset_mock()
        self.s3_client.reset_mock()
        self.events_client.put_events.return_value = {
            "FailedEntryCount": 0,
            "Entries": [{"EventId": "scan-result-event-id"}],
        }
        self.s3_client.head_object.return_value = {
            "ContentLength": 4096,
            "Metadata": {
                "mft-correlation-id": "7d9f4e4c-0e0f-4a5b-8b4e-4ab1f28fd1d1"
            },
        }
        self.s3_client.get_object_tagging.return_value = {
            "TagSet": [
                {
                    "Key": "GuardDutyMalwareScanStatus",
                    "Value": "NO_THREATS_FOUND",
                }
            ]
        }
        self.dynamodb_client.get_item.return_value = {
            "Item": {
                "status": {"S": "COMPLETED"},
                "file_id": {"S": "3f4e3d7a-4e2f-4bc2-9c4e-5f1ef2d4c501"},
                "correlation_id": {"S": "7d9f4e4c-0e0f-4a5b-8b4e-4ab1f28fd1d1"},
                "staged_event_id": {"S": "6dce6b40-6e43-49f0-a2cf-1da1d43bce22"},
                "processing_bucket": {"S": PROCESSING_BUCKET},
                "processing_key": {"S": "example/report.csv"},
                "processing_version_id": {"S": "4Mh..."},
                "incoming_size_bytes": {"N": "4096"},
            }
        }
        self.event = {
            "account": "123456789012",
            "id": "c5dc9cb4-3b1f-4f01-a4c6-41b30e11d790",
            "source": "aws.guardduty",
            "detail-type": "GuardDuty Malware Protection Object Scan Result",
            "time": "2026-07-10T14:02:00Z",
            "resources": [
                "arn:aws:guardduty:eu-west-2:123456789012:malware-protection-plan/example"
            ],
            "detail": {
                "schemaVersion": "1.0",
                "scanStatus": "COMPLETED",
                "resourceType": "S3_OBJECT",
                "s3ObjectDetails": {
                    "bucketName": PROCESSING_BUCKET,
                    "objectKey": "example/report.csv",
                    "versionId": "4Mh...",
                },
                "scanResultDetails": {
                    "scanResultStatus": "NO_THREATS_FOUND",
                    "statusReasons": None,
                },
            },
        }

    def test_publishes_canonical_scan_result(self):
        result = self.adapter.lambda_handler(self.event, None)

        entry = self.events_client.put_events.call_args.kwargs["Entries"][0]
        detail = json.loads(entry["Detail"])
        self.s3_client.head_object.assert_called_once_with(
            Bucket=PROCESSING_BUCKET,
            Key="example/report.csv",
            VersionId="4Mh...",
            ExpectedBucketOwner="123456789012",
        )
        self.dynamodb_client.get_item.assert_called_once_with(
            TableName="workflow-idempotency",
            Key={
                "concurrencyId": {
                    "S": "7d9f4e4c-0e0f-4a5b-8b4e-4ab1f28fd1d1"
                },
                "operation": {"S": "STAGE"},
            },
            ConsistentRead=True,
        )
        self.assertEqual(entry["DetailType"], "FileScanResultRecorded.v1")
        self.assertEqual(
            detail["metadata"]["idempotencyKey"],
            "scan:7d9f4e4c-0e0f-4a5b-8b4e-4ab1f28fd1d1:4Mh...",
        )
        self.assertEqual(
            detail["metadata"]["causationId"], "6dce6b40-6e43-49f0-a2cf-1da1d43bce22"
        )
        self.assertEqual(detail["data"]["scanResultStatus"], "NO_THREATS_FOUND")
        self.assertEqual(detail["data"]["tagStatus"], "NO_THREATS_FOUND")
        self.assertEqual(detail["data"]["object"]["sizeBytes"], 4096)
        self.assertEqual(entry["Time"], datetime(2026, 7, 10, 14, 2, tzinfo=timezone.utc))
        self.assertEqual(result, {"eventId": "scan-result-event-id"})

    def test_publishes_all_terminal_guardduty_outcomes(self):
        for scan_status, result_status in [
            ("COMPLETED", "NO_THREATS_FOUND"),
            ("COMPLETED", "THREATS_FOUND"),
            ("SKIPPED", "UNSUPPORTED"),
            ("SKIPPED", "ACCESS_DENIED"),
            ("FAILED", "FAILED"),
        ]:
            self.event["detail"]["scanStatus"] = scan_status
            self.event["detail"]["scanResultDetails"]["scanResultStatus"] = result_status
            self.event["detail"]["scanResultDetails"]["statusReasons"] = (
                ["PASSWORD_PROTECTED"] if scan_status == "SKIPPED" else None
            )
            self.assertEqual(self.adapter.lambda_handler(self.event, None)["eventId"], "scan-result-event-id")
            IDEMPOTENCY_CACHE.clear()

        self.assertEqual(self.events_client.put_events.call_count, 5)

    def test_identical_guardduty_event_publishes_once(self):
        first_result = self.adapter.lambda_handler(self.event, None)
        second_result = self.adapter.lambda_handler(self.event, None)

        self.assertEqual(first_result, second_result)
        self.events_client.put_events.assert_called_once()

    def test_new_guardduty_event_id_republishes_the_canonical_idempotency_key(self):
        self.adapter.lambda_handler(self.event, None)
        first_detail = json.loads(
            self.events_client.put_events.call_args.kwargs["Entries"][0]["Detail"]
        )
        self.event["id"] = "another-guardduty-event-id"

        self.adapter.lambda_handler(self.event, None)
        second_detail = json.loads(
            self.events_client.put_events.call_args.kwargs["Entries"][0]["Detail"]
        )

        self.assertEqual(self.events_client.put_events.call_count, 2)
        self.assertEqual(
            first_detail["metadata"]["idempotencyKey"],
            second_detail["metadata"]["idempotencyKey"],
        )

    def test_rejects_pre_publication_workflow_record(self):
        self.dynamodb_client.get_item.return_value["Item"]["status"] = {"S": "SOURCE_DELETED"}

        with self.assertRaisesRegex(RuntimeError, "not completed"):
            self.adapter.lambda_handler(self.event, None)

    def test_publishes_skipped_status_reasons(self):
        self.event["detail"]["scanStatus"] = "SKIPPED"
        self.event["detail"]["scanResultDetails"] = {
            "scanResultStatus": "UNSUPPORTED",
            "statusReasons": ["PASSWORD_PROTECTED"],
        }

        self.adapter.lambda_handler(self.event, None)

        entry = self.events_client.put_events.call_args.kwargs["Entries"][0]
        self.assertEqual(
            json.loads(entry["Detail"])["data"]["statusReasons"],
            ["PASSWORD_PROTECTED"],
        )

    def test_publishes_mismatch_without_changing_scan_result_status(self):
        for tag_set in [
            [],
            [
                {
                    "Key": "GuardDutyMalwareScanStatus",
                    "Value": "THREATS_FOUND",
                }
            ],
        ]:
            with self.subTest(tag_set=tag_set):
                self.s3_client.get_object_tagging.return_value = {"TagSet": tag_set}
                self.adapter.lambda_handler(self.event, None)

                entry = self.events_client.put_events.call_args.kwargs["Entries"][0]
                data = json.loads(entry["Detail"])["data"]
                self.assertEqual(data["scanResultStatus"], "NO_THREATS_FOUND")
                self.assertEqual(data["tagStatus"], "MISMATCH")
                IDEMPOTENCY_CACHE.clear()

    def test_rejects_processing_object_without_correlation_metadata(self):
        self.s3_client.head_object.return_value["Metadata"] = {}

        with self.assertRaisesRegex(ValueError, "mft-correlation-id"):
            self.adapter.lambda_handler(self.event, None)

    def test_raises_when_put_events_reports_failure(self):
        self.events_client.put_events.return_value = {
            "FailedEntryCount": 1,
            "Entries": [{"ErrorCode": "InternalFailure"}],
        }

        with self.assertRaisesRegex(RuntimeError, "Failed to publish"):
            self.adapter.lambda_handler(self.event, None)


if __name__ == "__main__":
    unittest.main()
