import base64
import gzip
import importlib.util
import io
import json
import pathlib
import unittest


MODULE_PATH = pathlib.Path(__file__).resolve().parents[1] / "lambda_function.py"
SPEC = importlib.util.spec_from_file_location("oracle_log_lambda", MODULE_PATH)
oracle_log_lambda = importlib.util.module_from_spec(SPEC)
assert SPEC.loader is not None
SPEC.loader.exec_module(oracle_log_lambda)


class OracleLogLambdaTests(unittest.TestCase):
    def test_decode_cloudwatch_logs_payload(self):
        payload = {"messageType": "DATA_MESSAGE", "logEvents": [{"id": "1", "timestamp": 1710000000000, "message": "ORA-12345 failed"}]}
        compressed = gzip.compress(json.dumps(payload).encode("utf-8"))
        encoded_data = base64.b64encode(compressed).decode("utf-8")

        decoded = oracle_log_lambda.decode_cloudwatch_logs_payload(encoded_data)

        self.assertEqual(decoded["logEvents"][0]["message"], "ORA-12345 failed")

    def test_extract_ora_events_from_log_payload(self):
        payload = {
            "logGroup": "/aws/rds/instance",
            "logStream": "alertlog",
            "logEvents": [
                {"timestamp": 1710000000000, "message": "Errors in file /tmp/alert.log: ORA-12345"},
                {"timestamp": 1710000000001, "message": "No issues here"},
            ],
        }

        events = oracle_log_lambda.extract_ora_events_from_log_payload(payload)

        self.assertEqual(len(events), 1)
        self.assertEqual(events[0]["codes"], ["ORA-12345"])
        self.assertEqual(events[0]["logStream"], "alertlog")

    def test_decode_cloudwatch_logs_payload_raises_on_malformed_payload(self):
        malformed_data = "not-valid-base64-data"

        with self.assertRaises(Exception):
            oracle_log_lambda.decode_cloudwatch_logs_payload(malformed_data)


if __name__ == "__main__":
    unittest.main()
