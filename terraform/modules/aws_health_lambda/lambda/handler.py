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


def create_github_issue(github_org, github_token, repo, issue):
    url = f"https://api.github.com/repos/{github_org}/{repo}/issues"

    try:
        response = requests.post(
            url,
            headers={
                "Authorization": f"Bearer {github_token}",
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
    except requests.RequestException as e:
        raise RuntimeError(f"GitHub issue creation request failed: {e}") from e

    return response.json()


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

    audience = event.get("audience") or os.getenv("WEB_IDENTITY_AUDIENCE")
    duration_seconds_raw = event.get("duration_seconds") or os.getenv(
        "WEB_IDENTITY_DURATION_SECONDS", "600"
    )
    github_org = event.get("github_org") or os.getenv("GITHUB_ORG")
    identity = event.get("identity") or os.getenv("GITHUB_IDENTITY")
    repo = event.get("repo") or os.getenv("GITHUB_REPO")
    signing_algorithm = event.get("signing_algorithm") or os.getenv(
        "WEB_IDENTITY_SIGNING_ALGORITHM", "RS256"
    )

    for var in ["audience", "github_org", "identity", "repo"]:
        if not locals()[var]:
            raise ValueError(f"Missing required parameter: '{var}'")

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
