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
        "aws_health_handler", Path(__file__).with_name("handler.py")
    )
    handler = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(handler)


class HandlerTests(unittest.TestCase):
    def setUp(self):
        self.environment = {
            "WEB_IDENTITY_AUDIENCE": "octo-sts.dev",
            "GITHUB_ORG": "org",
            "GITHUB_IDENTITY": "health",
            "GITHUB_REPO": "repo",
        }
        environment = patch.dict(os.environ, self.environment, clear=True)
        environment.start()
        self.addCleanup(environment.stop)
        self.event = {
            "detail-type": "AWS Health Event",
            "account": "test-account",
            "resources": ["cluster|service"],
            "detail": {
                "eventTypeCode": "AWS_ECS_TASK_PATCHING_RETIREMENT",
                "startTime": "Thu, 22 Oct 2026 18:00:00 GMT",
                "endTime": "Thu, 29 Oct 2026 18:00:00 GMT",
                "affectedEntities": [
                    {"entityValue": "cluster|service", "status": "IMPAIRED"}
                ],
                "service": "ECS",
                "eventDescription": [
                    {"language": "en_US", "latestDescription": "Description goes here"},
                    {"language": "en_GB", "latestDescription": "Another description"},
                ],
                "eventRegion": "eu-west-2",
                "eventScopeCode": "ACCOUNT_SPECIFIC",
            },
        }

    def test_issue_contains_health_fields(self):
        issue = handler.build_github_issue(self.event)
        self.assertEqual(
            issue["title"],
            "AWS Health Event: AWS_ECS_TASK_PATCHING_RETIREMENT - test-account",
        )
        self.assertEqual(issue["labels"], ["support", "aws_health_event"])
        for value in (
            self.event["detail"]["startTime"],
            self.event["detail"]["endTime"],
            "- cluster|service",
            "ECS",
            "Description goes here",
            "Another description",
            "eu-west-2",
            "ACCOUNT_SPECIFIC",
        ):
            self.assertIn(value, issue["body"])
        entities = issue["body"].split("```json\n", 1)[1].split("\n```", 1)[0]
        self.assertEqual(json.loads(entities), self.event["detail"]["affectedEntities"])

    def test_optional_sections_are_omitted_when_empty_or_absent(self):
        for omit in (False, True):
            with self.subTest(omit=omit):
                event = copy.deepcopy(self.event)
                event["resources"] = []
                event["detail"]["affectedEntities"] = []
                event["detail"]["endTime"] = ""
                if omit:
                    del event["resources"]
                    del event["detail"]["affectedEntities"]
                    del event["detail"]["endTime"]
                body = handler.build_github_issue(event)["body"]
                for heading in ("## End time", "## Resources", "## Affected entities"):
                    self.assertNotIn(heading, body)

    def test_optional_sections_are_independent(self):
        for field, heading in (
            ("resources", "## Resources"),
            ("affectedEntities", "## Affected entities"),
            ("endTime", "## End time"),
        ):
            for state in ("missing", "empty", "null"):
                with self.subTest(field=field, state=state):
                    event = copy.deepcopy(self.event)
                    container = event if field == "resources" else event["detail"]
                    if state == "missing":
                        del container[field]
                    else:
                        container[field] = (
                            None if state == "null" else ("" if field == "endTime" else [])
                        )
                    body = handler.build_github_issue(event)["body"]
                    self.assertNotIn(heading, body)
                    for other in ("## Resources", "## Affected entities", "## End time"):
                        if other != heading:
                            self.assertIn(other, body)
                    self.assertIn("## Service\nECS", body)

    def test_all_resources_and_entities_are_preserved_without_mutating_event(self):
        self.event["resources"].append("another-cluster|another-service")
        self.event["detail"]["affectedEntities"].append(
            {
                "entityValue": "another-cluster|another-service",
                "status": "UNIMPAIRED",
                "lastUpdatedTime": "Thu, 15 Oct 2026 18:27:38 GMT",
            }
        )
        original = copy.deepcopy(self.event)
        issue = handler.build_github_issue(self.event)
        self.assertEqual(set(issue), {"title", "body", "labels"})
        self.assertIn(
            "## Resources\n- cluster|service\n- another-cluster|another-service",
            issue["body"],
        )
        entities = issue["body"].split("```json\n", 1)[1].split("\n```", 1)[0]
        self.assertEqual(json.loads(entities), original["detail"]["affectedEntities"])
        self.assertEqual(self.event, original)

    @patch.object(handler.requests, "post")
    def test_create_issue_posts_authenticated_payload(self, post):
        post.return_value = Mock(
            status_code=201,
            json=Mock(return_value={"number": 42, "html_url": "https://example/42"}),
        )
        issue = handler.build_github_issue(self.event)
        result = handler.create_github_issue("org", "token", "repo", issue)
        self.assertEqual(result["number"], 42)
        post.assert_called_once_with(
            "https://api.github.com/repos/org/repo/issues",
            headers={
                "Authorization": "Bearer token",
                "Accept": "application/vnd.github+json",
                "X-GitHub-Api-Version": "2022-11-28",
            },
            json=issue,
            timeout=10,
        )

    @patch.object(handler.requests, "post")
    def test_api_errors_propagate(self, post):
        post.return_value = Mock(status_code=403, text="Forbidden")
        post.return_value.raise_for_status.side_effect = requests.HTTPError("Forbidden")
        with self.assertRaisesRegex(RuntimeError, "GitHub issue creation request failed"):
            handler.create_github_issue("org", "token", "repo", {})

    @patch.object(handler.requests, "post")
    def test_unexpected_success_status_is_rejected(self, post):
        post.return_value = Mock(status_code=200, text="Unexpected response")
        with self.assertRaisesRegex(RuntimeError, "unexpected status: 200"):
            handler.create_github_issue("org", "token", "repo", {})

    @patch.object(handler.requests, "post")
    def test_issue_creation_network_errors_preserve_cause(self, post):
        for error in (requests.Timeout("Timed out"), requests.ConnectionError("Offline")):
            with self.subTest(error=type(error).__name__):
                post.side_effect = error
                with self.assertRaisesRegex(
                    RuntimeError, "GitHub issue creation request failed"
                ) as raised:
                    handler.create_github_issue("org", "token", "repo", {})
                self.assertIs(raised.exception.__cause__, error)

    @patch.object(handler, "sts")
    def test_web_identity_request_and_response(self, sts):
        sts.get_web_identity_token.return_value = {
            "WebIdentityToken": "web-token",
            "Expiration": "2026-10-19T13:40:00Z",
        }
        result = handler.get_web_identity_token("octo-sts.dev", 600, "RS256")
        self.assertEqual(result, ("web-token", "2026-10-19T13:40:00Z"))
        sts.get_web_identity_token.assert_called_once_with(
            Audience=["octo-sts.dev"], DurationSeconds=600, SigningAlgorithm="RS256"
        )

    @patch.object(handler, "sts")
    def test_web_identity_client_error_is_logged_and_propagated(self, sts):
        error = ClientError(
            {"Error": {"Code": "AccessDenied", "Message": "Access denied"}},
            "GetWebIdentityToken",
        )
        sts.get_web_identity_token.side_effect = error
        with self.assertLogs(handler.logger, level="ERROR") as logs:
            with self.assertRaisesRegex(RuntimeError, "AccessDenied") as raised:
                handler.get_web_identity_token("octo-sts.dev", 600, "RS256")
        self.assertIs(raised.exception.__cause__, error)
        self.assertIn("Failed to obtain web identity token", "\n".join(logs.output))

    @patch.object(handler.requests, "get")
    def test_github_token_exchange_encodes_identity_and_scope(self, get):
        get.return_value = Mock(
            status_code=200, json=Mock(return_value={"token": "github-token"})
        )
        token = handler.get_github_token(
            "octo-sts.dev", "org", "health & alerts", "repo name", "web-token"
        )
        self.assertEqual(token, "github-token")
        get.assert_called_once_with(
            "https://octo-sts.dev/sts/exchange"
            "?scope=org/repo%20name&identity=health%20%26%20alerts",
            headers={"Authorization": "Bearer " + "web-token"},
            timeout=10,
        )

    @patch.object(handler.requests, "get")
    def test_github_token_exchange_http_errors(self, get):
        for status in (401, 403, 429, 500):
            with self.subTest(status=status):
                get.return_value = Mock(status_code=status, text="Exchange failed")
                get.return_value.raise_for_status.side_effect = requests.HTTPError(
                    "Exchange failed"
                )
                with self.assertLogs(handler.logger, level="ERROR"):
                    with self.assertRaisesRegex(
                        RuntimeError, "STS exchange request failed"
                    ):
                        handler.get_github_token(
                            "octo-sts.dev", "org", "health", "repo", "web-token"
                        )

    @patch.object(handler.requests, "get")
    def test_github_token_exchange_network_errors(self, get):
        for error in (requests.Timeout("Timed out"), requests.ConnectionError("Offline")):
            with self.subTest(error=type(error).__name__):
                get.side_effect = error
                with self.assertRaisesRegex(RuntimeError, "STS exchange request failed"):
                    handler.get_github_token(
                        "octo-sts.dev", "org", "health", "repo", "web-token"
                    )

    @patch.object(handler.requests, "get")
    def test_github_token_exchange_rejects_missing_token(self, get):
        for payload in (
            {},
            {"message": "No token"},
            {"token": None},
            {"token": ""},
            {"token": " \t\n"},
            {"token": 123},
            {"token": True},
            {"token": ["token"]},
            {"token": {"value": "token"}},
            [],
            ["token"],
            "token",
            None,
            123,
        ):
            with self.subTest(payload=payload):
                get.return_value = Mock(
                    status_code=200, json=Mock(return_value=payload)
                )
                with self.assertLogs(handler.logger, level="ERROR"):
                    with self.assertRaisesRegex(
                        RuntimeError, "STS exchange response did not contain a valid token"
                    ):
                        handler.get_github_token(
                            "octo-sts.dev", "org", "health", "repo", "web-token"
                        )

    @patch.object(handler.requests, "get")
    def test_github_token_exchange_accepts_json_formatting(self, get):
        for text in (
            '{"token":"github-token"}',
            '{"token": "github-token"}',
            '{\n  "token": "github-token",\n  "expires_in": 600\n}',
        ):
            with self.subTest(text=text):
                response = requests.Response()
                response.status_code = 200
                response.encoding = "utf-8"
                response._content = text.encode("utf-8")
                get.return_value = response
                self.assertEqual(
                    handler.get_github_token(
                        "octo-sts.dev", "org", "health", "repo", "web-token"
                    ),
                    "github-token",
                )

    @patch.object(handler.requests, "get")
    def test_github_token_exchange_rejects_malformed_json(self, get):
        for text in ("", "not JSON", '{"token":'):
            with self.subTest(text=text):
                response = requests.Response()
                response.status_code = 200
                response._content = text.encode("utf-8")
                get.return_value = response
                with self.assertLogs(handler.logger, level="ERROR"):
                    with self.assertRaisesRegex(
                        RuntimeError, "STS exchange response was not valid JSON"
                    ) as raised:
                        handler.get_github_token(
                            "octo-sts.dev", "org", "health", "repo", "web-token"
                        )
                self.assertIsInstance(
                    raised.exception.__cause__, requests.exceptions.JSONDecodeError
                )

    @patch.object(handler.requests, "get")
    def test_invalid_token_error_does_not_expose_response_contents(self, get):
        sensitive_value = "sensitive-response-value"
        get.return_value = Mock(
            status_code=200,
            json=Mock(return_value={"token": {"unexpected": sensitive_value}}),
        )
        with self.assertLogs(handler.logger, level="ERROR") as logs:
            with self.assertRaises(RuntimeError) as raised:
                handler.get_github_token(
                    "octo-sts.dev", "org", "health", "repo", "web-token"
                )
        self.assertNotIn(sensitive_value, str(raised.exception))
        self.assertNotIn(sensitive_value, "\n".join(logs.output))

    @patch.object(handler, "create_github_issue")
    @patch.object(handler, "get_github_token")
    @patch.object(handler, "get_web_identity_token")
    def test_resolved_entities_skip_ticket_and_authentication(
        self, web_token, github_token, create
    ):
        for count in (1, 2):
            with self.subTest(entity_count=count):
                event = copy.deepcopy(self.event)
                event["detail"]["eventArn"] = "arn:aws:health:example"
                event["detail"]["affectedEntities"] = [
                    {"entityValue": f"resource-{index}", "status": "RESOLVED"}
                    for index in range(count)
                ]
                original = copy.deepcopy(event)
                with self.assertLogs(handler.logger, level="INFO") as logs:
                    result = handler.lambda_handler(event, None)
                self.assertEqual(result["statusCode"], 200)
                self.assertIn(
                    "not generating a ticket", json.loads(result["body"])["message"]
                )
                self.assertIn("All affected entities are RESOLVED", "\n".join(logs.output))
                self.assertIn("arn:aws:health:example", "\n".join(logs.output))
                self.assertEqual(event, original)
        web_token.assert_not_called()
        github_token.assert_not_called()
        create.assert_not_called()

    @patch.object(handler, "create_github_issue")
    @patch.object(handler, "get_github_token", return_value="github-token")
    @patch.object(handler, "get_web_identity_token", return_value=("web-token", None))
    def test_non_resolved_or_absent_entities_still_generate_labelled_tickets(
        self, web_token, github_token, create
    ):
        cases = {
            "mixed": [{"status": "RESOLVED"}, {"status": "IMPAIRED"}],
            "impaired": [{"status": "IMPAIRED"}],
            "unknown_status": [{"status": "RESOLVED"}, {}],
            "empty": [],
            "null": None,
            "missing": None,
        }
        create.return_value = {"number": 42, "html_url": "https://example/42"}
        for name, entities in cases.items():
            with self.subTest(case=name):
                web_token.reset_mock()
                github_token.reset_mock()
                create.reset_mock()
                event = copy.deepcopy(self.event)
                if name == "missing":
                    del event["detail"]["affectedEntities"]
                else:
                    event["detail"]["affectedEntities"] = entities
                original = copy.deepcopy(event)
                result = handler.lambda_handler(event, None)
                web_token.assert_called_once()
                github_token.assert_called_once()
                create.assert_called_once()
                self.assertEqual(
                    create.call_args.kwargs["issue"]["labels"],
                    ["support", "aws_health_event"],
                )
                self.assertEqual(result["statusCode"], 200)
                self.assertEqual(json.loads(result["body"])["issue_number"], 42)
                self.assertEqual(event, original)

    @patch.object(handler, "create_github_issue")
    @patch.object(handler, "get_github_token")
    @patch.object(handler, "get_web_identity_token")
    def test_invalid_configuration_fails_before_external_calls(
        self, web_token, github_token, create
    ):
        cases = [
            ({"duration_seconds": "not-an-integer"}, "must be an integer"),
            ({"duration_seconds": [600]}, "must be an integer"),
            ({"duration_seconds": -1}, "must be between 60 and 600"),
            ({"duration_seconds": 59}, "must be between 60 and 600"),
            ({"duration_seconds": 601}, "must be between 60 and 600"),
            ({"signing_algorithm": "ES384"}, "must be RS256"),
        ]
        for overrides, message in cases:
            with self.subTest(overrides=overrides):
                with self.assertRaisesRegex(ValueError, message):
                    handler.lambda_handler({**self.event, **overrides}, None)
        web_token.assert_not_called()
        github_token.assert_not_called()
        create.assert_not_called()

    @patch.object(handler, "get_web_identity_token")
    def test_missing_configuration_is_rejected(self, web_token):
        for variable, parameter in (
            ("WEB_IDENTITY_AUDIENCE", "audience"),
            ("GITHUB_ORG", "github_org"),
            ("GITHUB_IDENTITY", "identity"),
            ("GITHUB_REPO", "repo"),
        ):
            with self.subTest(variable=variable):
                environment = dict(self.environment)
                del environment[variable]
                with patch.dict(os.environ, environment, clear=True):
                    with self.assertRaisesRegex(
                        ValueError, f"Missing required parameter: '{parameter}'"
                    ):
                        handler.lambda_handler(self.event, None)
        web_token.assert_not_called()

    @patch.object(handler, "get_web_identity_token")
    def test_non_object_events_are_rejected(self, web_token):
        for event in (None, [], "event", 123):
            with self.subTest(event=event):
                with self.assertRaisesRegex(ValueError, "Event must be an object"):
                    handler.lambda_handler(event, None)
        web_token.assert_not_called()

    @patch.object(handler, "create_github_issue")
    @patch.object(handler, "get_github_token")
    @patch.object(handler, "get_web_identity_token")
    def test_authentication_failure_stops_processing(self, web_token, github_token, create):
        error = RuntimeError("Authentication failed")
        web_token.side_effect = error
        with self.assertRaises(RuntimeError) as raised:
            handler.lambda_handler(self.event, None)
        self.assertIs(raised.exception, error)
        github_token.assert_not_called()
        create.assert_not_called()

        web_token.side_effect = None
        web_token.return_value = ("web-token", None)
        github_token.side_effect = error
        with self.assertRaises(RuntimeError) as raised:
            handler.lambda_handler(self.event, None)
        self.assertIs(raised.exception, error)
        create.assert_not_called()

    @patch.object(handler, "create_github_issue")
    @patch.object(handler, "get_github_token", return_value="github-token")
    @patch.object(handler, "get_web_identity_token", return_value=("web-token", None))
    def test_environment_duration_boundaries(self, web_token, github_token, create):
        create.return_value = {"number": 42, "html_url": "https://example/42"}
        for duration in (60, 600):
            with self.subTest(duration=duration):
                with patch.dict(
                    os.environ, {"WEB_IDENTITY_DURATION_SECONDS": str(duration)}
                ):
                    handler.lambda_handler(self.event, None)
                web_token.assert_called_with(
                    audience="octo-sts.dev",
                    duration_seconds=duration,
                    signing_algorithm="RS256",
                )

    @patch.object(handler, "create_github_issue")
    @patch.object(handler, "get_github_token", return_value="github-token")
    @patch.object(handler, "get_web_identity_token", return_value=("web-token", None))
    def test_handler_does_not_return_success_when_issue_creation_fails(
        self, web_token, github_token, create
    ):
        error = RuntimeError("GitHub issue creation failed")
        create.side_effect = error
        with self.assertRaises(RuntimeError) as raised:
            handler.lambda_handler(self.event, None)
        self.assertIs(raised.exception, error)
        create.assert_called_once()

    @patch.object(handler, "create_github_issue")
    @patch.object(handler, "get_github_token", return_value="github-token")
    @patch.object(handler, "get_web_identity_token", return_value=("web-token", None))
    def test_event_configuration_overrides_environment(self, web_token, github_token, create):
        event = {
            **self.event,
            "audience": "custom.example",
            "github_org": "another-org",
            "identity": "another-identity",
            "repo": "another-repo",
            "duration_seconds": "60",
            "signing_algorithm": "RS256",
        }
        create.return_value = {"number": 99, "html_url": "https://example/99"}
        result = handler.lambda_handler(event, None)
        web_token.assert_called_once_with(
            audience="custom.example", duration_seconds=60, signing_algorithm="RS256"
        )
        github_token.assert_called_once_with(
            audience="custom.example",
            github_org="another-org",
            identity="another-identity",
            repo="another-repo",
            web_identity_token="web-token",
        )
        create.assert_called_once_with(
            github_org="another-org",
            github_token="github-token",
            repo="another-repo",
            issue=handler.build_github_issue(event),
        )
        self.assertEqual(
            json.loads(result["body"]),
            {
                "message": "GitHub issue created successfully for another-org/another-repo.",
                "issue_number": 99,
                "issue_url": "https://example/99",
            },
        )

    @patch.dict(
        os.environ,
        {
            "WEB_IDENTITY_AUDIENCE": "octo-sts.dev",
            "GITHUB_ORG": "org",
            "GITHUB_IDENTITY": "health",
            "GITHUB_REPO": "repo",
        },
        clear=True,
    )
    @patch.object(handler, "create_github_issue")
    @patch.object(handler, "get_github_token", return_value="github-token")
    @patch.object(handler, "get_web_identity_token", return_value=("web-token", None))
    def test_handler_accepts_raw_health_event(self, web_token, github_token, create):
        create.return_value = {"number": 42, "html_url": "https://example/42"}
        result = handler.lambda_handler(self.event, None)
        web_token.assert_called_once_with(
            audience="octo-sts.dev", duration_seconds=600, signing_algorithm="RS256"
        )
        github_token.assert_called_once_with(
            audience="octo-sts.dev",
            github_org="org",
            identity="health",
            repo="repo",
            web_identity_token="web-token",
        )
        create.assert_called_once_with(
            github_org="org",
            github_token="github-token",
            repo="repo",
            issue=handler.build_github_issue(self.event),
        )
        self.assertEqual(result["statusCode"], 200)
        self.assertEqual(json.loads(result["body"])["issue_number"], 42)


if __name__ == "__main__":
    unittest.main()
