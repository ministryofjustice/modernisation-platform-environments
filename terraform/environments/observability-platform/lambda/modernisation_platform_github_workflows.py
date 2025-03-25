import os
import boto3
import json
import logging
import urllib.request
import urllib.parse
from datetime import datetime, timezone

# Setup logger
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Config
REPO_OWNER = "ministryofjustice"
REPO_NAME = "modernisation-platform"

def get_github_pat():
    secret_name = "observability-platform/modernisation-platform-github-pat"
    region_name = os.environ.get("AWS_REGION", "eu-west-2")

    client = boto3.client("secretsmanager", region_name=region_name)
    response = client.get_secret_value(SecretId=secret_name)

    secret = response["SecretString"]
    secret_dict = json.loads(secret)
    return secret_dict.get("pat")

def fetch_all_runs():
    all_runs = []
    page = 1
    per_page = 100
    today = datetime.now(timezone.utc).date()

    GITHUB_TOKEN = get_github_pat

    if not GITHUB_TOKEN:
        raise ValueError("GitHub PAT not found in Secrets")

    headers = {
        "Authorization": f"Bearer {GITHUB_TOKEN}",
        "Accept": "application/vnd.github+json",
        "User-Agent": "workflow-run-fetcher"
    }

    while True:
        # Build the URL with query params
        params = urllib.parse.urlencode({"per_page": per_page, "page": page})
        url = f"https://api.github.com/repos/{REPO_OWNER}/{REPO_NAME}/actions/runs?{params}"

        req = urllib.request.Request(url, headers=headers)

        try:
            with urllib.request.urlopen(req) as response:
                body = response.read()
                data = json.loads(body)
                link_header = response.headers.get("Link", "")
        except Exception as e:
            logger.error(f"GitHub API request failed: {e}")
            raise

        runs = data.get("workflow_runs", [])
        logger.info(f"📄 Retrieved {len(runs)} runs on page {page}")

        found_older = False

        for run in runs:
            run_date = datetime.fromisoformat(run["run_started_at"].replace("Z", "+00:00")).date()
            if run_date == today:
                all_runs.append(run)
            elif run_date < today:
                found_older = True
                break

        # Stop if we found older runs or there's no "next" link
        if found_older or 'rel="next"' not in link_header:
            break

        page += 1

    return all_runs

def filter_failed_runs(runs):
    return [
        {
            "id": run.get("id"),
            "name": run.get("name"),
            "status": run.get("status"),
            "conclusion": run.get("conclusion"),
            "run_started_at": run.get("run_started_at"),
            "html_url": run.get("html_url")
        }
        for run in runs
        if run.get("conclusion") in ["failure", "cancelled", "timed_out"]
    ]

def lambda_handler(event, context):
    today = datetime.now(timezone.utc).date()
    logger.info(f"📅 Fetching today's workflow runs from {REPO_OWNER}/{REPO_NAME} for {today}")

    try:

        all_runs = fetch_all_runs()

        for run in all_runs:
            logger.info(f"🧪 Run ID: {run['id']} | Started: {run['run_started_at']} | Conclusion: {run['conclusion']}")

        failed_runs = filter_failed_runs(all_runs)

        return {
            "statusCode": 200,
            "headers": {"Content-Type": "application/json"},
            "body": json.dumps(failed_runs)
        }

    except Exception as e:
        logger.error(f"❌ Lambda execution failed: {e}", exc_info=True)
        return {
            "statusCode": 500,
            "headers": {"Content-Type": "application/json"},
            "body": json.dumps({"error": str(e)})
        }
