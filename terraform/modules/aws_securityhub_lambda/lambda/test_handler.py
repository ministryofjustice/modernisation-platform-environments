import copy
import importlib.util
import json
import os
from pathlib import Path
import unittest
from unittest.mock import Mock, patch

import boto3
import requests
from botocore.exceptions import ClientError


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
                "VALID_SEVERITY_LABELS": '["INFORMATIONAL", "LOW", "MEDIUM", "HIGH", "CRITICAL"]',
                "RESOURCE_KEYS_TO_EXCLUDE": '["Tags", "Details"]',
                "IGNORE_FINDINGS": "{}",
                "WEB_IDENTITY_AUDIENCE": "octo-sts-example.dev",
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

    def test_resources_exclude_tags_and_details_without_mutating_finding(self):
        self.finding["Resources"] = [
            {
                "Type": "AwsLambdaFunction",
                "Id": "function-arn",
                "Partition": "aws",
                "Region": "eu-west-2",
                "Provider": "AWS",
                "Owner": {"Account": {"Id": "test-account"}},
                "Tags": {"application": "example"},
                "Details": {"AwsLambdaFunction": {"Runtime": "PYTHON_3_13"}},
            },
            {"Type": "AwsS3Bucket", "Id": "bucket-name"},
        ]
        original = copy.deepcopy(self.finding)

        body = handler.build_github_issue(self.finding)["body"]
        resources = json.loads(body.split("```json\n", 1)[1].split("\n```", 1)[0])

        self.assertEqual(
            resources,
            [
                {
                    key: value
                    for key, value in resource.items()
                    if key not in {"Tags", "Details"}
                }
                for resource in original["Resources"]
            ],
        )
        self.assertEqual(self.finding, original)

    def test_resource_exclusions_use_configured_keys(self):
        with patch.dict(os.environ, {"RESOURCE_KEYS_TO_EXCLUDE": '["Id"]'}):
            body = handler.build_github_issue(self.finding)["body"]

        resources = json.loads(body.split("```json\n", 1)[1].split("\n```", 1)[0])
        self.assertEqual(resources, [{"Type": "AwsS3Bucket"}])

    def test_empty_resource_exclusions_preserve_all_resource_keys(self):
        with patch.dict(os.environ, {"RESOURCE_KEYS_TO_EXCLUDE": "[]"}):
            body = handler.build_github_issue(self.finding)["body"]
        resources = json.loads(body.split("```json\n", 1)[1].split("\n```", 1)[0])
        self.assertEqual(resources, self.finding["Resources"])

    def test_invalid_resource_exclusions_are_logged_and_rejected(self):
        for value in ("not-json", "null", "{}", '[""]', '[" "]', "[1]"):
            with self.subTest(value=value):
                with patch.dict(os.environ, {"RESOURCE_KEYS_TO_EXCLUDE": value}):
                    with self.assertLogs(handler.logger, level="ERROR"):
                        with self.assertRaisesRegex(ValueError, "RESOURCE_KEYS_TO_EXCLUDE"):
                            handler.build_github_issue(self.finding)

    def test_allowed_severity_labels_are_loaded_from_environment(self):
        with patch.dict(os.environ, {"VALID_SEVERITY_LABELS": '["HIGH"]'}):
            with self.assertLogs(handler.logger, level="ERROR"):
                with self.assertRaisesRegex(ValueError, "VALID_SEVERITY_LABELS"):
                    handler.get_finding_severity_labels()
            os.environ["FINDING_SEVERITY_LABELS"] = '["HIGH"]'
            self.assertEqual(handler.get_finding_severity_labels(), {"HIGH"})

    def test_invalid_allowed_severities_are_logged_and_rejected(self):
        for value in ("not-json", "null", "{}", "[]", '[""]', "[1]"):
            with self.subTest(value=value):
                with patch.dict(os.environ, {"VALID_SEVERITY_LABELS": value}):
                    with self.assertLogs(handler.logger, level="ERROR"):
                        with self.assertRaisesRegex(ValueError, "VALID_SEVERITY_LABELS"):
                            handler.get_finding_severity_labels()

    def test_resource_exclusions_default_to_tags_and_details(self):
        os.environ.pop("RESOURCE_KEYS_TO_EXCLUDE")
        self.finding["Resources"][0].update({"Tags": {}, "Details": {}})
        body = handler.build_github_issue(self.finding)["body"]
        resources = json.loads(body.split("```json\n", 1)[1].split("\n```", 1)[0])
        self.assertEqual(resources, [{"Type": "AwsS3Bucket", "Id": "bucket-name"}])

    def test_finding_arns_display_only_the_final_identifier(self):
        cases = {
            "arn:aws:inspector2:eu-west-2:test-account:finding/example-id": "example-id",
            "arn:aws:securityhub:eu-west-2:test-account:subscription/standard/control/example-id": "example-id",
            "arn:aws:example:eu-west-2:test-account:finding:example-id": "example-id",
            "plain-finding-id": "plain-finding-id",
            "custom/finding-id": "custom/finding-id",
        }
        for finding_id, expected in cases.items():
            with self.subTest(finding_id=finding_id):
                self.finding["Id"] = finding_id
                body = handler.build_github_issue(self.finding)["body"]
                self.assertEqual(body.split("## Finding ID\n", 1)[1], expected)
                self.assertEqual(self.finding["Id"], finding_id)

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
            audience="octo-sts-example.dev",
            duration_seconds=600,
            signing_algorithm="RS256",
        )
        get_github_token.assert_called_once_with(
            audience="octo-sts-example.dev",
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
        self.assertEqual(
            post.call_args.kwargs["json"], handler.build_github_issue(self.finding)
        )
        self.assertEqual(post.call_args.kwargs["timeout"], 10)
        self.assertEqual(
            post.call_args.kwargs["headers"]["Accept"], "application/vnd.github+json"
        )
        self.assertEqual(
            post.call_args.kwargs["headers"]["X-GitHub-Api-Version"], "2022-11-28"
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

    @patch.object(handler, "sts")
    def test_web_identity_request_and_response(self, sts):
        sts.get_web_identity_token.return_value = {
            "WebIdentityToken": "web-token",
            "Expiration": "expiry",
        }
        self.assertEqual(
            handler.get_web_identity_token("octo-sts-example.dev", 600, "RS256"),
            ("web-token", "expiry"),
        )
        sts.get_web_identity_token.assert_called_once_with(
            Audience=["octo-sts-example.dev"], DurationSeconds=600, SigningAlgorithm="RS256"
        )

    @patch.object(handler, "sts")
    def test_web_identity_errors_are_logged_and_preserve_cause(self, sts):
        for details, expected in (
            ({"Code": "AccessDenied", "Message": "Denied"}, "AccessDenied"),
            ({}, "ClientError"),
        ):
            with self.subTest(details=details):
                error = ClientError({"Error": details}, "GetWebIdentityToken")
                sts.get_web_identity_token.side_effect = error
                with self.assertLogs(handler.logger, level="ERROR"):
                    with self.assertRaisesRegex(RuntimeError, expected) as raised:
                        handler.get_web_identity_token("octo-sts-example.dev", 600, "RS256")
                self.assertIs(raised.exception.__cause__, error)

    @patch.object(handler.requests, "get")
    def test_token_exchange_encodes_scope_and_identity(self, get):
        get.return_value = Mock(
            status_code=200, json=Mock(return_value={"token": "github-token"})
        )
        self.assertEqual(
            handler.get_github_token(
                "octo-sts-example.dev", "org", "alerts & issues", "repo name", "web-token"
            ),
            "github-token",
        )
        get.assert_called_once_with(
            "https://octo-sts-example.dev/sts/exchange"
            "?scope=org/repo%20name&identity=alerts%20%26%20issues",
            headers={"Authorization": "Bearer " + "web-token"},
            timeout=10,
        )

    @patch.object(handler.requests, "get")
    def test_token_exchange_http_errors_are_logged_and_preserve_cause(self, get):
        for status in (401, 403, 429, 500):
            with self.subTest(status=status):
                error = requests.HTTPError("Exchange failed")
                get.return_value = Mock(status_code=status, text="Exchange failed")
                get.return_value.raise_for_status.side_effect = error
                with self.assertLogs(handler.logger, level="ERROR"):
                    with self.assertRaisesRegex(RuntimeError, "STS exchange") as raised:
                        handler.get_github_token(
                            "octo-sts-example.dev", "org", "identity", "repo", "web-token"
                        )
                self.assertIs(raised.exception.__cause__, error)

    @patch.object(handler.requests, "get")
    def test_token_exchange_network_errors_preserve_cause(self, get):
        for error in (requests.Timeout("Timeout"), requests.ConnectionError("Offline")):
            with self.subTest(error=type(error).__name__):
                get.side_effect = error
                with self.assertRaisesRegex(RuntimeError, "STS exchange") as raised:
                    handler.get_github_token(
                        "octo-sts-example.dev", "org", "identity", "repo", "web-token"
                    )
                self.assertIs(raised.exception.__cause__, error)

    @patch.object(handler.requests, "get")
    def test_token_exchange_rejects_invalid_json_and_token_shapes(self, get):
        payloads = (
            None, [], "text", 1, True, {}, {"token": None}, {"token": ""},
            {"token": " \t"}, {"token": 1}, {"token": []}, {"token": {}},
        )
        for payload in payloads:
            with self.subTest(payload=payload):
                get.return_value = Mock(
                    status_code=200, json=Mock(return_value=payload)
                )
                with self.assertLogs(handler.logger, level="ERROR"):
                    with self.assertRaisesRegex(RuntimeError, "valid token"):
                        handler.get_github_token(
                            "octo-sts-example.dev", "org", "identity", "repo", "web-token"
                        )
        error = ValueError("Invalid JSON")
        get.return_value.json.side_effect = error
        with self.assertLogs(handler.logger, level="ERROR"):
            with self.assertRaisesRegex(RuntimeError, "valid JSON") as raised:
                handler.get_github_token(
                    "octo-sts-example.dev", "org", "identity", "repo", "web-token"
                )
        self.assertIs(raised.exception.__cause__, error)

    @patch.object(handler.requests, "post")
    def test_issue_creation_network_errors_preserve_cause(self, post):
        for error in (requests.Timeout("Timeout"), requests.ConnectionError("Offline")):
            with self.subTest(error=type(error).__name__):
                post.side_effect = error
                with self.assertRaisesRegex(RuntimeError, "request failed") as raised:
                    handler.create_github_issue("org", "github-token", "repo", {})
                self.assertIs(raised.exception.__cause__, error)

    @patch.object(handler.requests, "post")
    def test_issue_creation_rejects_unexpected_success_status(self, post):
        for status in (200, 202, 204):
            with self.subTest(status=status):
                post.return_value = Mock(status_code=status, text="Unexpected response")
                with self.assertLogs(handler.logger, level="ERROR"):
                    with self.assertRaisesRegex(RuntimeError, f"unexpected status: {status}"):
                        handler.create_github_issue("org", "github-token", "repo", {})

    def test_string_sets_deduplicate_without_changing_case(self):
        with patch.dict(os.environ, {"RESOURCE_KEYS_TO_EXCLUDE": '["Tags", "Tags", "tags"]'}):
            self.assertEqual(
                handler.get_string_set("RESOURCE_KEYS_TO_EXCLUDE", "[]"),
                {"Tags", "tags"},
            )

    def test_severity_defaults_apply_when_both_variables_are_absent(self):
        os.environ.pop("VALID_SEVERITY_LABELS")
        os.environ.pop("FINDING_SEVERITY_LABELS")
        self.assertEqual(handler.get_finding_severity_labels(), {"CRITICAL"})

    def test_ignore_configuration_defaults_and_preserves_substrings(self):
        os.environ.pop("IGNORE_FINDINGS")
        self.assertEqual(handler.get_ignored_findings(), {})
        os.environ["IGNORE_FINDINGS"] = '{"test-account": "public access"}'
        self.assertEqual(
            handler.get_ignored_findings(), {"test-account": "public access"}
        )

    def test_invalid_ignore_configuration_is_logged_and_rejected(self):
        values = ["", "not-json", "null", "[]", "true", '{"": "text"}', '{" ": "text"}']
        values.extend(
            json.dumps({"test-account": value})
            for value in (None, "", " ", 1, True, [], {})
        )
        for value in values:
            with self.subTest(value=value):
                with patch.dict(os.environ, {"IGNORE_FINDINGS": value}):
                    with self.assertLogs(handler.logger, level="ERROR"):
                        with self.assertRaisesRegex(ValueError, "IGNORE_FINDINGS"):
                            handler.get_ignored_findings()

    def test_minimal_issue_uses_defaults_and_omits_optional_sections(self):
        issue = handler.build_github_issue({})
        self.assertEqual(
            issue["title"], "[UNKNOWN] Untitled Security Hub finding - unknown account"
        )
        self.assertEqual(
            issue["body"], "## Severity\nUNKNOWN\n\n## Account\nunknown account"
        )
        self.assertEqual(set(issue), {"title", "body", "labels"})

    def test_empty_optional_fields_and_null_remediation_are_omitted(self):
        for remediation in (None, {}, {"Recommendation": None}, {"Recommendation": {}}):
            with self.subTest(remediation=remediation):
                finding = {
                    "Title": "",
                    "Severity": None,
                    "Region": None,
                    "Description": "",
                    "Types": [],
                    "Resources": [],
                    "Id": "",
                    "Remediation": remediation,
                }
                self.assertEqual(
                    handler.build_github_issue(finding)["body"],
                    "## Severity\nUNKNOWN\n\n## Account\nunknown account",
                )

    def test_exclusions_apply_only_to_top_level_resource_keys(self):
        self.finding["Resources"][0]["Owner"] = {"Tags": {"preserved": "value"}}
        self.finding["Resources"][0]["Tags"] = {"removed": "value"}
        body = handler.build_github_issue(self.finding)["body"]
        resources = json.loads(body.split("```json\n", 1)[1].split("\n```", 1)[0])
        self.assertNotIn("Tags", resources[0])
        self.assertEqual(resources[0]["Owner"], {"Tags": {"preserved": "value"}})

    @patch.object(handler, "create_github_issue")
    @patch.object(handler, "get_github_token")
    @patch.object(handler, "get_web_identity_token")
    def test_malformed_events_fail_before_external_calls(self, web, token, create):
        for event in (
            None, "text", [], {}, {"detail": None}, {"detail": []},
            {"detail": {}}, {"detail": {"findings": None}},
            {"detail": {"findings": "text"}}, {"detail": {"findings": [None]}},
            {"detail": {"findings": [self.finding, []]}},
        ):
            with self.subTest(event=event):
                with self.assertRaises(ValueError):
                    handler.lambda_handler(event, None)
        web.assert_not_called()
        token.assert_not_called()
        create.assert_not_called()

    @patch.object(handler, "get_web_identity_token")
    def test_malformed_severity_values_are_logged_and_skipped(self, web):
        for severity in (None, [], "CRITICAL", {}, {"Label": []}, {"Label": 1}):
            with self.subTest(severity=severity):
                self.event["detail"]["findings"][0]["Severity"] = severity
                with self.assertLogs(handler.logger, level="INFO") as logs:
                    result = handler.lambda_handler(self.event, None)
                self.assertEqual(result["statusCode"], 200)
                self.assertIn("Skipping Security Hub finding", "\n".join(logs.output))
        web.assert_not_called()

    @patch.object(handler, "create_github_issue")
    @patch.object(handler, "get_github_token")
    @patch.object(handler, "get_web_identity_token")
    def test_invalid_runtime_configuration_stops_before_external_calls(
        self, web, token, create
    ):
        cases = [
            ("WEB_IDENTITY_DURATION_SECONDS", "text", "must be an integer"),
            ("WEB_IDENTITY_DURATION_SECONDS", "59", "between 60 and 600"),
            ("WEB_IDENTITY_DURATION_SECONDS", "601", "between 60 and 600"),
            ("WEB_IDENTITY_SIGNING_ALGORITHM", "ES384", "must be RS256"),
        ]
        cases.extend(
            (name, "", "Missing required parameter")
            for name in ("WEB_IDENTITY_AUDIENCE", "GITHUB_ORG", "GITHUB_IDENTITY", "GITHUB_REPO")
        )
        for name, value, message in cases:
            with self.subTest(name=name, value=value):
                with patch.dict(os.environ, {name: value}):
                    with self.assertRaisesRegex(ValueError, message):
                        handler.lambda_handler(self.event, None)
        web.assert_not_called()
        token.assert_not_called()
        create.assert_not_called()

    @patch.object(
        handler, "create_github_issue",
        return_value={"number": 42, "html_url": "https://example/42"},
    )
    @patch.object(handler, "get_github_token", return_value="github-token")
    @patch.object(handler, "get_web_identity_token", return_value=("web-token", None))
    def test_duration_boundaries_and_defaults(self, web, token, create):
        for duration in ("60", "600", None):
            with self.subTest(duration=duration):
                web.reset_mock()
                with patch.dict(os.environ):
                    if duration is None:
                        os.environ.pop("WEB_IDENTITY_DURATION_SECONDS")
                        os.environ.pop("WEB_IDENTITY_SIGNING_ALGORITHM")
                    else:
                        os.environ["WEB_IDENTITY_DURATION_SECONDS"] = duration
                    handler.lambda_handler(self.event, None)
                self.assertEqual(
                    web.call_args.kwargs["duration_seconds"],
                    600 if duration is None else int(duration),
                )
                self.assertEqual(web.call_args.kwargs["signing_algorithm"], "RS256")

    @patch.object(
        handler, "create_github_issue",
        return_value={"number": 42, "html_url": "https://example/42"},
    )
    @patch.object(handler, "get_github_token", return_value="github-token")
    @patch.object(handler, "get_web_identity_token", return_value=("web-token", None))
    def test_ignore_matching_is_case_sensitive_and_requires_description(
        self, web, token, create
    ):
        os.environ["IGNORE_FINDINGS"] = '{"test-account": "PUBLIC ACCESS"}'
        for description in ("A resource allows public access.", None, "", []):
            with self.subTest(description=description):
                create.reset_mock()
                self.event["detail"]["findings"][0]["Description"] = description
                handler.lambda_handler(self.event, None)
                create.assert_called_once()

    @patch.object(
        handler, "create_github_issue",
        return_value={"number": 42, "html_url": "https://example/42"},
    )
    @patch.object(handler, "get_github_token", return_value="github-token")
    @patch.object(handler, "get_web_identity_token", return_value=("web-token", None))
    def test_mixed_ignored_and_matching_batch_preserves_input(self, web, token, create):
        os.environ["IGNORE_FINDINGS"] = '{"test-account": "public access"}'
        self.event["detail"]["findings"].append(
            {**copy.deepcopy(self.finding), "Description": "Different description"}
        )
        original = copy.deepcopy(self.event)
        result = handler.lambda_handler(self.event, None)
        create.assert_called_once()
        self.assertIn("Different description", create.call_args.kwargs["issue"]["body"])
        self.assertEqual(len(json.loads(result["body"])["issues"]), 1)
        self.assertEqual(self.event, original)

    @patch.object(handler, "create_github_issue")
    @patch.object(handler, "get_github_token")
    @patch.object(handler, "get_web_identity_token")
    def test_authentication_failures_stop_downstream_calls(self, web, token, create):
        error = RuntimeError("Authentication failed")
        web.side_effect = error
        with self.assertRaises(RuntimeError) as raised:
            handler.lambda_handler(self.event, None)
        self.assertIs(raised.exception, error)
        token.assert_not_called()
        create.assert_not_called()

        web.side_effect = None
        web.return_value = ("web-token", None)
        token.side_effect = error
        with self.assertRaises(RuntimeError) as raised:
            handler.lambda_handler(self.event, None)
        self.assertIs(raised.exception, error)
        create.assert_not_called()

    @patch.object(handler, "create_github_issue")
    @patch.object(handler, "get_github_token", return_value="github-token")
    @patch.object(handler, "get_web_identity_token", return_value=("web-token", None))
    def test_partial_batch_failure_propagates_and_stops_remaining_issues(
        self, web, token, create
    ):
        self.event["detail"]["findings"] = [copy.deepcopy(self.finding) for _ in range(3)]
        error = RuntimeError("GitHub unavailable")
        create.side_effect = [
            {"number": 42, "html_url": "https://example/42"},
            error,
        ]
        with self.assertRaises(RuntimeError) as raised:
            handler.lambda_handler(self.event, None)
        self.assertIs(raised.exception, error)
        self.assertEqual(create.call_count, 2)

    @patch.object(handler.requests, "post")
    @patch.object(handler.requests, "get")
    @patch.object(handler, "sts")
    def test_complete_handler_flow_with_mocked_aws_and_http(self, sts, get, post):
        sts.get_web_identity_token.return_value = {
            "WebIdentityToken": "web-token", "Expiration": "expiry"
        }
        get.return_value = Mock(
            status_code=200, json=Mock(return_value={"token": "github-token"})
        )
        post.return_value = Mock(
            status_code=201,
            json=Mock(return_value={"number": 42, "html_url": "https://example/42"}),
        )
        original = copy.deepcopy(self.event)

        result = handler.lambda_handler(self.event, None)

        self.assertEqual(result["statusCode"], 200)
        self.assertEqual(
            json.loads(result["body"]),
            {
                "message": "Created 1 GitHub issue(s) in org/repo.",
                "issues": [{"issue_number": 42, "issue_url": "https://example/42"}],
            },
        )
        sts.get_web_identity_token.assert_called_once()
        get.assert_called_once()
        post.assert_called_once()
        self.assertEqual(
            get.call_args.kwargs["headers"]["Authorization"], "Bearer " + "web-token"
        )
        self.assertEqual(
            post.call_args.kwargs["headers"]["Authorization"], "Bearer " + "github-token"
        )
        self.assertEqual(
            post.call_args.kwargs["json"],
            handler.build_github_issue(self.finding),
        )
        self.assertEqual(self.event, original)

    @patch.object(handler, "create_github_issue")
    @patch.object(handler, "get_github_token")
    @patch.object(handler, "get_web_identity_token")
    def test_invalid_filter_configuration_stops_before_authentication(
        self, web, token, create
    ):
        for name in ("IGNORE_FINDINGS", "RESOURCE_KEYS_TO_EXCLUDE"):
            with self.subTest(name=name):
                with patch.dict(os.environ, {name: "invalid-json"}):
                    with self.assertLogs(handler.logger, level="ERROR"):
                        with self.assertRaisesRegex(ValueError, name):
                            handler.lambda_handler(self.event, None)
        web.assert_not_called()
        token.assert_not_called()
        create.assert_not_called()

    @patch.object(handler, "create_github_issue")
    @patch.object(handler, "get_github_token", return_value="github-token")
    @patch.object(handler, "get_web_identity_token", return_value=("web-token", None))
    def test_each_configured_severity_can_create_an_issue(self, web, token, create):
        create.return_value = {"number": 42, "html_url": "https://example/42"}
        for severity in ("INFORMATIONAL", "LOW", "MEDIUM", "HIGH", "CRITICAL"):
            with self.subTest(severity=severity):
                create.reset_mock()
                os.environ["FINDING_SEVERITY_LABELS"] = json.dumps([severity])
                self.event["detail"]["findings"][0]["Severity"]["Label"] = severity
                handler.lambda_handler(self.event, None)
                create.assert_called_once()
                self.assertTrue(
                    create.call_args.kwargs["issue"]["title"].startswith(f"[{severity}]")
                )


if __name__ == "__main__":
    unittest.main()
