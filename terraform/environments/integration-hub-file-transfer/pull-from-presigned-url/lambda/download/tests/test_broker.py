import copy
import unittest
from unittest.mock import Mock
from broker import AccessDenied, issue

ID = "a" * 64
CONFIG = {"sso": {"groups_claim": "groups"}, "pickup_bucket": "pickup",
          "recipients": {"team": {"prefix": "team/", "principals": {"group": {"type": "GROUP", "id": "group-1"}}}}}
EVENT = {"routeKey": "POST /pickups/{id}/download", "pathParameters": {"id": ID},
         "requestContext": {"authorizer": {"jwt": {"claims": {"sub": "user-1", "groups": '["group-1"]'}}}}}
ITEM = {"recipientId": "team", "bucket": "pickup", "key": ID, "versionId": "retained-v1",
        "source": {"key": "team/file.txt"}, "collectUntil": 1000}


class BrokerTests(unittest.TestCase):
    def setUp(self):
        self.table = Mock(); self.s3 = Mock()
        self.table.get_item.return_value = {"Item": copy.deepcopy(ITEM)}
        self.s3.generate_presigned_url.return_value = "https://pickup.s3.eu-west-2.amazonaws.com/file?signature=secret"

    def run_request(self, event=None, config=None, now=100):
        return issue(event or EVENT, config or CONFIG, self.table, self.s3, lambda: now)

    def test_authorised_user_gets_exact_version_and_five_minutes(self):
        self.assertEqual(self.run_request()["expiresIn"], 300)
        args = self.s3.generate_presigned_url.call_args.kwargs
        self.assertEqual(args["Params"]["VersionId"], "retained-v1")
        self.assertEqual(args["Params"]["Bucket"], "pickup")
        self.assertEqual(args["Params"]["ResponseContentDisposition"], "attachment")
        self.assertTrue(self.table.get_item.call_args.kwargs["ConsistentRead"])

    def test_forwarded_link_denied_for_other_user(self):
        event = copy.deepcopy(EVENT)
        event["requestContext"]["authorizer"]["jwt"]["claims"]["groups"] = '["group-10"]'
        with self.assertRaises(AccessDenied): self.run_request(event)
        self.s3.generate_presigned_url.assert_not_called()

    def test_unverified_header_and_missing_authorizer_denied(self):
        event = copy.deepcopy(EVENT); event["requestContext"] = {}
        event["headers"] = {"Authorization": "Bearer fake"}
        with self.assertRaises(AccessDenied): self.run_request(event)
        self.table.get_item.assert_not_called()

    def test_malformed_and_overage_groups_fail_closed(self):
        for value in ('group-1', '{"group-1":true}', '[1]', ''):
            event = copy.deepcopy(EVENT)
            event["requestContext"]["authorizer"]["jwt"]["claims"]["groups"] = value
            with self.subTest(value=value), self.assertRaises(AccessDenied): self.run_request(event)

    def test_explicit_subject_supported_without_group_membership(self):
        config = copy.deepcopy(CONFIG)
        config["recipients"]["team"]["principals"] = {"user": {"type": "USER", "id": "user-1"}}
        self.assertEqual(self.run_request(config=config)["expiresIn"], 300)
        config["recipients"]["team"]["principals"]["user"]["id"] = "user-2"
        with self.assertRaises(AccessDenied): self.run_request(config=config)

    def test_revoked_recipient_or_changed_prefix_denied(self):
        for recipients in ({}, {"team": {**CONFIG["recipients"]["team"], "prefix": "other/"}}):
            config = copy.deepcopy(CONFIG); config["recipients"] = recipients
            with self.assertRaises(AccessDenied): self.run_request(config=config)

    def test_expiry_enforced_even_before_s3_or_dynamodb_cleanup(self):
        self.assertEqual(self.run_request(now=990)["expiresIn"], 10)
        with self.assertRaises(AccessDenied): self.run_request(now=1000)
        with self.assertRaises(AccessDenied): self.run_request(now=1001)

    def test_wrong_bucket_key_or_missing_version_denied(self):
        for key, value in (("bucket", "clean"), ("key", "other"), ("versionId", ""), ("versionId", "null")):
            item = copy.deepcopy(ITEM); item[key] = value
            self.table.get_item.return_value = {"Item": item}
            with self.assertRaises(AccessDenied): self.run_request()
        self.s3.generate_presigned_url.assert_not_called()

    def test_missing_receipt_and_invalid_id_denied(self):
        self.table.get_item.return_value = {}
        with self.assertRaises(AccessDenied): self.run_request()
        event = copy.deepcopy(EVENT); event["pathParameters"]["id"] = "../other"
        with self.assertRaises(AccessDenied): self.run_request(event)

    def test_request_cannot_override_object_or_url_duration(self):
        event = copy.deepcopy(EVENT)
        event["body"] = '{"bucket":"other", "expiresIn":86400}'
        self.assertEqual(self.run_request(event)["expiresIn"], 300)
        self.assertEqual(self.s3.generate_presigned_url.call_args.kwargs["Params"]["Bucket"], "pickup")

    def test_retry_checks_current_authorisation_again(self):
        self.run_request()
        config = copy.deepcopy(CONFIG); config["recipients"] = {}
        with self.assertRaises(AccessDenied): self.run_request(config=config)
        self.assertEqual(self.s3.generate_presigned_url.call_count, 1)
