import copy
import importlib.util
import json
import os
from pathlib import Path
import unittest
from unittest.mock import Mock, patch

import boto3
import requests


with patch.object(boto3, "client"):
    spec = importlib.util.spec_from_file_location(
        "aws_securityhub_handler", Path(__file__).with_name("handler.py")
    )
    handler = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(handler)


class HandlerTests(unittest.TestCase):
    def setUp(self):
        environment = patch.dict(
            os.environ,
            {
                "FINDING_SEVERITY_LABELS": '["CRITICAL"]',
                "IGNORE_FINDINGS": "{}",
                "WEB_IDENTITY_AUDIENCE": "octo-sts.dev",
                "WEB_IDENTITY_DURATION_SECONDS": "600",
                "WEB_IDENTITY_SIGNING_ALGORITHM": "RS256",
                "GITHUB_ORG": "org",
                "GITHUB_IDENTITY": "securityhub",
                "GITHUB_REPO": "repo",
            },
            clear=True,
        )
        environment.start()
        self.addCleanup(environment.stop)
        self.finding = {
            "Id": "finding-id",
            "Title": "Public access is enabled",
            "Description": "A resource allows public access.",
            "AwsAccountId": "test-account",
            "Region": "eu-west-2",
            "Severity": {"Label": "CRITICAL"},
            "Types": ["Software and Configuration Checks/Industry and Regulatory Standards"],
            "Resources": [{"Type": "AwsS3Bucket", "Id": "bucket-name"}],
            "Remediation": {
                "Recommendation": {"Text": "Restrict access to the bucket."}
            },
        }
        self.event = {
            "detail-type": "Security Hub Findings - Imported",
            "detail": {"findings": [copy.deepcopy(self.finding)]},
        }

    def test_issue_contains_securityhub_finding_details(self):
        issue = handler.build_github_issue(self.finding)
        self.assertEqual(
            issue["title"], "[CRITICAL] Public access is enabled - test-account"
        )
        self.assertEqual(issue["labels"], ["support", "aws_securityhub_finding"])
        for value in (
            "## Severity\nCRITICAL",
            "## Account\ntest-account",
            "## Region\neu-west-2",
            "A resource allows public access.",
            "Software and Configuration Checks/Industry and Regulatory Standards",
            '"Type": "AwsS3Bucket"',
            "Restrict access to the bucket.",
            "finding-id",
        ):
            self.assertIn(value, issue["body"])

    @patch.object(handler, "create_github_issue")
    @patch.object(handler, "get_github_token", return_value="github-token")
    @patch.object(handler, "get_web_identity_token", return_value=("web-token", None))
    def test_creates_one_issue_per_matching_finding(
        self, get_web_token, get_github_token, create_issue
    ):
        self.event["detail"]["findings"].append(
            {
                **copy.deepcopy(self.finding),
                "Id": "another-finding",
                "Title": "High severity finding",
                "Severity": {"Label": "HIGH"},
            }
        )
        self.event["detail"]["findings"].append(
            {
                **copy.deepcopy(self.finding),
                "Id": "low-finding",
                "Severity": {"Label": "LOW"},
            }
        )
        os.environ["FINDING_SEVERITY_LABELS"] = '["CRITICAL", "HIGH"]'
        create_issue.side_effect = [
            {"number": 41, "html_url": "https://example/issues/41"},
            {"number": 42, "html_url": "https://example/issues/42"},
        ]

        result = handler.lambda_handler(self.event, None)

        self.assertEqual(result["statusCode"], 200)
        self.assertEqual(
            json.loads(result["body"])["issues"],
            [
                {"issue_number": 41, "issue_url": "https://example/issues/41"},
                {"issue_number": 42, "issue_url": "https://example/issues/42"},
            ],
        )
        self.assertEqual(create_issue.call_count, 2)
        get_web_token.assert_called_once_with(
            audience="octo-sts.dev",
            duration_seconds=600,
            signing_algorithm="RS256",
        )
        get_github_token.assert_called_once_with(
            audience="octo-sts.dev",
            github_org="org",
            identity="securityhub",
            repo="repo",
            web_identity_token="web-token",
        )
        self.assertEqual(
            [call.kwargs["issue"]["title"] for call in create_issue.call_args_list],
            [
                "[CRITICAL] Public access is enabled - test-account",
                "[HIGH] High severity finding - test-account",
            ],
        )

    @patch.object(handler, "create_github_issue")
    @patch.object(handler, "get_github_token")
    @patch.object(handler, "get_web_identity_token")
    def test_severity_mismatch_logs_and_exits_without_authentication(
        self, get_web_token, get_github_token, create_issue
    ):
        self.event["detail"]["findings"][0]["Severity"]["Label"] = "HIGH"

        with self.assertLogs(handler.logger, level="INFO") as logs:
            result = handler.lambda_handler(self.event, None)

        self.assertEqual(result["statusCode"], 200)
        self.assertIn(
            "No Security Hub findings matched", json.loads(result["body"])["message"]
        )
        self.assertIn("severity HIGH", "\n".join(logs.output))
        get_web_token.assert_not_called()
        get_github_token.assert_not_called()
        create_issue.assert_not_called()

    @patch.object(handler, "create_github_issue")
    @patch.object(handler, "get_github_token")
    @patch.object(handler, "get_web_identity_token")
    def test_unknown_or_missing_severity_is_skipped(
        self, get_web_token, get_github_token, create_issue
    ):
        for label in ("LOW", None):
            with self.subTest(label=label):
                finding = copy.deepcopy(self.finding)
                if label is None:
                    finding["Severity"] = {}
                else:
                    finding["Severity"]["Label"] = label
                self.event["detail"]["findings"] = [finding]
                result = handler.lambda_handler(self.event, None)
                self.assertEqual(result["statusCode"], 200)
        get_web_token.assert_not_called()
        get_github_token.assert_not_called()
        create_issue.assert_not_called()

    def test_empty_findings_are_a_graceful_no_op(self):
        self.event["detail"]["findings"] = []

        result = handler.lambda_handler(self.event, None)

        self.assertEqual(result["statusCode"], 200)
        self.assertIn(
            "No Security Hub findings matched", json.loads(result["body"])["message"]
        )

    @patch.object(handler.requests, "post")
    def test_create_issue_uses_exchanged_github_token(self, post):
        post.return_value = Mock(
            status_code=201,
            json=Mock(return_value={"number": 42, "html_url": "https://example/42"}),
        )

        result = handler.create_github_issue(
            "org", "github-token", "repo", handler.build_github_issue(self.finding)
        )

        self.assertEqual(result["number"], 42)
        self.assertEqual(
            post.call_args.kwargs["headers"]["Authorization"],
            "Bearer " + "github-token",
        )
        self.assertEqual(
            post.call_args.args[0], "https://api.github.com/repos/org/repo/issues"
        )

    def test_invalid_severity_configuration_fails_explicitly(self):
        for value in ("not-json", "[]", '["URGENT"]', '["CRITICAL", 1]'):
            with self.subTest(value=value):
                os.environ["FINDING_SEVERITY_LABELS"] = value
                with self.assertLogs(handler.logger, level="ERROR"):
                    with self.assertRaisesRegex(ValueError, "FINDING_SEVERITY_LABELS"):
                        handler.lambda_handler(self.event, None)

    def test_severity_configuration_defaults_to_critical(self):
        os.environ.pop("FINDING_SEVERITY_LABELS")

        self.assertEqual(handler.get_finding_severity_labels(), {"CRITICAL"})

    def test_matching_ignored_finding_does_not_create_issue(self):
        os.environ["IGNORE_FINDINGS"] = json.dumps(
            {"test-account": "A resource allows public access"}
        )
        with patch.object(handler, "get_web_identity_token") as get_web_token:
            with self.assertLogs(handler.logger, level="INFO") as logs:
                result = handler.lambda_handler(self.event, None)

        self.assertEqual(result["statusCode"], 200)
        self.assertIn(
            "All matching Security Hub findings were ignored",
            json.loads(result["body"])["message"],
        )
        self.assertIn("Skipping ignored Security Hub finding", "\n".join(logs.output))
        get_web_token.assert_not_called()

    def test_invalid_event_shape_fails_explicitly(self):
        for event in ([], {}, {"detail": {"findings": {}}}):
            with self.subTest(event=event):
                with self.assertRaises(ValueError):
                    handler.lambda_handler(event, None)

    @patch.object(handler, "create_github_issue")
    @patch.object(handler, "get_github_token", return_value="github-token")
    @patch.object(handler, "get_web_identity_token", return_value=("web-token", None))
    def test_matching_finding_calls_github_issue_creation(
        self, get_web_token, get_github_token, create_issue
    ):
        create_issue.return_value = {"number": 42, "html_url": "https://example/42"}

        result = handler.lambda_handler(self.event, None)

        self.assertEqual(result["statusCode"], 200)
        create_issue.assert_called_once()
        get_web_token.assert_called_once()
        get_github_token.assert_called_once()

    @patch.object(handler.requests, "post")
    def test_github_issue_api_errors_are_reported(self, post):
        post.return_value = Mock(status_code=403, text="Forbidden")
        post.return_value.raise_for_status.side_effect = requests.HTTPError("Forbidden")

        with self.assertRaisesRegex(RuntimeError, "GitHub issue creation request failed"):
            handler.create_github_issue(
                "org", "github-token", "repo", handler.build_github_issue(self.finding)
            )


if __name__ == "__main__":
    unittest.main()
