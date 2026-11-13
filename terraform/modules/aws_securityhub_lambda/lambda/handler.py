import boto3
import json
import logging
import os
from datetime import datetime, timedelta
from urllib.parse import quote

import requests

from botocore.exceptions import ClientError

logger = logging.getLogger()
logger.setLevel(logging.INFO)

sts = boto3.client("sts", region_name=os.getenv("AWS_REGION"))


def get_web_identity_token(audience, duration_seconds, signing_algorithm):
    request = {
        "Audience": [audience],
        "DurationSeconds": duration_seconds,
        "SigningAlgorithm": signing_algorithm,
    }

    try:
        response = sts.get_web_identity_token(**request)
    except ClientError as error:
        error_code = error.response.get("Error", {}).get("Code", "ClientError")
        error_message = error.response.get("Error", {}).get("Message", str(error))
        logger.error(
            "Failed to obtain web identity token. %s: %s",
            error_code,
            error_message,
        )
        raise RuntimeError(
            f"Failed to obtain web identity token. {error_code}"
        ) from error

    return response["WebIdentityToken"], response["Expiration"]


def get_github_token(audience, github_org, identity, repo, web_identity_token):
    scope = f"{github_org}/{repo}"
    url = (
        f"https://{audience}/sts/exchange"
        f"?scope={quote(scope, safe='/:')}"
        f"&identity={quote(identity, safe='')}"
    )

    try:
        response = requests.get(
            url,
            headers={"Authorization": "Bearer " + web_identity_token},
            timeout=10,
        )
        if response.status_code != 200:
            logger.error(
                "STS exchange failed. status=%s url=%s body=%s",
                response.status_code,
                url,
                response.text,
            )
        response.raise_for_status()
    except requests.RequestException as error:
        raise RuntimeError(f"STS exchange request failed: {error}") from error

    try:
        payload = response.json()
    except ValueError as error:
        logger.error("STS exchange response was not valid JSON")
        raise RuntimeError("STS exchange response was not valid JSON") from error

    github_token = payload.get("token") if isinstance(payload, dict) else None
    if not isinstance(github_token, str) or not github_token.strip():
        logger.error("STS exchange response did not contain a valid token")
        raise RuntimeError("STS exchange response did not contain a valid token")

    return github_token


def get_ignored_findings():
    try:
        findings = json.loads(os.getenv("IGNORE_FINDINGS", "{}"))
    except ValueError as error:
        logger.error("IGNORE_FINDINGS must contain a JSON object")
        raise ValueError("IGNORE_FINDINGS must contain a JSON object") from error

    if not isinstance(findings, dict) or any(
        not isinstance(account, str)
        or not account.strip()
        or not isinstance(description, str)
        or not description.strip()
        for account, description in findings.items()
    ):
        message = (
            "IGNORE_FINDINGS must map non-empty account keys "
            "to non-empty description strings"
        )
        logger.error(message)
        raise ValueError(message)
    return findings


def get_string_set(name, default, allow_empty=False):
    try:
        values = json.loads(os.getenv(name, default))
    except ValueError as error:
        message = f"{name} must contain a JSON array"
        logger.error(message)
        raise ValueError(message) from error

    if (
        not isinstance(values, list)
        or (not values and not allow_empty)
        or any(not isinstance(value, str) or not value.strip() for value in values)
    ):
        message = f"{name} must contain a JSON array of non-empty strings"
        logger.error(message)
        raise ValueError(message)

    return set(values)


def get_finding_severity_labels():
    valid_labels = get_string_set(
        "VALID_SEVERITY_LABELS",
        '["INFORMATIONAL", "LOW", "MEDIUM", "HIGH", "CRITICAL"]',
    )
    labels = get_string_set("FINDING_SEVERITY_LABELS", '["CRITICAL"]')
    if not labels <= valid_labels:
        message = "FINDING_SEVERITY_LABELS must be included in VALID_SEVERITY_LABELS"
        logger.error(message)
        raise ValueError(message)
    return labels


