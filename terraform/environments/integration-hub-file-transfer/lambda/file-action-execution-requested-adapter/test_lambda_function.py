import importlib
import json
import os
import sys
import unittest
from datetime import datetime, timedelta, timezone
from types import SimpleNamespace
from unittest.mock import MagicMock, patch


ACCOUNT_ID = "123456789012"
CLEAN_BUCKET = "integration-hub-file-transfer-development-clean"
IDEMPOTENCY_CACHE = {}
IDEMPOTENCY_DECORATORS = []
LOGS = []
METRICS = []


class FakeLogger:
    def __init__(self, **_kwargs):
        pass

    def info(self, *_args, **_kwargs):
        LOGS.append(("info", _args, _kwargs))

    def warning(self, *_args, **_kwargs):
        LOGS.append(("warning", _args, _kwargs))

    def exception(self, *_args, **_kwargs):
        LOGS.append(("exception", _args, _kwargs))

    def inject_lambda_context(self, **_kwargs):
        return lambda function: function


class FakeMetrics:
    def __init__(self, **_kwargs):
        pass

    def add_metric(self, name, unit, value):
        METRICS.append((name, unit, value))

    def log_metrics(self, function):
        return function


class FakeIdempotencyConfig:
    def __init__(self, **kwargs):
        self.options = kwargs


def fake_idempotent(**kwargs):
    IDEMPOTENCY_DECORATORS.append(kwargs)

    def decorator(function):
        def wrapped(event, context):
            key = event.get("detail", {}).get("metadata", {}).get("idempotencyKey")
            if key in IDEMPOTENCY_CACHE:
                return IDEMPOTENCY_CACHE[key]

            result = function(event, context)
            IDEMPOTENCY_CACHE[key] = result
            return result

        return wrapped

    return decorator


