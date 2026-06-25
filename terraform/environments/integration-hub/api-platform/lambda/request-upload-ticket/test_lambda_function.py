import os
import json
import sys
import unittest
from types import SimpleNamespace
from unittest.mock import patch

os.environ.setdefault("TRANSFER_CLIENTS_TABLE", "transfer-clients")
os.environ.setdefault("MULTIPART_SESSIONS_TABLE", "multipart-sessions")
os.environ.setdefault("UPLOAD_BUCKET_NAME", "upload-bucket")
os.environ.setdefault("UPLOAD_BUCKET_KMS_KEY_ARN", "arn:aws:kms:eu-west-2:111122223333:key/example")
os.environ.setdefault("PRESIGNED_URL_EXPIRY_SECONDS", "900")
os.environ.setdefault("MAX_PRESIGNED_URL_EXPIRY_SECONDS", "3600")
os.environ.setdefault("SINGLE_PUT_LIMIT_BYTES", "5368709120")
os.environ.setdefault("MULTIPART_DEFAULT_PART_SIZE_BYTES", "67108864")
os.environ.setdefault("MULTIPART_INITIAL_PRESIGN_PARTS", "10")
os.environ.setdefault("MULTIPART_MAX_PARTS", "10000")

sys.modules.setdefault(
    "boto3",
    SimpleNamespace(
        client=lambda _service_name: SimpleNamespace(),
        resource=lambda _service_name: SimpleNamespace(),
    ),
)

import lambda_function as handler


class FakeTable:
    def __init__(self, items=None):
        self.items = items or {}

    def get_item(self, Key):
        key_name, key_value = next(iter(Key.items()))
        item = self.items.get(key_value)
        return {"Item": item} if item is not None else {}

    def put_item(self, Item):
        self.items[Item["transfer_ticket"]] = Item

    def update_item(self, Key, **_kwargs):
        transfer_ticket = Key["transfer_ticket"]
        if transfer_ticket not in self.items:
            raise KeyError(transfer_ticket)


class FakeDynamoResource:
    def __init__(self, tables):
        self.tables = tables

    def Table(self, name):
        return self.tables[name]


class FakeS3Client:
    def __init__(self):
        self.create_calls = []
        self.presign_calls = []

    def generate_presigned_url(self, ClientMethod, Params, ExpiresIn, HttpMethod):
        self.presign_calls.append(
            {
                "ClientMethod": ClientMethod,
                "Params": Params,
                "ExpiresIn": ExpiresIn,
                "HttpMethod": HttpMethod,
            }
        )
        if ClientMethod == "upload_part":
            return f"https://example.test/upload-part/{Params['PartNumber']}"
        return "https://example.test/upload"

    def create_multipart_upload(self, **kwargs):
        self.create_calls.append(kwargs)
        return {"UploadId": "upload-123"}


class UploadLambdaTests(unittest.TestCase):
    def setUp(self):
        self.transfer_clients = FakeTable(
            {
                "products-poc": {
                    "client_id": "products-poc",
                    "enabled": True,
                    "key_prefix": "products-poc/uploads",
                    "max_upload_size_bytes": 107374182400,
                    "allowed_content_types": ["text/csv"],
                }
            }
        )
        self.multipart_sessions = FakeTable()
        self.fake_dynamo = FakeDynamoResource(
            {
                handler.TRANSFER_CLIENTS_TABLE: self.transfer_clients,
                handler.MULTIPART_SESSIONS_TABLE: self.multipart_sessions,
            }
        )
        self.fake_s3 = FakeS3Client()

    def _event(self, route_key, body, path_parameters=None):
        return {
            "routeKey": route_key,
            "body": json.dumps(body) if body is not None else None,
            "pathParameters": path_parameters or {},
            "requestContext": {
                "authorizer": {
                    "lambda": {
                        "allowedClientIds": "products-poc",
                        "principalId": "test-user",
                        "roleName": "products-poc-upload",
                        "authType": "basic",
                    }
                }
            },
        }

    @patch.object(handler, "DYNAMODB")
    @patch.object(handler, "S3_CLIENT")
    @patch.object(handler.uuid, "uuid4", side_effect=["ticket-1", "object-1"])
    def test_small_file_uses_single_upload(self, _uuid4, patched_s3, patched_dynamo):
        patched_s3.generate_presigned_url = self.fake_s3.generate_presigned_url
        patched_dynamo.Table = self.fake_dynamo.Table

        response = handler.lambda_handler(
            self._event(
                "POST /transfer-tickets",
                {
                    "clientId": "products-poc",
                    "fileName": "example.csv",
                    "contentType": "text/csv",
                    "sizeBytes": 1024,
                },
            ),
            None,
        )

        body = json.loads(response["body"])
        self.assertEqual(200, response["statusCode"])
        self.assertEqual("https://example.test/upload", body["upload"]["url"])
        self.assertEqual("1024", body["upload"]["headers"]["x-amz-meta-declared-size-bytes"])

    @patch.object(handler, "DYNAMODB")
    @patch.object(handler, "S3_CLIENT")
    @patch.object(handler.uuid, "uuid4", side_effect=["ticket-2", "object-2"])
    def test_large_file_uses_multipart_upload(self, _uuid4, patched_s3, patched_dynamo):
        patched_s3.generate_presigned_url = self.fake_s3.generate_presigned_url
        patched_s3.create_multipart_upload = self.fake_s3.create_multipart_upload
        patched_dynamo.Table = self.fake_dynamo.Table

        response = handler.lambda_handler(
            self._event(
                "POST /transfer-tickets",
                {
                    "clientId": "products-poc",
                    "fileName": "example.csv",
                    "contentType": "text/csv",
                    "sizeBytes": handler.SINGLE_PUT_LIMIT_BYTES + 1,
                },
            ),
            None,
        )

        body = json.loads(response["body"])
        self.assertEqual(200, response["statusCode"])
        self.assertEqual("upload-123", body["multipart"]["uploadId"])
        self.assertTrue(body["multipart"]["initialParts"])
        self.assertIn("ticket-2", self.multipart_sessions.items)
        self.assertEqual(handler.SINGLE_PUT_LIMIT_BYTES + 1, self.multipart_sessions.items["ticket-2"]["declared_size_bytes"])

    @patch.object(handler, "DYNAMODB")
    @patch.object(handler, "S3_CLIENT")
    def test_part_presign_returns_requested_parts(self, patched_s3, patched_dynamo):
        patched_s3.generate_presigned_url = self.fake_s3.generate_presigned_url
        patched_dynamo.Table = self.fake_dynamo.Table
        self.multipart_sessions.items["ticket-3"] = {
            "transfer_ticket": "ticket-3",
            "status": "initiated",
            "client_id": "products-poc",
            "bucket": "bucket-name",
            "object_key": "products-poc/uploads/object.csv",
            "upload_id": "upload-456",
            "expires_in_seconds": 900,
            "part_size_bytes": 67108864,
            "total_parts": 3,
        }

        response = handler.lambda_handler(
            self._event(
                "POST /transfer-tickets/{transferTicket}/parts",
                {"partNumbers": [1, 3]},
                {"transferTicket": "ticket-3"},
            ),
            None,
        )

        body = json.loads(response["body"])
        self.assertEqual(200, response["statusCode"])
        self.assertEqual([1, 3], [part["partNumber"] for part in body["parts"]])


if __name__ == "__main__":
    unittest.main()
