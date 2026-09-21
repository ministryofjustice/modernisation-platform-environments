import boto3
import json
import jwt
import logging
import os
import time
import urllib.error
import urllib.request

logger = logging.getLogger()
logger.setLevel(logging.INFO)

GITHUB_API_URL = "https://api.github.com"
GITHUB_APP_SECRET_ARN = os.environ["GITHUB_APP_SECRET_ARN"]

secrets_manager = boto3.client("secretsmanager")


def get_github_config():
    response = secrets_manager.get_secret_value(SecretId=GITHUB_APP_SECRET_ARN)
    secret_string = response.get("SecretString")

    if not secret_string:
        raise RuntimeError("GitHub secret is empty or not found in Secrets Manager.")

    config = json.loads(secret_string)

    required_keys = [
        "github_app_id",
        "github_app_private_key",
        "github_installation_id",
    ]

    missing_keys = [key for key in required_keys if not config.get(key)]

    if missing_keys:
        raise RuntimeError(
            f"Missing required GitHub config keys: {', '.join(missing_keys)}"
        )

    return config


def create_app_jwt(app_id, private_key):
    now = int(time.time())
    payload = {"iat": now - 60, "exp": now + (9 * 60), "iss": str(app_id)}
    token = jwt.encode(payload, private_key, algorithm="RS256")
    return token


def get_installation_access_token(app_jwt, installation_id):
    url = f"{GITHUB_API_URL}" f"/app/installations/{installation_id}/access_tokens"

    request = urllib.request.Request(
        url,
        method="POST",
        headers={
            "Authorization": f"Bearer {app_jwt}",
            "Accept": "application/vnd.github+json",
            "X-Github-Api-Version": "2022-11-28",
            "User-Agent": "aws-github-workflow-scheduler",
        },
    )

    try:
        with urllib.request.urlopen(request, timeout=10) as response:
            body = response.read().decode("utf-8")
            data = json.loads(body)
            return data["token"]

    except urllib.error.HTTPError as error:
        body = error.read().decode("utf-8")
        logger.error(
            "Failed to obtain GitHub installation access token. HTTP %s: %s",
            error.code,
            body,
        )
        raise RuntimeError(
            f"Failed to obtain GitHub installation access token. HTTP {error.code}"
        ) from error


def trigger_workflow(installation_token, github_org, repo, workflow, ref, inputs):
    url = (
        f"{GITHUB_API_URL}"
        f"/repos/{github_org}/{repo}"
        f"/actions/workflows/{workflow}/dispatches"
    )
    payload = {"ref": ref, "inputs": inputs}
    body = json.dumps(payload).encode("utf-8")
    request = urllib.request.Request(
        url,
        data=body,
        method="POST",
        headers={
            "Authorization": f"Bearer {installation_token}",
            "Accept": "application/vnd.github+json",
            "X-Github-Api-Version": "2022-11-28",
            "Content-Type": "application/json",
            "User-Agent": "aws-github-workflow-scheduler",
        },
    )

    try:
        with urllib.request.urlopen(request, timeout=10) as response:
            if response.status != 204:
                raise RuntimeError(f"Unexpected response status: {response.status}")
            logger.info(
                "Successfully triggered workflow '%s' in repo '%s' on ref '%s'",
                workflow,
                repo,
                ref,
            )
    except urllib.error.HTTPError as error:
        body = error.read().decode("utf-8")
        logger.error(
            "Failed to trigger GitHub workflow. HTTP %s: %s", error.code, body
        )
        raise RuntimeError(
            f"Failed to trigger GitHub workflow. HTTP {error.code}"
        ) from error


def lambda_handler(event, context):
    logger.info("Received workflow trigger request: %s", json.dumps(event))
    inputs = event.get("inputs", {})
    github_org = event.get("org") or os.getenv("GITHUB_ORG")
    ref = event.get("ref", "main")
    repo = event.get("repo")
    workflow = event.get("workflow")

    if inputs is None:
        inputs = {}
    if not isinstance(inputs, dict):
        raise ValueError("Parameter 'inputs' must be an object")
    if not github_org:
        raise ValueError("Missing required parameter: 'org'")
    if not ref:
        raise ValueError("Missing required parameter: 'ref'")
    if not repo:
        raise ValueError("Missing required parameter: 'repo'")
    if not workflow:
        raise ValueError("Missing required parameter: 'workflow'")

    github_config = get_github_config()
    app_id = github_config["github_app_id"]
    installation_id = github_config["github_installation_id"]
    private_key = github_config["github_app_private_key"]

    app_jwt = create_app_jwt(app_id=app_id, private_key=private_key)

    installation_token = get_installation_access_token(
        app_jwt=app_jwt, installation_id=installation_id
    )

    trigger_workflow(
        installation_token=installation_token,
        github_org=github_org,
        repo=repo,
        workflow=workflow,
        ref=ref,
        inputs=inputs,
    )

    return {
        "statusCode": 200,
        "body": json.dumps(
            {
                "message": "Workflow triggered successfully.",
                "org": github_org,
                "repo": repo,
                "workflow": workflow,
                "ref": ref,
            }
        ),
    }
