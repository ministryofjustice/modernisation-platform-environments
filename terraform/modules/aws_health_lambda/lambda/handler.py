import boto3
import json
import logging
import os
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
    except requests.RequestException as e:
        raise RuntimeError(f"STS exchange request failed: {e}")

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
        not account.strip()
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


def build_github_issue(event):
    detail = event["detail"]
    title = f"{event['detail-type']}: {detail['eventTypeCode']} - {event['account']}"
    sections = [f"## Start time\n{detail['startTime']}"]

    if detail.get("endTime"):
        sections.append(f"## End time\n{detail['endTime']}")
    if event.get("resources"):
        resources = "\n".join(f"- {resource}" for resource in event["resources"])
        sections.append(f"## Resources\n{resources}")
    if detail.get("affectedEntities"):
        entities = json.dumps(detail["affectedEntities"], indent=2)
        sections.append(f"## Affected entities\n```json\n{entities}\n```")

    descriptions = "\n\n".join(
        description["latestDescription"] for description in detail["eventDescription"]
    )
    sections.extend(
        [
            f"## Service\n{detail['service']}",
            f"## Description\n{descriptions}",
            f"## Region\n{detail['eventRegion']}",
            f"## Event scope\n{detail['eventScopeCode']}",
        ]
    )
    return {
        "title": title,
        "body": "\n\n".join(sections),
        "labels": ["support", "aws_health_event"],
    }


def github_headers(github_token):
    return {
        "Authorization": "Bearer " + github_token,
        "Accept": "application/vnd.github+json",
        "X-GitHub-Api-Version": "2022-11-28",
    }


def github_graphql(github_token, query, variables):
    try:
        response = requests.post(
            "https://api.github.com/graphql",
            headers=github_headers(github_token),
            json={"query": query, "variables": variables},
            timeout=10,
        )
        response.raise_for_status()
    except requests.RequestException as error:
        logger.error("GitHub Projects API request failed: %s", error)
        raise RuntimeError("GitHub Projects API request failed") from error

    try:
        payload = response.json()
    except ValueError as error:
        logger.error("GitHub Projects API response was not valid JSON")
        raise RuntimeError("GitHub Projects API response was not valid JSON") from error
    if (
        not isinstance(payload, dict)
        or payload.get("errors")
        or not isinstance(payload.get("data"), dict)
    ):
        logger.error("GitHub Projects API returned errors: %s", payload)
        raise RuntimeError("GitHub Projects API returned errors or invalid data")
    return payload["data"]


def get_github_project_source(github_org, github_token, project_number, source):
    data = github_graphql(
        github_token,
        """
        query($org: String!, $number: Int!) {
          organization(login: $org) {
            projectV2(number: $number) {
              id
              field(name: "Source") {
                ... on ProjectV2SingleSelectField { id options { id name } }
              }
            }
          }
        }
        """,
        {"org": github_org, "number": project_number},
    )
    organization = data.get("organization") or {}
    project = organization.get("projectV2") or {}
    field = project.get("field") or {}
    option = next(
        (item for item in field.get("options", []) if item.get("name") == source), None
    )
    if not project.get("id") or not field.get("id") or not option or not option.get("id"):
        logger.error("GitHub project %s has no Source option %r", project_number, source)
        raise RuntimeError(f"GitHub project {project_number} has no Source option {source!r}")
    return project["id"], field["id"], option["id"]


def add_issue_to_github_project(github_token, issue_id, project_id, field_id, option_id):
    data = github_graphql(
        github_token,
        """
        mutation($project: ID!, $issue: ID!) {
          addProjectV2ItemById(input: {projectId: $project, contentId: $issue}) {
            item { id }
          }
        }
        """,
        {"project": project_id, "issue": issue_id},
    )
    item = (data.get("addProjectV2ItemById") or {}).get("item") or {}
    if not item.get("id"):
        raise RuntimeError("GitHub Projects API did not return a project item ID")
    data = github_graphql(
        github_token,
        """
        mutation($project: ID!, $item: ID!, $field: ID!, $option: String!) {
          updateProjectV2ItemFieldValue(input: {
            projectId: $project, itemId: $item, fieldId: $field,
            value: {singleSelectOptionId: $option}
          }) { projectV2Item { id } }
        }
        """,
        {"project": project_id, "item": item["id"], "field": field_id, "option": option_id},
    )
    updated = (data.get("updateProjectV2ItemFieldValue") or {}).get("projectV2Item") or {}
    if updated.get("id") != item["id"]:
        raise RuntimeError("GitHub Projects API did not confirm the Source update")