class FileActionExecutionRequestedAdapterHandlerTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.events_client = MagicMock()
        cls.secrets_client = MagicMock()
        cls.dynamodb_client = MagicMock()
        boto3 = MagicMock()
        boto3.client.side_effect = lambda service, **_kwargs: {
            "dynamodb": cls.dynamodb_client,
            "events": cls.events_client,
            "secretsmanager": cls.secrets_client,
        }[service]

        powertools = SimpleNamespace(Logger=FakeLogger, Metrics=FakeMetrics)
        powertools_metrics = SimpleNamespace(
            MetricUnit=SimpleNamespace(Seconds="Seconds")
        )
        powertools_idempotency = SimpleNamespace(
            DynamoDBPersistenceLayer=lambda **_kwargs: SimpleNamespace(),
            IdempotencyConfig=FakeIdempotencyConfig,
            idempotent=fake_idempotent,
        )
        cls.modules_patch = patch.dict(
            sys.modules,
            {
                "aws_lambda_powertools": powertools,
                "aws_lambda_powertools.metrics": powertools_metrics,
                "aws_lambda_powertools.utilities.idempotency": powertools_idempotency,
                "boto3": boto3,
                "botocore": MagicMock(),
                "botocore.config": MagicMock(),
            },
        )
        cls.modules_patch.start()
        os.environ.update(
            {
                "DISPATCH_SECRET_NAME_PREFIX": "integration-hub-file-transfer/file-dispatch/",
                "EVENT_BUS_ARN": "arn:aws:events:eu-west-2:123456789012:event-bus/file-transfer",
                "IDEMPOTENCY_EXPIRY_SECONDS": "2592000",
                "IDEMPOTENCY_TABLE": "adapter-idempotency",
                "WORKFLOW_IDEMPOTENCY_TABLE": "workflow-idempotency",
            }
        )
        cls.handler = importlib.import_module("lambda_function")

    @classmethod
    def tearDownClass(cls):
        cls.modules_patch.stop()

    def setUp(self):
        IDEMPOTENCY_CACHE.clear()
        LOGS.clear()
        METRICS.clear()
        self.dynamodb_client.reset_mock()
        self.dynamodb_client.get_item.side_effect = None
        self.dynamodb_client.get_item.return_value = {}
        self.events_client.reset_mock()
        self.secrets_client.reset_mock()
        self.events_client.put_events.side_effect = None
        self.secrets_client.get_secret_value.side_effect = None
        self.events_client.put_events.return_value = {
            "FailedEntryCount": 0,
            "Entries": [{"EventId": "requested-event-id"}],
        }
        self.secrets_client.get_secret_value.return_value = {
            "ARN": "arn:aws:secretsmanager:eu-west-2:123456789012:secret:identity/",
            "VersionId": "secret-version",
            "SecretString": json.dumps(
                {
                    "action": {
                        "name": "place-on-sqs",
                        "queueArn": "sensitive-queue-arn",
                    },
                    "notifications": {
                        "email": "sensitive-recipient",
                        "slack": None,
                        "teams": None,
                    },
                }
            ),
        }
        self.event = {
            "id": "aa88e95a-159c-40c1-9e7b-38d00b0b6169",
            "detail-type": "FileRouted.v1",
            "source": "uk.gov.justice.service.managed-file-transfer",
            "account": ACCOUNT_ID,
            "detail": {
                "metadata": {
                    "correlationId": "7d9f4e4c-0e0f-4a5b-8b4e-4ab1f28fd1d1",
                    "idempotencyKey": "route:clean:bucket:identity/report.csv:version",
                },
                "data": {
                    "fileId": "3f4e3d7a-4e2f-4bc2-9c4e-5f1ef2d4c501",
                    "route": "clean",
                    "destinationObject": {
                        "bucket": CLEAN_BUCKET,
                        "key": "identity/report.csv",
                        "versionId": "version",
                        "sizeBytes": 4096,
                    },
                },
            },
        }

    def test_publishes_requested_event(self):
        result = self.handler.lambda_handler(self.event, None)

        entry = self.events_client.put_events.call_args.kwargs["Entries"][0]
        detail = json.loads(entry["Detail"])
        self.assertEqual(entry["DetailType"], "FileActionExecutionRequested.v1")
        self.assertEqual(detail["data"]["action"], {"name": "place-on-sqs"})
        self.assertEqual(detail["data"]["notifications"], ["email"])
        self.assertNotIn("sensitive-queue-arn", entry["Detail"])
        self.assertNotIn("sensitive-recipient", entry["Detail"])
        self.assertEqual(result, {"eventId": "requested-event-id", "status": "PUBLISHED"})
        log_entry = LOGS[-1][2]["extra"]
        self.assertEqual(
            log_entry["correlation_id"],
            "7d9f4e4c-0e0f-4a5b-8b4e-4ab1f28fd1d1",
        )
        self.assertEqual(
            log_entry["action_request"]["action_execution_id"],
            detail["data"]["actionExecutionId"],
        )
        self.assertEqual(
            log_entry["action_request"]["destination_event_id"],
            "requested-event-id",
        )
        self.assertNotIn("sensitive-queue-arn", json.dumps(log_entry))
        self.assertNotIn("sensitive-recipient", json.dumps(log_entry))

    def test_records_end_to_end_latency_from_the_stage_record(self):
        received_at = datetime.now(timezone.utc) - timedelta(hours=1)
        self.dynamodb_client.get_item.return_value = {
            "Item": {"received_at": {"S": received_at.isoformat()}}
        }

        self.handler.lambda_handler(self.event, None)

        name, unit, value = METRICS[0]
        self.assertEqual((name, unit), ("EndToEndLatency", "Seconds"))
        self.assertAlmostEqual(value, 3600, delta=30)
        self.assertEqual(len(METRICS), 1)
        self.dynamodb_client.get_item.assert_called_once_with(
            TableName="workflow-idempotency",
            ConsistentRead=True,
            Key={
                "concurrencyId": {"S": "7d9f4e4c-0e0f-4a5b-8b4e-4ab1f28fd1d1"},
                "operation": {"S": "STAGE"},
            },
        )

    def test_falls_back_to_the_stage_claim_time(self):
        self.dynamodb_client.get_item.return_value = {
            "Item": {"created_at": {"N": "1783692000"}}
        }

        self.handler.lambda_handler(self.event, None)

        self.assertEqual(len(METRICS), 1)

    def test_dispatch_succeeds_when_the_landing_time_is_unavailable(self):
        self.dynamodb_client.get_item.side_effect = Exception("dynamodb unavailable")

        result = self.handler.lambda_handler(self.event, None)

        self.assertEqual(result["status"], "PUBLISHED")
        self.assertEqual(METRICS, [])

    def test_skips_latency_when_there_is_no_stage_record(self):
        self.dynamodb_client.get_item.return_value = {}

        result = self.handler.lambda_handler(self.event, None)

        self.assertEqual(result["status"], "PUBLISHED")
        self.assertEqual(METRICS, [])

    def test_uses_source_logical_idempotency_key(self):
        self.assertEqual(
            self.handler.idempotency_config.options["event_key_jmespath"],
            "detail.metadata.idempotencyKey",
        )
        self.assertEqual(
            self.handler.idempotency_config.options["payload_validation_jmespath"],
            '[source, "detail-type", account, detail]',
        )

        first_result = self.handler.lambda_handler(self.event, None)
        self.event["id"] = "different-envelope-id"
        second_result = self.handler.lambda_handler(self.event, None)

        self.assertEqual(first_result, second_result)
        self.events_client.put_events.assert_called_once()

    def test_returns_no_match_without_publishing(self):
        not_found = Exception("not found")
        not_found.response = {"Error": {"Code": "ResourceNotFoundException"}}
        self.secrets_client.get_secret_value.side_effect = not_found

        result = self.handler.lambda_handler(self.event, None)

        self.assertEqual(result, {"eventId": None, "status": "NO_MATCH"})
        self.events_client.put_events.assert_not_called()

    def test_returns_no_actions_for_an_all_null_configuration(self):
        self.secrets_client.get_secret_value.return_value["SecretString"] = json.dumps(
            {
                "action": None,
                "notifications": {"email": None, "slack": None, "teams": None},
            }
        )

        result = self.handler.lambda_handler(self.event, None)

        self.assertEqual(result, {"eventId": None, "status": "NO_ACTIONS"})
        self.events_client.put_events.assert_not_called()

    def test_raises_when_any_publish_entry_fails(self):
        self.events_client.put_events.return_value = {
            "FailedEntryCount": 1,
            "Entries": [{"ErrorCode": "InternalFailure", "ErrorMessage": "failed"}],
        }

        with self.assertRaisesRegex(RuntimeError, "Failed to publish"):
            self.handler.lambda_handler(self.event, None)


if __name__ == "__main__":
    unittest.main()