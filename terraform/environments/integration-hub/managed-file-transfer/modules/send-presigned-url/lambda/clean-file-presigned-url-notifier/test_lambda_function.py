import json
import os
import sys
import unittest
from types import SimpleNamespace
from unittest.mock import patch

os.environ.setdefault("CLIENT_NOTIFICATION_SNS_TOPIC_ARN", "arn:aws:sns:eu-west-2:111122223333:client-topic")
os.environ.setdefault("DOWNLOAD_BUCKET_NAME", "clean-bucket")
os.environ.setdefault("DOWNLOAD_URL_EXPIRY_SECONDS", "1800")
os.environ.setdefault("IDEMPOTENCY_TABLE", "idempotency-table")
os.environ.setdefault("MAX_DOWNLOAD_URL_EXPIRY_SECONDS", "3600")
os.environ.setdefault("SLACK_SNS_TOPIC_ARN", "arn:aws:sns:eu-west-2:111122223333:slack-topic")


class FakeLogger:
    def __init__(self, **_kwargs):
        pass

    def info(self, *_args, **_kwargs):
        return None

    def exception(self, *_args, **_kwargs):
        return None

    def inject_lambda_context(self, clear_state=True, log_event=False):
        def decorator(function):
            return function

        return decorator


class FakeIdempotencyConfig:
    def __init__(self, **_kwargs):
        pass

    def register_lambda_context(self, _context):
        return None


def fake_idempotent_function(**_kwargs):
    def decorator(function):
        return function

    return decorator


sys.modules.setdefault("boto3", SimpleNamespace(client=lambda _service_name, **_kwargs: SimpleNamespace()))

# `from botocore.config import Config` imports `botocore` first, so stub both the
# package and the submodule to keep tests runnable without botocore installed.
_module_type = type(sys)
_botocore_pkg = _module_type("botocore")
_botocore_pkg.__path__ = []
_botocore_config = _module_type("botocore.config")
_botocore_config.Config = lambda **_kwargs: SimpleNamespace()
sys.modules.setdefault("botocore", _botocore_pkg)
sys.modules.setdefault("botocore.config", _botocore_config)

sys.modules.setdefault("aws_lambda_powertools", SimpleNamespace(Logger=FakeLogger))
sys.modules.setdefault(
    "aws_lambda_powertools.utilities.idempotency",
    SimpleNamespace(
        DynamoDBPersistenceLayer=lambda **_kwargs: SimpleNamespace(),
        IdempotencyConfig=FakeIdempotencyConfig,
        idempotent_function=fake_idempotent_function,
    ),
)

import lambda_function as handler


class FakeS3Client:
    def __init__(self, metadata):
        self.metadata = metadata
        self.head_calls = []
        self.presign_calls = []

    def head_object(self, **kwargs):
        self.head_calls.append(kwargs)
        return {"Metadata": self.metadata}

    def generate_presigned_url(self, method, Params, ExpiresIn):
        self.presign_calls.append({"method": method, "params": Params, "expires_in": ExpiresIn})
        return "https://example.test/download"


class FakeSnsClient:
    def __init__(self):
        self.publish_calls = []

    def publish(self, **kwargs):
        self.publish_calls.append(kwargs)
        return {"MessageId": f"message-{len(self.publish_calls)}"}


class CleanFileNotifierTests(unittest.TestCase):
    def _event(self):
        return {
            "Records": [
                {
                    "body": json.dumps(
                        {
                            "Records": [
                                {
                                    "eventSource": "aws:s3",
                                    "s3": {
                                        "bucket": {"name": "clean-bucket"},
                                        "object": {"key": "products-poc/uploads/2026/06/25/test.csv"},
                                    },
                                }
                            ]
                        }
                    )
                }
            ]
        }

    @patch.object(handler, "s3")
    @patch.object(handler, "sns")
    def test_publishes_slack_and_client_notifications_when_client_metadata_is_present(self, patched_sns, patched_s3):
        fake_s3 = FakeS3Client(
            {
                "client-id": "products-poc",
                "original-file-name": "test.csv",
                "transfer-ticket": "ticket-123",
            }
        )
        fake_sns = FakeSnsClient()
        patched_s3.head_object = fake_s3.head_object
        patched_s3.generate_presigned_url = fake_s3.generate_presigned_url
        patched_sns.publish = fake_sns.publish

        handler.lambda_handler(self._event(), SimpleNamespace())

        self.assertEqual(2, len(fake_sns.publish_calls))
        client_publish = fake_sns.publish_calls[1]
        message = json.loads(client_publish["Message"])
        self.assertEqual(handler.CLIENT_NOTIFICATION_SNS_TOPIC_ARN, client_publish["TopicArn"])
        self.assertEqual("products-poc", message["clientId"])
        self.assertEqual("ticket-123", message["transferTicket"])
        self.assertEqual("test.csv", message["fileName"])
        self.assertEqual("products-poc", client_publish["MessageAttributes"]["clientId"]["StringValue"])

    @patch.object(handler, "s3")
    @patch.object(handler, "sns")
    def test_skips_client_notification_when_client_metadata_is_missing(self, patched_sns, patched_s3):
        fake_s3 = FakeS3Client({})
        fake_sns = FakeSnsClient()
        patched_s3.head_object = fake_s3.head_object
        patched_s3.generate_presigned_url = fake_s3.generate_presigned_url
        patched_sns.publish = fake_sns.publish

        handler.lambda_handler(self._event(), SimpleNamespace())

        self.assertEqual(1, len(fake_sns.publish_calls))
        self.assertEqual(handler.SLACK_SNS_TOPIC_ARN, fake_sns.publish_calls[0]["TopicArn"])


if __name__ == "__main__":
    unittest.main()