def create_github_issue(github_org, github_token, repo, issue, project_number, source):
    project_id, field_id, option_id = get_github_project_source(
        github_org, github_token, project_number, source
    )
    url = f"https://api.github.com/repos/{github_org}/{repo}/issues"

    try:
        response = requests.post(
            url,
            headers=github_headers(github_token),
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
    except requests.RequestException as e:
        raise RuntimeError(f"GitHub issue creation request failed: {e}") from e

    created_issue = response.json()
    try:
        add_issue_to_github_project(
            github_token, created_issue["node_id"], project_id, field_id, option_id
        )
    except (RuntimeError, KeyError) as error:
        message = (
            f"Created GitHub issue {created_issue.get('html_url', 'unknown')} but failed to set its project Source"
        )
        logger.error("%s; manual reconciliation may be required", message)
        raise RuntimeError(message) from error
    return created_issue


def lambda_handler(event, context):
    logger.info("Received AWS Health event: %s", json.dumps(event))

    if not isinstance(event, dict):
        raise ValueError("Event must be an object")

    affected_entities = event["detail"].get("affectedEntities")
    if affected_entities and all(
        entity.get("status") == "RESOLVED" for entity in affected_entities
    ):
        message = (
            "All affected entities are RESOLVED; this is a resolved event, "
            "therefore not generating a ticket."
        )
        logger.info(
            "%s Event ARN: %s; account: %s",
            message,
            event["detail"].get("eventArn"),
            event.get("account"),
        )
        return {
            "statusCode": 200,
            "body": json.dumps({"message": message}),
        }

    ignored_description = get_ignored_findings().get(str(event["account"]))
    if ignored_description is not None and any(
        ignored_description in description["latestDescription"]
        for description in event["detail"]["eventDescription"]
    ):
        message = (
            "AWS Health event matches an ignored finding; "
            "not generating a ticket."
        )
        logger.info(
            "%s Event ARN: %s; account: %s",
            message,
            event["detail"].get("eventArn"),
            event["account"],
        )
        return {
            "statusCode": 200,
            "body": json.dumps({"message": message}),
        }

    audience = event.get("audience") or os.getenv("WEB_IDENTITY_AUDIENCE")
    duration_seconds_raw = event.get("duration_seconds") or os.getenv(
        "WEB_IDENTITY_DURATION_SECONDS", "600"
    )
    github_org = event.get("github_org") or os.getenv("GITHUB_ORG")
    identity = event.get("identity") or os.getenv("GITHUB_IDENTITY")
    repo = event.get("repo") or os.getenv("GITHUB_REPO")
    project_number_raw = os.getenv("GITHUB_PROJECT_NUMBER")
    source = os.getenv("GITHUB_ISSUE_SOURCE", "Support")
    signing_algorithm = event.get("signing_algorithm") or os.getenv(
        "WEB_IDENTITY_SIGNING_ALGORITHM", "RS256"
    )

    for name, value in (
        ("audience", audience),
        ("github_org", github_org),
        ("identity", identity),
        ("repo", repo),
        ("github_project_number", project_number_raw),
        ("github_issue_source", source.strip()),
    ):
        if not value:
            raise ValueError(f"Missing required parameter: '{name}'")

    try:
        project_number = int(project_number_raw)
    except ValueError as error:
        raise ValueError("GITHUB_PROJECT_NUMBER must be a positive integer") from error
    if project_number <= 0:
        raise ValueError("GITHUB_PROJECT_NUMBER must be a positive integer")

    try:
        duration_seconds = int(duration_seconds_raw)
    except (TypeError, ValueError) as error:
        raise ValueError("Parameter 'duration_seconds' must be an integer") from error
    if duration_seconds < 60 or duration_seconds > 600:
        raise ValueError("Parameter 'duration_seconds' must be between 60 and 600")
    if signing_algorithm not in {"RS256"}:
        raise ValueError("Parameter 'signing_algorithm' must be RS256")

    issue = build_github_issue(event)

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

    created_issue = create_github_issue(
        github_org=github_org,
        github_token=github_token,
        repo=repo,
        issue=issue,
        project_number=project_number,
        source=source,
    )

    return {
        "statusCode": 200,
        "body": json.dumps(
            {
                "message": f"GitHub issue created successfully for {github_org}/{repo}.",
                "issue_number": created_issue["number"],
                "issue_url": created_issue["html_url"],
            }
        ),
    }
