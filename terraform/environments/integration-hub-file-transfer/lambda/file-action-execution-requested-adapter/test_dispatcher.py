import json
import unittest
from datetime import datetime, timezone
from types import SimpleNamespace
from unittest.mock import MagicMock

from dispatcher import (
    build_requested_event_detail,
    find_dispatch_configuration,
    parse_dispatch_configuration,
    parse_file_routed_event,
    secret_name_candidates,
)


ACCOUNT_ID = "123456789012"
CLEAN_BUCKET = "integration-hub-file-transfer-development-clean"


class SecretNotFoundError(Exception):
    def __init__(self):
        self.response = {"Error": {"Code": "ResourceNotFoundException"}}


class DispatcherTest(unittest.TestCase):
    def setUp(self):
        self.event = {
            "id": "aa88e95a-159c-40c1-9e7b-38d00b0b6169",
            "detail-type": "FileRouted.v1",
            "source": "uk.gov.justice.service.managed-file-transfer",
            "account": ACCOUNT_ID,
            "detail": {
                "metadata": {
                    "correlationId": "7d9f4e4c-0e0f-4a5b-8b4e-4ab1f28fd1d1",
                    "idempotencyKey": (
                        f"route:clean:{CLEAN_BUCKET}:identity/reports/test.csv:version"
                    ),
                },
                "data": {
                    "fileId": "3f4e3d7a-4e2f-4bc2-9c4e-5f1ef2d4c501",
                    "route": "clean",
                    "destinationObject": {
                        "bucket": CLEAN_BUCKET,
                        "key": "identity/reports/test.csv",
                        "versionId": "version",
                        "sizeBytes": 4096,
                    },
                },
            },
        }
        self.secret_response = {
            "ARN": "arn:aws:secretsmanager:eu-west-2:123456789012:secret:identity/reports/",
            "VersionId": "secret-version",
            "SecretString": json.dumps(
                {
                    "action": {
                        "name": "place-on-sqs",
                        "queueArn": "sensitive-queue-arn",
                    },
                    "notifications": {
                        "email": "sensitive-recipient",
                        "slack": None,
                        "teams": "sensitive-webhook",
                    },
                }
            ),
        }

    def test_generates_exact_then_slash_boundary_candidates(self):
        self.assertEqual(
            secret_name_candidates("identity/group/reports/test.csv"),
            [
                "identity/group/reports/test.csv",
                "identity/group/reports/",
                "identity/group/",
                "identity/",
            ],
        )

    def test_returns_first_matching_configuration(self):
        secret_client = MagicMock()
        secret_client.get_secret_value.side_effect = [
            SecretNotFoundError(),
            self.secret_response,
        ]

        configuration = find_dispatch_configuration(
            secret_client, "application/file-dispatch/", "identity/reports/test.csv"
        )

        self.assertEqual(configuration.secret_version_id, "secret-version")
        self.assertEqual(
            [call.kwargs["SecretId"] for call in secret_client.get_secret_value.call_args_list],
            [
                "application/file-dispatch/identity/reports/test.csv",
                "application/file-dispatch/identity/reports/",
            ],
        )

    def test_returns_none_when_no_secret_matches(self):
        secret_client = MagicMock()
        secret_client.get_secret_value.side_effect = SecretNotFoundError()

        configuration = find_dispatch_configuration(
            secret_client, "application/file-dispatch/", "identity/reports/test.csv"
        )

        self.assertIsNone(configuration)

    def test_propagates_non_not_found_secret_errors(self):
        secret_client = MagicMock()
        secret_client.get_secret_value.side_effect = PermissionError("denied")

        with self.assertRaises(PermissionError):
            find_dispatch_configuration(
                secret_client, "application/file-dispatch/", "identity/report.csv"
            )

    def test_rejects_malformed_secret_configuration(self):
        self.secret_response["SecretString"] = "not-json"

        with self.assertRaisesRegex(ValueError, "valid JSON"):
            parse_dispatch_configuration(self.secret_response)

    def test_builds_deterministic_events_without_sensitive_values(self):
        routed_file = parse_file_routed_event(self.event)
        configuration = parse_dispatch_configuration(self.secret_response)
        requested_at = datetime(2026, 8, 19, 12, 30, tzinfo=timezone.utc)

        first = build_requested_event_detail(
            routed_file, configuration, requested_at=requested_at
        )
        second = build_requested_event_detail(
            routed_file, configuration, requested_at=requested_at
        )

        self.assertEqual(first, second)
        detail = first
        execution_id = detail["data"]["actionExecutionId"]
        self.assertEqual(
            detail["metadata"]["idempotencyKey"], f"action-request:{execution_id}"
        )
        self.assertEqual(
            detail["data"]["configurationReference"],
            {
                "secretArn": self.secret_response["ARN"],
                "secretVersionId": "secret-version",
            },
        )
        self.assertEqual(detail["data"]["action"], {"name": "place-on-sqs"})
        self.assertEqual(detail["data"]["notifications"], ["email", "teams"])
        self.assertNotIn("sensitive-queue-arn", json.dumps(detail))
        self.assertNotIn("sensitive-recipient", json.dumps(detail))
        self.assertNotIn("sensitive-webhook", json.dumps(detail))

    def test_changed_secret_version_changes_execution_id(self):
        routed_file = parse_file_routed_event(self.event)
        first_configuration = parse_dispatch_configuration(self.secret_response)
        self.secret_response["VersionId"] = "new-secret-version"
        second_configuration = parse_dispatch_configuration(self.secret_response)

        first = build_requested_event_detail(routed_file, first_configuration)
        second = build_requested_event_detail(routed_file, second_configuration)

        self.assertNotEqual(
            first["data"]["actionExecutionId"],
            second["data"]["actionExecutionId"],
        )

    def test_all_null_configuration_is_a_successful_no_op(self):
        self.secret_response["SecretString"] = json.dumps(
            {
                "action": None,
                "notifications": {"email": None, "slack": None, "teams": None},
            }
        )

        configuration = parse_dispatch_configuration(self.secret_response)
        routed_file = parse_file_routed_event(self.event)

        self.assertIsNone(configuration.action_name)
        self.assertEqual(configuration.notifications, ())
        self.assertIsNone(build_requested_event_detail(routed_file, configuration))

    def test_builds_notification_only_event(self):
        self.secret_response["SecretString"] = json.dumps(
            {
                "action": None,
                "notifications": {
                    "email": "sensitive-recipient",
                    "slack": None,
                    "teams": None,
                },
            }
        )

        configuration = parse_dispatch_configuration(self.secret_response)
        routed_file = parse_file_routed_event(self.event)
        detail = build_requested_event_detail(routed_file, configuration)

        self.assertNotIn("action", detail["data"])
        self.assertEqual(detail["data"]["notifications"], ["email"])

    def test_rejects_action_without_a_name(self):
        self.secret_response["SecretString"] = json.dumps(
            {
                "action": {"queueArn": "sensitive-queue-arn"},
                "notifications": {"email": None, "slack": None, "teams": None},
            }
        )

        with self.assertRaisesRegex(ValueError, "secret.action.name"):
            parse_dispatch_configuration(self.secret_response)

    def test_rejects_empty_configured_notification_name(self):
        self.secret_response["SecretString"] = json.dumps(
            {
                "action": None,
                "notifications": {"": "sensitive-recipient"},
            }
        )

        with self.assertRaisesRegex(ValueError, "secret.notifications key"):
            parse_dispatch_configuration(self.secret_response)

if __name__ == "__main__":
    unittest.main()