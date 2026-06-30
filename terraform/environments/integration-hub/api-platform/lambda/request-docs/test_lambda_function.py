import base64
import json
import os
import sys
import unittest
from types import SimpleNamespace
from unittest.mock import patch


os.environ.setdefault("DOCS_BASIC_AUTH_SECRET_ID", "docs-secret")

sys.modules.setdefault(
    "boto3",
    SimpleNamespace(
        client=lambda _service_name: SimpleNamespace(),
    ),
)

import lambda_function as handler


class FakeSecretsManager:
    def get_secret_value(self, SecretId):
        assert SecretId == handler.DOCS_BASIC_AUTH_SECRET_ID
        return {
            "SecretString": json.dumps(
                {
                    "username": "docs-user",
                    "password": "docs-password",
                }
            )
        }


class DocsLambdaTests(unittest.TestCase):
    def _event(self, raw_path, authorization=None):
        headers = {}
        if authorization:
            headers["authorization"] = authorization
        return {
            "rawPath": raw_path,
            "headers": headers,
        }

    @patch.object(handler, "SECRETS_MANAGER", new=FakeSecretsManager())
    def test_docs_html_is_returned(self):
        token = base64.b64encode(b"docs-user:docs-password").decode("ascii")
        response = handler.lambda_handler(self._event("/docs", f"Basic {token}"), None)

        self.assertEqual(200, response["statusCode"])
        self.assertIn("SwaggerUIBundle", response["body"])
        self.assertTrue(response["headers"]["content-type"].startswith("text/html"))

    @patch.object(handler, "SECRETS_MANAGER", new=FakeSecretsManager())
    def test_openapi_yaml_is_returned(self):
        token = base64.b64encode(b"docs-user:docs-password").decode("ascii")
        response = handler.lambda_handler(self._event("/openapi.yaml", f"Basic {token}"), None)

        self.assertEqual(200, response["statusCode"])
        self.assertIn("openapi: 3.0.3", response["body"])
        self.assertTrue(response["headers"]["content-type"].startswith("application/yaml"))

    @patch.object(handler, "SECRETS_MANAGER", new=FakeSecretsManager())
    def test_missing_authorization_is_rejected(self):
        response = handler.lambda_handler(self._event("/docs"), None)

        self.assertEqual(401, response["statusCode"])
        self.assertIn("www-authenticate", response["headers"])


if __name__ == "__main__":
    unittest.main()