def build_github_issue(finding):
    resource_keys_to_exclude = get_string_set(
        "RESOURCE_KEYS_TO_EXCLUDE", '["Tags", "Details"]', allow_empty=True
    )
    title = finding.get("Title") or "Untitled Security Hub finding"
    severity_details = finding.get("Severity")
    severity = (
        severity_details.get("Label", "UNKNOWN")
        if isinstance(severity_details, dict)
        else "UNKNOWN"
    )
    account_id = finding.get("AwsAccountId", "unknown account")
    issue_title = f"[{severity}] {title} - {account_id}"

    sections = [
        f"## Severity\n{severity}",
        f"## Account\n{account_id}",
    ]

    if finding.get("Region"):
        sections.append(f"## Region\n{finding['Region']}")
    if finding.get("Description"):
        sections.append(f"## Description\n{finding['Description']}")
    if finding.get("Types"):
        sections.append(
            "## Finding types\n" + "\n".join(f"- {item}" for item in finding["Types"])
        )
    if finding.get("Resources"):
        resources = json.dumps(
            [
                {
                    key: value
                    for key, value in resource.items()
                    if key not in resource_keys_to_exclude
                }
                for resource in finding["Resources"]
            ],
            indent=2,
        )
        sections.append(f"## Resources\n```json\n{resources}\n```")
    remediation = finding.get("Remediation")
    recommendation_details = (
        remediation.get("Recommendation") if isinstance(remediation, dict) else None
    )
    recommendation = (
        recommendation_details.get("Text")
        if isinstance(recommendation_details, dict)
        else None
    )
    if recommendation:
        sections.append(f"## Remediation\n{recommendation}")
    if finding.get("Id"):
        finding_id = finding["Id"]
        if finding_id.startswith("arn:"):
            finding_id = finding_id.rsplit("/", 1)[-1].rsplit(":", 1)[-1]
        sections.append(f"## Finding ID\n{finding_id}")

    return {
        "title": issue_title,
        "body": "\n\n".join(sections),
        "labels": ["support", "aws_securityhub_finding"],
    }


def create_github_issue(github_org, github_token, repo, issue):
    url = f"https://api.github.com/repos/{github_org}/{repo}/issues"

    try:
        response = requests.post(
            url,
            headers={
                "Authorization": "Bearer " + github_token,
                "Accept": "application/vnd.github+json",
                "X-GitHub-Api-Version": "2022-11-28",
            },
            json=issue,
            timeout=10,
        )
        if response.status_code != 201:
            logger.error(
                "GitHub issue creation failed. status=%s url=%s body=%s",
                response.status_code,
                url,
                response.text,
            )
            response.raise_for_status()
            raise RuntimeError(
                f"GitHub issue creation returned unexpected status: {response.status_code}"
            )
    except requests.RequestException as error:
        raise RuntimeError(f"GitHub issue creation request failed: {error}") from error

    return response.json()


def get_finding_grace_period():
    value = os.getenv("FINDING_GRACE_PERIOD", "10")
    try:
        minutes = int(value)
    except ValueError as error:
        logger.error("FINDING_GRACE_PERIOD must be a non-negative whole number of minutes")
        raise ValueError(
            "FINDING_GRACE_PERIOD must be a non-negative whole number of minutes"
        ) from error
    if minutes < 0:
        logger.error("FINDING_GRACE_PERIOD must be non-negative")
        raise ValueError("FINDING_GRACE_PERIOD must be non-negative")
    return minutes


def finding_is_within_grace_period(finding, minutes):
    timestamps = {}
    for field in ("CreatedAt", "UpdatedAt"):
        value = finding.get(field)
        try:
            if not isinstance(value, str):
                raise ValueError("Timestamp must be a string")
            timestamp = datetime.fromisoformat(value.replace("Z", "+00:00"))
            if timestamp.utcoffset() is None:
                raise ValueError("Timestamp must include a timezone")
        except ValueError as error:
            logger.error(
                "Security Hub finding %s has missing or invalid %s",
                finding.get("Id", "unknown"), field,
            )
            raise ValueError(f"Finding {field} must be a timezone-aware timestamp") from error
        timestamps[field] = timestamp

    elapsed = timestamps["UpdatedAt"] - timestamps["CreatedAt"]
    if elapsed < timedelta(0) or elapsed.total_seconds() > minutes * 60:
        logger.info(
            "Skipping Security Hub finding %s: UpdatedAt is outside the %s-minute grace period after CreatedAt",
            finding.get("Id", "unknown"), minutes,
        )
        return False
    return True


