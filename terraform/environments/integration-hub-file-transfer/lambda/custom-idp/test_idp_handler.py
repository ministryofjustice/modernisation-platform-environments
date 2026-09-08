import importlib.util
import json
import os
import sys
import unittest
from pathlib import Path
from types import ModuleType, SimpleNamespace
from unittest.mock import MagicMock, patch


CUSTOM_IDP_DIRECTORY = Path(__file__).parent
HANDLER_FILE = CUSTOM_IDP_DIRECTORY / "idp_handler" / "app.py"
LAYER_DIRECTORY = CUSTOM_IDP_DIRECTORY / "layer" / "python"
SECRET_PREFIX = "integration-hub-file-transfer/development/transfer-users/"
AWS_ACCOUNT_ID = "123456789012"
TRANSFER_ROLE_ARN = "arn:aws:iam::123456789012:role/transfer-user"
TRANSFER_SESSION_POLICY = '{"Version":"2012-10-17","Statement":[]}'
TRANSFER_HOME_DIRECTORY_DETAILS = (
    '[{"Entry":"/","Target":"/integration-hub-file-transfer-development-incoming/{{USERNAME}}"}]'
)


class ResourceNotFoundException(Exception):
    pass


class CustomIdpTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        sys.path.insert(0, str(LAYER_DIRECTORY))

        secretsmanager_client = MagicMock()
        secretsmanager_client.exceptions = SimpleNamespace(
            ResourceNotFoundException=ResourceNotFoundException
        )

        boto3 = ModuleType("boto3")
        boto3.client = MagicMock(return_value=secretsmanager_client)

        cls.modules_patch = patch.dict(sys.modules, {"boto3": boto3})
        cls.modules_patch.start()

        os.environ["SECRET_PREFIX"] = SECRET_PREFIX
        os.environ["AWS_ACCOUNT_ID"] = AWS_ACCOUNT_ID
        os.environ["TRANSFER_ROLE_ARN"] = TRANSFER_ROLE_ARN
        os.environ["TRANSFER_SESSION_POLICY"] = TRANSFER_SESSION_POLICY
        os.environ["TRANSFER_HOME_DIRECTORY_DETAILS"] = TRANSFER_HOME_DIRECTORY_DETAILS

        spec = importlib.util.spec_from_file_location("custom_idp_handler", HANDLER_FILE)
        cls.handler = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(cls.handler)

    @classmethod
    def tearDownClass(cls):
        cls.modules_patch.stop()
        sys.path.remove(str(LAYER_DIRECTORY))

    def setUp(self):
        self.secrets = {}
        self.handler.secretsmanager_client.get_secret_value.reset_mock()
        self.handler.secretsmanager_client.get_secret_value.side_effect = self.get_secret_value

    def get_secret_value(self, SecretId):
        if SecretId not in self.secrets:
            raise ResourceNotFoundException()
        return {"SecretString": json.dumps(self.secrets[SecretId])}

    def user_record(self, **overrides):
        record = {
            "username": "example-user",
            "password": "super-secret",
            "publicKeys": ["ssh-ed25519 AAAATEST"],
            "ipv4_allow_list": [],
            "server_id_allow_list": [],
        }
        record.update(overrides)
        return record

    def event(self, **overrides):
        event = {
            "username": "Example-User",
            "password": "super-secret",
            "serverId": "s-1234567890abcdef0",
            "sourceIp": "192.0.2.10",
            "protocol": "FTPS",
        }
        event.update(overrides)
        return event

    def add_user_secret(self, record=None):
        self.secrets[f"{SECRET_PREFIX}example-user"] = record or self.user_record()

    def test_password_authentication_uses_one_secret_lookup(self):
        self.add_user_secret()

        response = self.handler.lambda_handler(self.event(), None)

        self.assertEqual(TRANSFER_ROLE_ARN, response["Role"])
        self.assertEqual(TRANSFER_SESSION_POLICY, response["Policy"])
        self.assertEqual("LOGICAL", response["HomeDirectoryType"])
        self.assertEqual(
            '[{"Entry": "/", "Target": "/integration-hub-file-transfer-development-incoming/example-user"}]',
            response["HomeDirectoryDetails"],
        )
        self.assertEqual(1, self.handler.secretsmanager_client.get_secret_value.call_count)
        self.handler.secretsmanager_client.get_secret_value.assert_called_once_with(
            SecretId=f"{SECRET_PREFIX}example-user"
        )
        self.assertNotIn("password", response)
        self.assertNotIn("ipv4_allow_list", response)
        self.assertNotIn("Role", self.secrets[f"{SECRET_PREFIX}example-user"])
        self.assertNotIn("Policy", self.secrets[f"{SECRET_PREFIX}example-user"])

    def test_ssh_authentication_returns_keys(self):
        self.add_user_secret()

        response = self.handler.lambda_handler(self.event(password=""), None)

        self.assertEqual(["ssh-ed25519 AAAATEST"], response["PublicKeys"])

    def test_secret_cannot_override_terraform_authorisation(self):
        self.add_user_secret(
            self.user_record(
                Role="arn:aws:iam::123456789012:role/untrusted",
                Policy="untrusted-policy",
                HomeDirectoryDetails=[{"Entry": "/", "Target": "/untrusted"}],
            )
        )

        response = self.handler.lambda_handler(self.event(), None)

        self.assertEqual(TRANSFER_ROLE_ARN, response["Role"])
        self.assertEqual(TRANSFER_SESSION_POLICY, response["Policy"])
        self.assertEqual(
            '[{"Entry": "/", "Target": "/integration-hub-file-transfer-development-incoming/example-user"}]',
            response["HomeDirectoryDetails"],
        )

    def test_invalid_home_directory_configuration_is_denied(self):
        self.add_user_secret()
        invalid_configurations = [
            "not-json",
            "{}",
            "[]",
            '[{"Entry": "/"}]',
            '[{"Entry": 1, "Target": "/bucket/example-user"}]',
        ]

        for configuration in invalid_configurations:
            with self.subTest(configuration=configuration):
                with patch.object(self.handler, "TRANSFER_HOME_DIRECTORY_DETAILS", configuration):
                    self.assertEqual({}, self.handler.lambda_handler(self.event(), None))

    def test_wrong_or_missing_password_is_denied(self):
        self.add_user_secret()

        self.assertEqual({}, self.handler.lambda_handler(self.event(password="wrong"), None))
        self.secrets[f"{SECRET_PREFIX}example-user"] = self.user_record(password=None, publicKeys=[])
        self.assertEqual({}, self.handler.lambda_handler(self.event(password="super-secret"), None))

    def test_user_restrictions_are_enforced(self):
        self.add_user_secret(
            self.user_record(
                ipv4_allow_list=["192.0.2.0/24"],
                server_id_allow_list=["s-1234567890abcdef0"],
            )
        )

        self.assertNotEqual({}, self.handler.lambda_handler(self.event(), None))
        self.assertEqual({}, self.handler.lambda_handler(self.event(sourceIp="198.51.100.10"), None))
        self.assertEqual({}, self.handler.lambda_handler(self.event(serverId="s-other"), None))

    def test_invalid_or_missing_user_record_is_denied(self):
        self.assertEqual({}, self.handler.lambda_handler(self.event(), None))
        self.add_user_secret(self.user_record(username="another-user"))
        self.assertEqual({}, self.handler.lambda_handler(self.event(), None))
        self.secrets[f"{SECRET_PREFIX}example-user"] = self.user_record(publicKeys="not-a-list")
        self.assertEqual({}, self.handler.lambda_handler(self.event(), None))

    def test_rejects_request_without_source_ip(self):
        with self.assertRaisesRegex(self.handler.AuthenticationError, "Source IP is missing"):
            self.handler.validate_request_context(
                {"serverId": "s-1234567890abcdef0"},
                "example-user",
                self.user_record(),
            )

    def test_accepts_source_ip_in_canonical_cidr(self):
        self.assertTrue(self.handler.ip_in_cidr_list("192.0.2.10", ["192.0.2.0/24"]))

    def test_rejects_invalid_source_ip(self):
        self.assertFalse(self.handler.ip_in_cidr_list("not-an-ip-address", ["192.0.2.0/24"]))

    def test_rejects_invalid_source_ip_when_allow_list_is_empty(self):
        self.assertFalse(self.handler.ip_in_cidr_list("not-an-ip-address", []))

    def test_rejects_non_canonical_cidr(self):
        self.assertFalse(self.handler.ip_in_cidr_list("192.0.2.10", ["192.0.2.1/24"]))


if __name__ == "__main__":
    unittest.main()