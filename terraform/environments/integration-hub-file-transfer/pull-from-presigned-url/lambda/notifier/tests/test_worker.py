import copy
import json
import unittest
from unittest.mock import Mock, patch
from worker import InvalidNotification, Store, message, post_slack, process

NOW = 1790762400
SECRET = "arn:aws:secretsmanager:eu-west-2:123456789012:secret:dispatch-abcdef"
CONFIG = {"account": "123456789012", "queue_arn": "queue", "topic_arn": "topic",
          "clean_bucket": "clean", "portal_url": "https://web.development.file-transfer.service.justice.gov.uk",
          "pickup_bucket": "pickup", "pickup_kms_key": "key", "routes": {SECRET: {"prefix": "products-poc/uploads/", "recipient_id": "products",
                               "webhook_secret_arn": "webhook-secret"}}}
DATA = {"actionExecutionId": "8f2f1df5-a54d-4852-be34-a75781f80418",
        "fileId": "8f2f1df5-a54d-4852-be34-a75781f80419", "requestedAt": "2026-09-30T10:00:00Z",
        "notifications": ["slack"], "configurationReference": {"secretArn": SECRET, "secretVersionId": "version1"},
        "object": {"bucket": "clean", "key": "products-poc/uploads/test.txt", "versionId": "object-v1", "sizeBytes": 5}}


def record(data=None):
    event = {"source": "uk.gov.justice.service.managed-file-transfer", "account": CONFIG["account"],
             "region": "eu-west-2", "detail-type": "FileActionExecutionRequested.v1", "detail": {"data": data or copy.deepcopy(DATA)}}
    return {"eventSource": "aws:sqs", "eventSourceARN": "queue", "messageId": "message1",
            "body": json.dumps({"Type": "Notification", "TopicArn": "topic", "Message": json.dumps(event)})}