def lambda_handler(event, context):
    if not isinstance(event, dict):
        raise ValueError("Event must be an object")

    logger.info("Received AWS Security Hub event: %s", json.dumps(event))

    detail = event.get("detail")
    findings = detail.get("findings") if isinstance(detail, dict) else None
    if not isinstance(findings, list):
        raise ValueError("Event detail must contain a findings array")

    expected_severities = get_finding_severity_labels()
    grace_period = get_finding_grace_period()
    matching_findings = []
    for finding in findings:
        if not isinstance(finding, dict):
            raise ValueError("Each Security Hub finding must be an object")

        severity = finding.get("Severity")
        severity_label = severity.get("Label") if isinstance(severity, dict) else None
        if (
            not isinstance(severity_label, str)
            or severity_label not in expected_severities
        ):
            logger.info(
                "Skipping Security Hub finding with severity %s; expected one of %s",
                severity_label or "UNKNOWN",
                sorted(expected_severities),
            )
            continue
        if finding_is_within_grace_period(finding, grace_period):
            matching_findings.append(finding)

    if not matching_findings:
        message = "No Security Hub findings matched the configured severity labels and grace period."
        logger.info(message)
        return {"statusCode": 200, "body": json.dumps({"message": message})}

    ignored_findings = get_ignored_findings()
    issues_to_create = []
    for finding in matching_findings:
        account_id = str(finding.get("AwsAccountId", ""))
        ignored_description = ignored_findings.get(account_id)
        description = finding.get("Description")
        if not isinstance(description, str):
            description = ""
        if ignored_description and ignored_description in description:
            logger.info(
                "Skipping ignored Security Hub finding %s for account %s",
                finding.get("Id", "unknown"),
                account_id or "unknown",
            )
            continue
        issues_to_create.append(build_github_issue(finding))

    if not issues_to_create:
        message = "All matching Security Hub findings were ignored."
        logger.info(message)
        return {"statusCode": 200, "body": json.dumps({"message": message})}

    audience = os.getenv("WEB_IDENTITY_AUDIENCE")
    duration_seconds_raw = os.getenv("WEB_IDENTITY_DURATION_SECONDS", "600")
    github_org = os.getenv("GITHUB_ORG")
    identity = os.getenv("GITHUB_IDENTITY")
    repo = os.getenv("GITHUB_REPO")
    signing_algorithm = os.getenv("WEB_IDENTITY_SIGNING_ALGORITHM", "RS256")

    for name, value in (
        ("audience", audience),
        ("github_org", github_org),
        ("identity", identity),
        ("repo", repo),
    ):
        if not value:
            raise ValueError(f"Missing required parameter: '{name}'")

    try:
        duration_seconds = int(duration_seconds_raw)
    except (TypeError, ValueError) as error:
        raise ValueError("Parameter 'duration_seconds' must be an integer") from error
    if duration_seconds < 60 or duration_seconds > 600:
        raise ValueError("Parameter 'duration_seconds' must be between 60 and 600")
    if signing_algorithm != "RS256":
        raise ValueError("Parameter 'signing_algorithm' must be RS256")

    web_identity_token, _ = get_web_identity_token(
        audience=audience,
        duration_seconds=duration_seconds,
        signing_algorithm=signing_algorithm,
    )
    github_token = get_github_token(
        audience=audience,
        github_org=github_org,
        identity=identity,
        repo=repo,
        web_identity_token=web_identity_token,
    )

    created_issues = [
        create_github_issue(
            github_org=github_org,
            github_token=github_token,
            repo=repo,
            issue=issue,
        )
        for issue in issues_to_create
    ]
    return {
        "statusCode": 200,
        "body": json.dumps(
            {
                "message": f"Created {len(created_issues)} GitHub issue(s) in {github_org}/{repo}.",
                "issues": [
                    {
                        "issue_number": issue["number"],
                        "issue_url": issue["html_url"],
                    }
                    for issue in created_issues
                ],
            }
        ),
    }
