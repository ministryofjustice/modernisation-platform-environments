import json
import os
import sys
import unittest
from types import SimpleNamespace
from unittest.mock import patch

os.environ.setdefault("CLIENT_NOTIFICATION_SNS_TOPIC_ARN", "arn:aws:sns:eu-west-2:111122223333:client-topic")
os.environ.setdefault(
    "CLIENT_DESTINATION_DELIVERY_CONFIG_JSON",
    json.dumps(
        {
            "products-poc": {
                "enabled": True,
                "request_url": "https://consumer.example.test/presigned-destination",
                "request_timeout_seconds": 15,
                "request_auth_secret_name": "products-poc-destination-api-auth",
            }
        }
    ),
)
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
sys.modules.setdefault("requests", SimpleNamespace(request=lambda *_args, **_kwargs: SimpleNamespace()))

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
        self.get_calls = []
        self.presign_calls = []

    def head_object(self, **kwargs):
        self.head_calls.append(kwargs)
        return {
            "ContentLength": 28,
            "ContentType": "text/csv",
            "Metadata": self.metadata,
        }

    def generate_presigned_url(self, method, Params, ExpiresIn):
        self.presign_calls.append({"method": method, "params": Params, "expires_in": ExpiresIn})
        return "https://example.test/download"

    def get_object(self, **kwargs):
        self.get_calls.append(kwargs)
        return {"Body": FakeStreamingBody(b"header1,header2\nvalue1,value2\n")}


class FakeStreamingBody:
    def __init__(self, payload):
        self.payload = payload
        self.is_closed = False

    def read(self, amt=None):
        if amt is None:
            amt = len(self.payload)
        chunk = self.payload[:amt]
        self.payload = self.payload[amt:]
        return chunk

    def close(self):
        self.is_closed = True


class FakeSnsClient:
    def __init__(self):
        self.publish_calls = []

    def publish(self, **kwargs):
        self.publish_calls.append(kwargs)
        return {"MessageId": f"message-{len(self.publish_calls)}"}


class FakeSecretsManager:
    def __init__(self, secret_string=None):
        self.secret_string = secret_string or json.dumps({"headers": {"Authorization": "Bearer test-token"}})
        self.calls = []

    def get_secret_value(self, SecretId):
        self.calls.append(SecretId)
        return {"SecretString": self.secret_string}


class FakeHttpResponse:
    def __init__(self, payload):
        self.payload = payload

    def raise_for_status(self):
        return None

    def json(self):
        return self.payload


class FakeRequests:
    def __init__(self):
        self.calls = []

    def request(self, method, url, **kwargs):
        self.calls.append({"method": method, "url": url, **kwargs})
        if len(self.calls) == 1:
            return FakeHttpResponse(
                {
                    "upload": {
                        "url": "https://destination.example.test/upload",
                        "method": "PUT",
                        "headers": {
                            "x-amz-server-side-encryption": "AES256",
                        },
                    }
                }
            )

        upload_body = kwargs["data"]
        self.uploaded_payload = upload_body.read()
        return FakeHttpResponse({})


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
    @patch.object(handler, "secrets_manager")
    @patch.object(handler, "requests")
    def test_publishes_slack_client_and_destination_delivery_when_client_metadata_is_present(
        self,
        patched_requests,
        patched_secrets_manager,
        patched_sns,
        patched_s3,
    ):
        fake_s3 = FakeS3Client(
            {
                "client-id": "products-poc",
                "original-file-name": "test.csv",
                "transfer-ticket": "ticket-123",
            }
        )
        fake_sns = FakeSnsClient()
        fake_requests = FakeRequests()
        fake_secrets_manager = FakeSecretsManager()
        patched_s3.head_object = fake_s3.head_object
        patched_s3.generate_presigned_url = fake_s3.generate_presigned_url
        patched_s3.get_object = fake_s3.get_object
        patched_sns.publish = fake_sns.publish
        patched_requests.request = fake_requests.request
        patched_secrets_manager.get_secret_value = fake_secrets_manager.get_secret_value

        handler.lambda_handler(self._event(), SimpleNamespace())

        self.assertEqual(2, len(fake_sns.publish_calls))
        client_publish = fake_sns.publish_calls[1]
        message = json.loads(client_publish["Message"])
        self.assertEqual(handler.CLIENT_NOTIFICATION_SNS_TOPIC_ARN, client_publish["TopicArn"])
        self.assertEqual("products-poc", message["clientId"])
        self.assertEqual("ticket-123", message["transferTicket"])
        self.assertEqual("test.csv", message["fileName"])
        self.assertEqual("products-poc", client_publish["MessageAttributes"]["clientId"]["StringValue"])
        self.assertEqual("products-poc-destination-api-auth", fake_secrets_manager.calls[0])
        self.assertEqual(2, len(fake_requests.calls))
        self.assertEqual("POST", fake_requests.calls[0]["method"])
        self.assertEqual("https://consumer.example.test/presigned-destination", fake_requests.calls[0]["url"])
        self.assertEqual("PUT", fake_requests.calls[1]["method"])
        self.assertEqual("https://destination.example.test/upload", fake_requests.calls[1]["url"])
        self.assertEqual(b"header1,header2\nvalue1,value2\n", fake_requests.uploaded_payload)
        self.assertEqual(
            "Bearer test-token",
            fake_requests.calls[0]["headers"]["Authorization"],
        )

    @patch.object(handler, "s3")
    @patch.object(handler, "sns")
    @patch.object(handler, "requests")
    def test_skips_client_notification_when_client_metadata_is_missing(self, patched_requests, patched_sns, patched_s3):
        fake_s3 = FakeS3Client({})
        fake_sns = FakeSnsClient()
        patched_s3.head_object = fake_s3.head_object
        patched_s3.generate_presigned_url = fake_s3.generate_presigned_url
        patched_s3.get_object = fake_s3.get_object
        patched_sns.publish = fake_sns.publish
        patched_requests.request = lambda *_args, **_kwargs: self.fail("requests.request should not be called")

        handler.lambda_handler(self._event(), SimpleNamespace())

        self.assertEqual(1, len(fake_sns.publish_calls))
        self.assertEqual(handler.SLACK_SNS_TOPIC_ARN, fake_sns.publish_calls[0]["TopicArn"])

    @patch.object(handler, "CLIENT_DESTINATION_DELIVERY_CONFIG", new={})
    @patch.object(handler, "s3")
    @patch.object(handler, "sns")
    @patch.object(handler, "requests")
    def test_skips_destination_delivery_when_client_has_no_delivery_config(
        self,
        patched_requests,
        patched_sns,
        patched_s3,
    ):
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
        patched_s3.get_object = fake_s3.get_object
        patched_sns.publish = fake_sns.publish
        patched_requests.request = lambda *_args, **_kwargs: self.fail("requests.request should not be called")

        handler.lambda_handler(self._event(), SimpleNamespace())

        self.assertEqual(2, len(fake_sns.publish_calls))


if __name__ == "__main__":
    unittest.main()
