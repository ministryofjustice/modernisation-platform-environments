import importlib
import hashlib
import json
import os
import sys
import unittest
from datetime import datetime, timezone
from types import SimpleNamespace
from unittest.mock import MagicMock, patch


INCOMING_BUCKET = "integration-hub-file-transfer-development-incoming"


class FakeLogger:
    def __init__(self, **_kwargs):
        pass

    def info(self, *_args, **_kwargs):
        return None

    def exception(self, *_args, **_kwargs):
        return None

    def inject_lambda_context(self, **_kwargs):
        return lambda function: function


class FakeIdempotencyConfig:
    def __init__(self, **kwargs):
        self.options = kwargs


IDEMPOTENCY_CACHE = {}


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


class FileReceivedAdapterTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.events_client = MagicMock()
        boto3 = MagicMock()
        boto3.client.return_value = cls.events_client

        powertools = SimpleNamespace(Logger=FakeLogger)
        powertools_idempotency = SimpleNamespace(
            DynamoDBPersistenceLayer=lambda **_kwargs: SimpleNamespace(),
            IdempotencyConfig=FakeIdempotencyConfig,
            idempotent=fake_idempotent,
        )
        cls.modules_patch = patch.dict(
            sys.modules,
            {
                "aws_lambda_powertools": powertools,
                "aws_lambda_powertools.utilities.idempotency": powertools_idempotency,
                "boto3": boto3,
            },
        )
        cls.modules_patch.start()
        os.environ["EVENT_BUS_ARN"] = "arn:aws:events:eu-west-2:123456789012:event-bus/file-transfer"
        os.environ["IDEMPOTENCY_EXPIRY_SECONDS"] = "2592000"
        os.environ["IDEMPOTENCY_TABLE"] = "file-transfer-idempotency"
        os.environ["INCOMING_BUCKET_NAME"] = INCOMING_BUCKET
        cls.adapter = importlib.import_module("lambda_function")

    @classmethod
    def tearDownClass(cls):
        cls.modules_patch.stop()

    def setUp(self):
        IDEMPOTENCY_CACHE.clear()
        self.events_client.reset_mock()
        self.events_client.put_events.return_value = {
            "FailedEntryCount": 0,
            "Entries": [{"EventId": "canonical-event-id"}],
        }
        self.event = {
            "version": "0",
            "id": "7d9f4e4c-0e0f-4a5b-8b4e-4ab1f28fd1d1",
            "detail-type": "Object Created",
            "source": "aws.s3",
            "account": "123456789012",
            "time": "2026-07-10T14:00:00Z",
            "region": "eu-west-2",
            "detail": {
                "bucket": {"name": INCOMING_BUCKET},
                "object": {
                    "key": "example/report.csv",
                    "size": 4096,
                    "version-id": "3Lg...",
                },
            },
        }

    def test_publishes_file_received_event(self):
        result = self.adapter.lambda_handler(self.event, None)

        entry = self.events_client.put_events.call_args.kwargs["Entries"][0]
        detail = json.loads(entry["Detail"])
        expected_file_id = hashlib.sha256(
            f"{INCOMING_BUCKET}:example/report.csv:3Lg...".encode("utf-8")
        ).hexdigest()
        self.assertEqual(entry["DetailType"], "FileReceived.v1")
        self.assertEqual(
            entry["Source"], "uk.gov.justice.service.managed-file-transfer"
        )
        self.assertEqual(detail["data"]["fileId"], expected_file_id)
        self.assertEqual(detail["metadata"]["correlationId"], expected_file_id)
        self.assertEqual(
            detail["metadata"]["idempotencyKey"],
            f"{INCOMING_BUCKET}:example/report.csv:3Lg...",
        )
        self.assertEqual(detail["data"]["object"]["sizeBytes"], 4096)
        self.assertEqual(entry["Time"], datetime(2026, 7, 10, 14, tzinfo=timezone.utc))
        self.assertEqual(result, {"eventId": "canonical-event-id"})

    def test_identical_event_reuses_stable_identifiers(self):
        first_result = self.adapter.lambda_handler(self.event, None)
        second_result = self.adapter.lambda_handler(self.event, None)

        self.assertEqual(first_result, second_result)
        self.events_client.put_events.assert_called_once()

    def test_same_object_version_has_stable_identity_across_notifications(self):
        first_detail = self.adapter._build_detail(self.event)
        self.event["id"] = "a-new-native-event-id"
        second_detail = self.adapter._build_detail(self.event)

        self.assertEqual(first_detail["data"]["fileId"], second_detail["data"]["fileId"])
        self.assertEqual(
            first_detail["metadata"]["correlationId"],
            second_detail["metadata"]["correlationId"],
        )

    def test_configures_source_event_id_as_required_idempotency_key(self):
        self.assertEqual(self.adapter.idempotency_config.options["event_key_jmespath"], "id")
        self.assertTrue(
            self.adapter.idempotency_config.options["raise_on_no_idempotency_key"]
        )
        self.assertEqual(
            self.adapter.idempotency_config.options["expires_after_seconds"],
            2592000,
        )

    def test_rejects_event_for_another_bucket(self):
        self.event["detail"]["bucket"]["name"] = "another-bucket"

        with self.assertRaisesRegex(ValueError, "configured incoming bucket"):
            self.adapter.lambda_handler(self.event, None)

        self.events_client.put_events.assert_not_called()

    def test_rejects_wrong_source(self):
        self.event["source"] = "aws.guardduty"

        with self.assertRaisesRegex(ValueError, "source must be aws.s3"):
            self.adapter.lambda_handler(self.event, None)

        self.events_client.put_events.assert_not_called()

    def test_rejects_wrong_detail_type(self):
        self.event["detail-type"] = "Object Deleted"

        with self.assertRaisesRegex(ValueError, "detail-type must be Object Created"):
            self.adapter.lambda_handler(self.event, None)

        self.events_client.put_events.assert_not_called()

    def test_rejects_missing_object_version(self):
        del self.event["detail"]["object"]["version-id"]

        with self.assertRaisesRegex(ValueError, "detail.object.version-id"):
            self.adapter.lambda_handler(self.event, None)

        self.events_client.put_events.assert_not_called()

    def test_rejects_missing_object_size(self):
        del self.event["detail"]["object"]["size"]

        with self.assertRaisesRegex(ValueError, "detail.object.size"):
            self.adapter.lambda_handler(self.event, None)

        self.events_client.put_events.assert_not_called()

    def test_raises_when_put_events_reports_failure(self):
        self.events_client.put_events.return_value = {
            "FailedEntryCount": 1,
            "Entries": [{"ErrorCode": "InternalFailure", "ErrorMessage": "failed"}],
        }

        with self.assertRaisesRegex(RuntimeError, "Failed to publish"):
            self.adapter.lambda_handler(self.event, None)


if __name__ == "__main__":
    unittest.main()