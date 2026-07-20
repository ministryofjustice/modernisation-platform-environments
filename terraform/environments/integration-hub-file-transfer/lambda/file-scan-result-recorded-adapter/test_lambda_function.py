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
        def wrapped(operation):
            key = operation["idempotencyKey"]
            payload = (operation["object"], operation["scanResultStatus"])
            if key in IDEMPOTENCY_CACHE:
                if IDEMPOTENCY_CACHE[key]["payload"] != payload:
                    raise ValueError("Idempotency payload does not match the existing operation")
                return IDEMPOTENCY_CACHE[key]["result"]

            result = function(operation)
            IDEMPOTENCY_CACHE[key] = {"payload": payload, "result": result}
            return result

        return wrapped

    return decorator


class FileScanResultRecordedAdapterTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.events_client = MagicMock()
        cls.dynamodb_client = MagicMock()
        boto3 = MagicMock()
        boto3.client.side_effect = lambda name: {
            "events": cls.events_client,
            "dynamodb": cls.dynamodb_client,
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
                "MALWARE_PROTECTION_PLAN_ARN": "arn:aws:guardduty:eu-west-2:123456789012:malware-protection-plan/example",
                "PROCESSING_BUCKET_NAME": PROCESSING_BUCKET,
                "PROCESSING_OBJECT_LOOKUP_KEY_INDEX_NAME": "processing-object-lookup-key-index",
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
        self.events_client.put_events.return_value = {
            "FailedEntryCount": 0,
            "Entries": [{"EventId": "scan-result-event-id"}],
        }
        self.dynamodb_client.query.return_value = {
            "Items": [
                {
                    "status": {"S": "PUBLISHED"},
                    "file_id": {"S": "3f4e3d7a-4e2f-4bc2-9c4e-5f1ef2d4c501"},
                    "correlation_id": {"S": "7d9f4e4c-0e0f-4a5b-8b4e-4ab1f28fd1d1"},
                    "staged_event_id": {"S": "6dce6b40-6e43-49f0-a2cf-1da1d43bce22"},
                    "processing_bucket": {"S": PROCESSING_BUCKET},
                    "processing_key": {"S": "example/report.csv"},
                    "processing_version_id": {"S": "4Mh..."},
                    "incoming_size_bytes": {"N": "4096"},
                }
            ]
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
                "scanResultDetails": {"scanResultStatus": "NO_THREATS_FOUND"},
            },
        }

    def test_publishes_canonical_scan_result(self):
        result = self.adapter.lambda_handler(self.event, None)

        entry = self.events_client.put_events.call_args.kwargs["Entries"][0]
        detail = json.loads(entry["Detail"])
        self.assertEqual(self.dynamodb_client.query.call_args.kwargs["Limit"], 2)
        self.assertEqual(entry["DetailType"], "FileScanResultRecorded.v1")
        self.assertEqual(
            detail["metadata"]["idempotencyKey"],
            "scan:7d9f4e4c-0e0f-4a5b-8b4e-4ab1f28fd1d1:4Mh...",
        )
        self.assertEqual(
            detail["metadata"]["causationId"], "6dce6b40-6e43-49f0-a2cf-1da1d43bce22"
        )
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
            self.assertEqual(self.adapter.lambda_handler(self.event, None)["eventId"], "scan-result-event-id")
            IDEMPOTENCY_CACHE.clear()

        self.assertEqual(self.events_client.put_events.call_count, 5)

    def test_duplicate_guardduty_events_publish_once(self):
        first_result = self.adapter.lambda_handler(self.event, None)
        self.event["id"] = "another-guardduty-event-id"
        second_result = self.adapter.lambda_handler(self.event, None)

        self.assertEqual(first_result, second_result)
        self.events_client.put_events.assert_called_once()

    def test_rejects_conflicting_scan_result_for_the_same_object_version(self):
        self.adapter.lambda_handler(self.event, None)
        self.event["detail"]["scanResultDetails"]["scanResultStatus"] = "THREATS_FOUND"

        with self.assertRaisesRegex(ValueError, "Idempotency payload"):
            self.adapter.lambda_handler(self.event, None)

    def test_rejects_invalid_status_combination(self):
        self.event["detail"]["scanStatus"] = "COMPLETED"
        self.event["detail"]["scanResultDetails"]["scanResultStatus"] = "FAILED"

        with self.assertRaisesRegex(ValueError, "terminal GuardDuty outcome"):
            self.adapter.lambda_handler(self.event, None)

    def test_rejects_pre_publication_workflow_record(self):
        self.dynamodb_client.query.return_value["Items"][0]["status"] = {"S": "VERIFIED"}

        with self.assertRaisesRegex(RuntimeError, "not published"):
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
