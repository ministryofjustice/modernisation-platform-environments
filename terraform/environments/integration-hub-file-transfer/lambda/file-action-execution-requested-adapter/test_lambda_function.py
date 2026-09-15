import importlib
import json
import os
import sys
import unittest
from types import SimpleNamespace
from unittest.mock import MagicMock, patch


ACCOUNT_ID = "123456789012"
CLEAN_BUCKET = "integration-hub-file-transfer-development-clean"
IDEMPOTENCY_CACHE = {}
IDEMPOTENCY_DECORATORS = []
LOGS = []


class FakeLogger:
    def __init__(self, **_kwargs):
        pass

    def info(self, *_args, **_kwargs):
        LOGS.append(("info", _args, _kwargs))

    def exception(self, *_args, **_kwargs):
        LOGS.append(("exception", _args, _kwargs))

    def inject_lambda_context(self, **_kwargs):
        return lambda function: function


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
        boto3 = MagicMock()
        boto3.client.side_effect = lambda service: {
            "events": cls.events_client,
            "secretsmanager": cls.secrets_client,
        }[service]

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
        os.environ.update(
            {
                "DISPATCH_SECRET_NAME_PREFIX": "integration-hub-file-transfer/file-dispatch/",
                "EVENT_BUS_ARN": "arn:aws:events:eu-west-2:123456789012:event-bus/file-transfer",
                "IDEMPOTENCY_EXPIRY_SECONDS": "2592000",
                "IDEMPOTENCY_TABLE": "adapter-idempotency",
            }
        )
        cls.handler = importlib.import_module("lambda_function")

    @classmethod
    def tearDownClass(cls):
        cls.modules_patch.stop()

    def setUp(self):
        IDEMPOTENCY_CACHE.clear()
        LOGS.clear()
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