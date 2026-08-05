import importlib
import os
import sys
import unittest
from types import SimpleNamespace
from unittest.mock import MagicMock, patch


IDEMPOTENCY_DECORATORS = []


class FakeLogger:
    def __init__(self, **_kwargs):
        pass

    def info(self, *_args, **_kwargs):
        pass

    def exception(self, *_args, **_kwargs):
        pass

    def inject_lambda_context(self, **_kwargs):
        return lambda function: function


class FakeIdempotencyConfig:
    def __init__(self, **kwargs):
        self.options = kwargs


def fake_idempotent(**kwargs):
    IDEMPOTENCY_DECORATORS.append(kwargs)
    return lambda function: function


class HandlerPackagingTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        boto3 = MagicMock()
        boto3.resource.return_value.Table.return_value = MagicMock()
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
                "EVENT_BUS_ARN": "event-bus-arn",
                "IDEMPOTENCY_EXPIRY_SECONDS": "3600",
                "IDEMPOTENCY_TABLE": "adapter-idempotency",
                "WORKFLOW_IDEMPOTENCY_TABLE": "workflow-idempotency",
                "INCOMING_BUCKET_NAME": "incoming",
                "INCOMING_KMS_KEY_ARN": "incoming-kms",
                "PROCESSING_BUCKET_NAME": "processing",
                "PROCESSING_KMS_KEY_ARN": "processing-kms",
                "CLEAN_BUCKET_NAME": "clean",
                "CLEAN_KMS_KEY_ARN": "clean-kms",
                "QUARANTINE_BUCKET_NAME": "quarantine",
                "QUARANTINE_KMS_KEY_ARN": "quarantine-kms",
                "INVESTIGATION_BUCKET_NAME": "investigation",
                "INVESTIGATION_KMS_KEY_ARN": "investigation-kms",
            }
        )
        cls.stage = importlib.import_module("stage_lambda")
        cls.route = importlib.import_module("route_lambda")

    @classmethod
    def tearDownClass(cls):
        cls.modules_patch.stop()

    def test_handlers_share_the_package_but_have_separate_operations(self):
        self.assertEqual(self.stage.service.operation, "STAGE")
        self.assertEqual(self.route.service.operation, "ROUTE")
        self.assertIs(self.stage.FileMoverService, self.route.FileMoverService)

    def test_handlers_use_distinct_powertools_idempotency_prefixes(self):
        self.assertEqual(
            [decorator["key_prefix"] for decorator in IDEMPOTENCY_DECORATORS],
            ["managed-file-transfer/stage", "managed-file-transfer/route"],
        )
        self.assertEqual(
            self.stage.idempotency_config.options["event_key_jmespath"], "id"
        )


if __name__ == "__main__":
    unittest.main()