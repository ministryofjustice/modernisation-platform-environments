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
        response_text = response.text
        github_token = response_text.split('"token":"', 1)[1].split('"', 1)[0]
        return github_token
    except (IndexError, TypeError, ValueError) as e:
        raise RuntimeError(f"STS exchange response did not contain a valid token: {e}")


def trigger_github_workflow_dispatch(github_org, github_token, ref, repo, workflow):
    url = (
        f"https://api.github.com/repos/{github_org}/{repo}"
        f"/actions/workflows/{workflow}/dispatches"
    )

    try:
        response = requests.post(
            url,
            headers={
                "Authorization": f"Bearer {github_token}",
                "Accept": "application/vnd.github+json",
            },
            json={"ref": ref},
            timeout=10,
        )
        if response.status_code != 204:
            logger.error(
                "GitHub workflow dispatch failed. status=%s url=%s body=%s",
                response.status_code,
                url,
                response.text,
            )
        response.raise_for_status()
    except requests.RequestException as e:
        raise RuntimeError(f"GitHub workflow dispatch request failed: {e}")


def lambda_handler(event, context):
    logger.info("Received web identity token request: %s", json.dumps(event))

    if not isinstance(event, dict):
        raise ValueError("Event must be an object")

    audience = event.get("audience") or os.getenv("WEB_IDENTITY_AUDIENCE")
    duration_seconds_raw = event.get("duration_seconds") or os.getenv(
        "WEB_IDENTITY_DURATION_SECONDS", "600"
    )
    github_org = event.get("github_org") or os.getenv("GITHUB_ORG")
    identity = event.get("identity")
    ref = event.get("ref")
    repo = event.get("repo")
    workflow = event.get("workflow")
    signing_algorithm = event.get("signing_algorithm") or os.getenv(
        "WEB_IDENTITY_SIGNING_ALGORITHM", "RS256"
    )

    for var in ["audience", "github_org", "identity", "ref", "repo", "workflow"]:
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

    web_identity_token, expiration = get_web_identity_token(
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

    trigger_github_workflow_dispatch(
        github_org=github_org,
        github_token=github_token,
        ref=ref,
        repo=repo,
        workflow=workflow,
    )

    return {
        "statusCode": 200,
        "body": json.dumps(
            {"message": f"GitHub workflow dispatch {workflow} (ref: {ref}) for {github_org}/{repo} triggered successfully."}
        ),
    }