class WorkerTests(unittest.TestCase):
    def setUp(self):
        self.store = Mock()
        self.store.claim.return_value = True
        self.secrets = Mock()
        self.secrets.get_secret_value.side_effect = [
            {"SecretString": json.dumps({"notifications": {"slack": "products"}})},
            {"SecretString": json.dumps({"url": "https://hooks.slack.com/services/T/B/credential"})}]
        self.send = Mock()
        self.retainer = Mock()
        self.retainer.prepare.return_value = {"bucket": "pickup", "key": "products/execution/test.txt"}

    def run_record(self, rec=None, config=None):
        return process(rec or record(), config or CONFIG, self.store, self.secrets, self.send, lambda: NOW, self.retainer)

    def test_sends_only_portal_link_and_reads_exact_dispatch_version(self):
        self.assertEqual(self.run_record(), "sent")
        self.assertEqual(self.secrets.get_secret_value.call_args_list[0].kwargs,
                         {"SecretId": SECRET, "VersionId": "version1"})
        payload = self.send.call_args.args[1]
        self.assertEqual(payload["blocks"][2]["elements"][0]["url"], CONFIG["portal_url"])
        self.assertIn("pickup/products/execution/test.txt", payload["blocks"][1]["text"]["text"])
        self.retainer.prepare.assert_called_once()
        self.assertNotIn("X-Amz", json.dumps(payload))
        self.assertNotIn("credential", json.dumps(payload))
        self.store.complete.assert_called_once()

    def test_untrusted_objects_rejected_before_secret_read(self):
        for change in ({"bucket": "quarantine"}, {"bucket": "investigation"}, {"versionId": ""}, {"versionId": "null"}, {"versionId": 1},
                       {"key": "products-poc/uploads-other/test.txt"}, {"key": "another-client/test.txt"}):
            with self.subTest(change=change):
                data = copy.deepcopy(DATA); data["object"].update(change)
                with self.assertRaises(InvalidNotification): self.run_record(record(data))
        self.secrets.get_secret_value.assert_not_called()
        self.send.assert_not_called()

    def test_failed_copy_does_not_notify(self):
        self.retainer.prepare.side_effect = RuntimeError("Copy failed")
        with self.assertRaises(RuntimeError): self.run_record()
        self.send.assert_not_called()
        self.store.complete.assert_not_called()

    def test_unknown_secret_rejected(self):
        data = copy.deepcopy(DATA); data["configurationReference"]["secretArn"] = SECRET + "-other"
        with self.assertRaises(InvalidNotification): self.run_record(record(data))
        self.secrets.get_secret_value.assert_not_called()

    def test_wrong_recipient_rejected(self):
        self.secrets.get_secret_value.side_effect = [{"SecretString": json.dumps({"notifications": {"slack": "other"}})}]
        with self.assertRaises(InvalidNotification): self.run_record()
        self.store.claim.assert_not_called()

    def test_duplicate_not_sent_twice(self):
        self.store.claim.return_value = False
        self.assertEqual(self.run_record(), "duplicate")
        self.send.assert_not_called()
        self.assertEqual(self.secrets.get_secret_value.call_count, 1)

    def test_stale_event_not_sent(self):
        data = copy.deepcopy(DATA); data["requestedAt"] = "2026-09-28T10:00:00Z"
        self.assertEqual(self.run_record(record(data)), "expired")
        self.secrets.get_secret_value.assert_not_called()

    def test_future_event_rejected(self):
        data = copy.deepcopy(DATA); data["requestedAt"] = "2026-10-30T10:00:00Z"
        with self.assertRaises(InvalidNotification): self.run_record(record(data))

    def test_sender_failure_does_not_mark_sent(self):
        self.send.side_effect = TimeoutError()
        with self.assertRaises(TimeoutError): self.run_record()
        self.store.complete.assert_not_called()

    def test_wrong_transport_rejected(self):
        rec = record(); rec["eventSourceARN"] = "other"
        with self.assertRaises(InvalidNotification): self.run_record(rec)
        rec = record(); envelope = json.loads(rec["body"]); envelope["TopicArn"] = "other"; rec["body"] = json.dumps(envelope)
        with self.assertRaises(InvalidNotification): self.run_record(rec)
        self.secrets.get_secret_value.assert_not_called()

    def test_wrong_account_and_event_type_rejected(self):
        for field,value in [("account","other"),("detail-type","FileRouted.v1"),("source","other"),("region","us-east-1")]:
            rec=record(); envelope=json.loads(rec["body"]); event=json.loads(envelope["Message"])
            event[field]=value; envelope["Message"]=json.dumps(event); rec["body"]=json.dumps(envelope)
            with self.assertRaises(InvalidNotification): self.run_record(rec)

    def test_portal_cannot_be_overridden_to_attacker_host(self):
        config=copy.deepcopy(CONFIG); config["portal_url"]="https://evil.invalid/"
        with self.assertRaises(InvalidNotification): self.run_record(config=config)

    def test_filename_is_plain_text(self):
        data=copy.deepcopy(DATA); data["object"]["key"]="products-poc/uploads/<https://evil.invalid|click> <!channel>"
        payload=message(data,CONFIG["portal_url"], {"bucket": "pickup", "key": data["object"]["key"]})
        self.assertEqual(payload["blocks"][1]["text"]["type"],"plain_text")
        self.assertFalse(payload["unfurl_links"])

    def test_webhook_ssrf_blocked(self):
        for url in ("http://hooks.slack.com/services/T/B/C", "https://evil.invalid/services/T/B/C",
                    "https://hooks.slack.com.evil.invalid/services/T/B/C", "https://hooks.slack.com/services/T/B/C?redirect=evil"):
            with self.assertRaises(InvalidNotification): post_slack(url,{})

    def test_redirect_handler_refuses_redirects(self):
        from worker import NoRedirect
        self.assertIsNone(NoRedirect().redirect_request(None,None,302,"",{},"https://evil.invalid"))

    def test_store_retries_in_progress_but_acknowledges_sent(self):
        class ConditionalError(Exception):
            response={"Error":{"Code":"ConditionalCheckFailedException"}}
        table=Mock(); table.put_item.side_effect=ConditionalError()
        table.get_item.return_value={"Item":{"status":"IN_PROGRESS"}}
        with self.assertRaises(RuntimeError): Store(table).claim("key", NOW)
        table.get_item.return_value={"Item":{"status":"SENT"}}
        self.assertFalse(Store(table).claim("key",NOW))
        self.assertTrue(table.get_item.call_args.kwargs["ConsistentRead"])

class HandlerTests(unittest.TestCase):
    def test_partial_batch_failure_and_no_secret_in_logs(self):
        import importlib.util
        import io
        from contextlib import redirect_stdout
        from pathlib import Path
        import sys
        boto = Mock()
        with patch.dict(sys.modules, {"boto3": boto, "botocore": Mock(), "botocore.config": Mock()}), patch.dict(
                "os.environ", {"CONFIG": json.dumps(CONFIG), "IDEMPOTENCY_TABLE": "test"}):
            spec=importlib.util.spec_from_file_location("notifier_test_handler",Path(__file__).parents[1]/"handler.py")
            handler=importlib.util.module_from_spec(spec);spec.loader.exec_module(handler)
        output=io.StringIO()
        with patch.object(handler,"process",side_effect=["sent",RuntimeError("https://hooks.slack.com/services/SECRET")]), redirect_stdout(output):
            result=handler.lambda_handler({"Records":[{"messageId":"ok"},{"messageId":"retry"}]},Mock())
        self.assertEqual(result,{"batchItemFailures":[{"itemIdentifier":"retry"}]})
        self.assertNotIn("SECRET",output.getvalue())
