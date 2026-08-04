import importlib.util
import os
import sys
import unittest
from pathlib import Path
from types import ModuleType
from unittest.mock import MagicMock, patch


CUSTOM_IDP_DIRECTORY = Path(__file__).parent
HANDLER_FILE = CUSTOM_IDP_DIRECTORY / "idp_handler" / "app.py"
LAYER_DIRECTORY = CUSTOM_IDP_DIRECTORY / "layer" / "python"


class CustomIdpTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        sys.path.insert(0, str(LAYER_DIRECTORY))

        sts_client = MagicMock()
        sts_client.get_caller_identity.return_value = {"Account": "123456789012"}

        boto3 = ModuleType("boto3")
        boto3.client = MagicMock(
            side_effect=lambda service: sts_client if service == "sts" else MagicMock()
        )
        boto3.resource = MagicMock()

        boto3_dynamodb = ModuleType("boto3.dynamodb")
        boto3_conditions = ModuleType("boto3.dynamodb.conditions")
        boto3_conditions.Key = MagicMock()

        cls.modules_patch = patch.dict(
            sys.modules,
            {
                "boto3": boto3,
                "boto3.dynamodb": boto3_dynamodb,
                "boto3.dynamodb.conditions": boto3_conditions,
            },
        )
        cls.modules_patch.start()

        os.environ["USERS_TABLE"] = "custom-idp-users"
        os.environ["IDENTITY_PROVIDERS_TABLE"] = "custom-idp-identity-providers"

        spec = importlib.util.spec_from_file_location("custom_idp_handler", HANDLER_FILE)
        cls.handler = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(cls.handler)

    @classmethod
    def tearDownClass(cls):
        cls.modules_patch.stop()
        sys.path.remove(str(LAYER_DIRECTORY))

    def test_rejects_request_without_source_ip(self):
        with self.assertRaisesRegex(self.handler.AuthenticationError, "Source IP is missing"):
            self.handler.validate_request_context(
                {"serverId": "s-1234567890abcdef0"},
                "example-user",
                {},
                {},
            )

    def test_accepts_source_ip_in_canonical_cidr(self):
        self.assertTrue(
            self.handler.ip_in_cidr_list("192.0.2.10", ["192.0.2.0/24"])
        )

    def test_rejects_invalid_source_ip(self):
        self.assertFalse(
            self.handler.ip_in_cidr_list("not-an-ip-address", ["192.0.2.0/24"])
        )

    def test_rejects_invalid_source_ip_when_allow_list_is_empty(self):
        self.assertFalse(self.handler.ip_in_cidr_list("not-an-ip-address", []))

    def test_rejects_non_canonical_cidr(self):
        self.assertFalse(
            self.handler.ip_in_cidr_list("192.0.2.10", ["192.0.2.1/24"])
        )


if __name__ == "__main__":
    unittest.main()