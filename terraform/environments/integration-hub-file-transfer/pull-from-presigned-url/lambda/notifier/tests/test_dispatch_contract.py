import importlib.util
import json
from pathlib import Path
import sys
import unittest
from unittest.mock import Mock

from test_worker import CONFIG, DATA, NOW, SECRET, record
from worker import process

path = Path(__file__).resolve().parents[4] / "lambda/file-action-execution-requested-adapter/dispatcher.py"
spec = importlib.util.spec_from_file_location("pickup_dispatch_contract", path)
dispatcher = importlib.util.module_from_spec(spec)
sys.modules[spec.name] = dispatcher
spec.loader.exec_module(dispatcher)


class DispatchContractTests(unittest.TestCase):
    def test_real_dispatcher_and_notifier_accept_same_destination(self):
        secret = {"ARN": SECRET, "VersionId": "version1", "SecretString": json.dumps({
            "action": None, "notifications": {"slack": "products", "email": None, "teams": None}})}
        configuration = dispatcher.parse_dispatch_configuration(secret)
        self.assertIn("slack", configuration.notifications)
        secrets = Mock()
        secrets.get_secret_value.side_effect = [secret, {"SecretString": '{"url":"https://hooks.slack.com/services/T/B/C"}'}]
        retainer = Mock()
        retainer.prepare.return_value = {"bucket": "pickup", "key": "products/execution/test.txt"}
        send = Mock()
        self.assertEqual(process(record(), CONFIG, Mock(), secrets, send, lambda: NOW, retainer), "sent")
        send.assert_called_once()

    def test_legacy_object_destination_is_rejected_by_dispatcher(self):
        with self.assertRaises(ValueError):
            dispatcher.parse_dispatch_configuration({"ARN": SECRET, "VersionId": "version1", "SecretString": json.dumps({
                "action": None, "notifications": {"slack": {"type": "authenticated-pickup", "recipient": "products"}}})})
