import os
import json
import logging
import requests
from datetime import datetime, timezone

# Setup logger
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Config
REPO_OWNER = "ministryofjustice"
REPO_NAME = "modernisation-platform"
GITHUB_TOKEN = os.environ.get("GITHUB_PAT")

def fetch_all_runs():
    all_runs = []
    page = 1
    per_page = 100
    today = datetime.now(timezone.utc).date()

    headers = {
        "Authorization": f"Bearer {GITHUB_TOKEN}",
        "Accept": "application/vnd.github+json",
        "User-Agent": "workflow-run-fetcher"
    }

    while True:
        url = f"https://api.github.com/repos/{REPO_OWNER}/{REPO_NAME}/actions/runs"
        params = {"per_page": per_page, "page": page}
        response = requests.get(url, headers=headers, params=params)

        if response.status_code != 200:
            logger.error(f"GitHub API error {response.status_code}: {response.text}")
            raise Exception("GitHub API request failed")

        data = response.json()
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

        if found_older or "next" not in response.links:
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
        if not GITHUB_TOKEN:
            raise Exception("GITHUB_PAT environment variable is not set.")

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
