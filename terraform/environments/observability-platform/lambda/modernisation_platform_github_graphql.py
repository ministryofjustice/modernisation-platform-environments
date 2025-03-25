import json
import os
import urllib.request
import logging
from datetime import datetime, timezone

logger = logging.getLogger()
logger.setLevel(logging.INFO)

GITHUB_API_URL = "https://api.github.com/graphql"
GITHUB_TOKEN = os.environ.get("GITHUB_PAT")

REPO_OWNER = "ministryofjustice"
REPO_NAME = "modernisation-platform"

logger.info("Building query")

def build_query(after_cursor=None):
    after = f', after: "{after_cursor}"' if after_cursor else ''
    return f"""
    {{
      repository(owner: "{REPO_OWNER}", name: "{REPO_NAME}") {{
        actionsWorkflowRuns(first: 100{after}) {{
          pageInfo {{
            hasNextPage
            endCursor
          }}
          nodes {{
            id
            workflow {{ name }}
            status
            conclusion
            runStartedAt
            updatedAt
            url
          }}
        }}
      }}
    }}
    """

def fetch_all_runs():
    all_runs = []
    cursor = None
    has_next_page = True

    headers = {
        "Authorization": f"Bearer {GITHUB_TOKEN}",
        "Content-Type": "application/json",
        "User-Agent": "grafana-lambda-proxy"
    }

    while has_next_page:
        query = build_query(cursor)
        req = urllib.request.Request(
            GITHUB_API_URL,
            data=json.dumps({"query": query}).encode("utf-8"),
            headers=headers
        )
        with urllib.request.urlopen(req) as response:
            result = json.loads(response.read())

        data = result["data"]["repository"]["actionsWorkflowRuns"]
        all_runs.extend(data["nodes"])
        has_next_page = data["pageInfo"]["hasNextPage"]
        cursor = data["pageInfo"]["endCursor"]

    return all_runs

def lambda_handler(event, context):
    today = datetime.now(timezone.utc).date()
    try:
    
        logger.info(f"Fetching all workflow runs for: {today} from {REPO_OWNER}/{REPO_NAME}")

        all_runs = fetch_all_runs()

        # Log every workflow run's ID and timestamp for debugging
        for run in all_runs:
            run_id = run.get("id")
            started_at = run.get("runStartedAt")
            logger.info(f"Workflow ID: {run_id}, Started At: {started_at}")

        # Filter for failed/cancelled/timed out runs from today
        filtered_runs = [
            run for run in all_runs
            if run["conclusion"] in ["failure", "cancelled", "timed_out"]
            and datetime.fromisoformat(run["runStartedAt"].replace("Z", "+00:00")).date() == today
        ]

        detailed_runs = [
            {
                "id": run.get("id"),
                "name": run.get("name"),
                "status": run.get("status"),
                "conclusion": run.get("conclusion"),
                "run_started_at": run.get("runStartedAt"),
                "html_url": run.get("html_url")
            }
            for run in filtered_runs
        ]


        return {
            "statusCode": 200,
            "headers": {"Content-Type": "application/json"},
            "body": json.dumps(filtered_runs)
        }
    except Exception as e:
        return {
            "statusCode": 500,
            "body": json.dumps({"error": str(e)})
        }