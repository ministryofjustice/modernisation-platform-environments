# EventBridge Schedule -> Lambda -> GitHub Workflow Dispatch API -> ONR Environment Start Workflow
import json
import logging
import boto3
import requests
logger = logging.getLogger()
logger.setLevel(logging.INFO)

client = boto3.client("secretsmanager")
secret = client.get_secret_value(
    SecretId="github_pat"
)
github_pat = json.loads(secret["SecretString"])["pat"]

WORKFLOW_FILE = "onr_environment_start_poc.yml"
BRANCH = "main"


def lambda_handler(event, context):

    payload = {
        "ref": BRANCH,
        "inputs": {
            "onr_environment": "pp",
            "pipeline_stages": "all",
            "force": "false",
            "dryrun": "false",
            "verbose": "false",
            "ccm_gap_secs": "2",
            "ec2_gap_secs": "30",
        },
    }

    url = (
        f"https://api.github.com/repos/"
        f"ministryofjustice/dso-modernisation-platform-automation/actions/workflows/"
        f"{WORKFLOW_FILE}/dispatches"
    )

    response = requests.post(
        url,
        headers={
            "Accept": "application/vnd.github+json",
            "Authorization": f"Bearer {github_pat}",
            "X-GitHub-Api-Version": "2022-11-28",
        },
        json=payload,
        timeout=30,
    )

    logger.info(
        "GitHub response status=%s body=%s",
        response.status_code,
        response.text,
    )

    response.raise_for_status()

    return {
        "statusCode": response.status_code,
        "workflow": WORKFLOW_FILE,
        "repository": f"ministryofjustice/dso-modernisation-platform-automation",
    }