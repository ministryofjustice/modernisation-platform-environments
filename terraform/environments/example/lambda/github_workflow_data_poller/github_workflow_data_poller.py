import os
import json
import datetime
from urllib import request, parse, error

import boto3
from botocore.exceptions import ClientError

GITHUB_API_URL = os.environ.get("GITHUB_API_URL", "https://api.github.com")
OWNER = os.environ["GITHUB_OWNER"]
REPO = os.environ["GITHUB_REPO"]
SLOT_MINUTES = int(os.environ.get("SLOT_MINUTES", "15"))
WORKFLOW_RUN_LOG_GROUP = os.environ["WORKFLOW_RUN_LOG_GROUP"]

logs_client = boto3.client("logs")


def _nearest_slot(now_utc: datetime.datetime, slot_minutes: int):
    """
    Return (start, end) UTC datetime for the nearest N-minute slot of the current hour.
    Example for 15 min: [00-15), [15-30), [30-45), [45-60)
    """
    if now_utc.tzinfo is None:
        now_utc = now_utc.replace(tzinfo=datetime.timezone.utc)

    minute = now_utc.minute
    slot_index = minute // slot_minutes
    slot_start_min = slot_index * slot_minutes

    slot_start = now_utc.replace(minute=slot_start_min, second=0, microsecond=0)
    slot_end = slot_start + datetime.timedelta(minutes=slot_minutes)

    return slot_start, slot_end


def _isoformat_github(dt: datetime.datetime) -> str:
    if dt.tzinfo is None:
        dt = dt.replace(tzinfo=datetime.timezone.utc)
    return dt.astimezone(datetime.timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def _fetch_all_runs(owner: str, repo: str, start_iso: str, end_iso: str):
    """
    Fetch workflow runs from GitHub Actions API for the given time range.
    Returns ALL workflows created in the last 6 hours from the main branch.
    Client-side filters for workflows that were created OR updated in the 15-minute slot.
    """
    all_runs = []
    page = 1
    max_pages = 10
    
    # Look back 6 hours from slot start
    start_dt = datetime.datetime.strptime(start_iso, "%Y-%m-%dT%H:%M:%SZ").replace(tzinfo=datetime.timezone.utc)
    search_start_dt = start_dt - datetime.timedelta(hours=6)
    search_start_iso = _isoformat_github(search_start_dt)
    
    print(f"Searching for workflows created since {search_start_iso}")
    print(f"Filtering for activity in slot: {start_iso} to {end_iso}")
    
    while page <= max_pages:
        url = f"{GITHUB_API_URL}/repos/{owner}/{repo}/actions/runs"
        params = {
            "branch": "main",
            "created": f">={search_start_iso}",  # All workflows created in last 6 hours
            "per_page": "100",
            "page": str(page)
        }
        
        query_string = parse.urlencode(params)
        full_url = f"{url}?{query_string}"
        
        print(f"Fetching from GitHub API (page {page}): {full_url}")
        
        try:
            req = request.Request(full_url)
            req.add_header("Accept", "application/vnd.github+json")
            req.add_header("X-GitHub-Api-Version", "2022-11-28")
            
            github_token = os.environ.get("GITHUB_TOKEN")
            if github_token:
                req.add_header("Authorization", f"Bearer {github_token}")
            
            with request.urlopen(req, timeout=30) as response:
                data = json.loads(response.read().decode("utf-8"))
                runs = data.get("workflow_runs", [])
                
                if not runs:
                    print("No more runs returned from API")
                    break
                
                # Return ALL workflows - no filtering
                # They will all be written to CloudWatch logs
                all_runs.extend(runs)
                
                for run in runs:
                    print(f"  Run {run.get('id')}: created={run.get('created_at')}, updated={run.get('updated_at')}, status={run.get('status')}, conclusion={run.get('conclusion')}")
                
                print(f"Page {page}: Found {len(runs)} runs")
                
                if len(runs) < 100:
                    print("Reached last page")
                    break
                
                page += 1
                
        except error.HTTPError as e:
            print(f"GitHub HTTP error: {e.code} - {e.reason}")
            try:
                print(f"Response: {e.read().decode('utf-8')}")
            except:
                pass
            break
        except error.URLError as e:
            print(f"GitHub URL error: {e.reason}")
            break
        except Exception as e:
            print(f"Unexpected error: {str(e)}")
            break
    
    print(f"Total runs found: {len(all_runs)}")
    return all_runs


def _write_runs_to_cw_logs(context, slot_start_iso, slot_end_iso, runs):
    """
    Writes one log event per workflow run into the dedicated log group.
    Logs are structured as JSON for automatic parsing in CloudWatch Logs Insights.
    """
    log_group_name = WORKFLOW_RUN_LOG_GROUP
    log_stream_name = context.aws_request_id  # unique per invocation

    # Create log stream if it doesn't exist yet
    try:
        logs_client.create_log_stream(
            logGroupName=log_group_name, logStreamName=log_stream_name
        )
    except ClientError as e:
        if e.response["Error"]["Code"] != "ResourceAlreadyExistsException":
            raise

    # Build log events
    now_ms = int(datetime.datetime.now(datetime.timezone.utc).timestamp() * 1000)
    events = []

    # One event per workflow run - format as JSON
    for r in runs:
        log_event = {
            "type": "WORKFLOW_RUN",
            "repository": f"{OWNER}/{REPO}",
            "slot_start": slot_start_iso,
            "slot_end": slot_end_iso,
            "id": r.get("id"),
            "run_number": r.get("run_number"),
            "workflow_name": r.get("name"),
            "status": r.get("status"),
            "conclusion": r.get("conclusion"),
            "created_at": r.get("created_at"),
            "updated_at": r.get("updated_at"),
            "run_attempt": r.get("run_attempt"),
            "event": r.get("event"),
            "workflow_id": r.get("workflow_id"),
            "head_branch": r.get("head_branch"),
            "head_sha": r.get("head_sha"),
            "actor": (r.get("actor") or {}).get("login"),
            "triggering_actor": (r.get("triggering_actor") or {}).get("login")
            if r.get("triggering_actor")
            else None,
            "html_url": r.get("html_url"),
        }
        
        # Remove None values
        log_event = {k: v for k, v in log_event.items() if v is not None}
        
        # CHANGED: Format as JSON instead of key=value pairs
        events.append(
            {
                "timestamp": now_ms,
                "message": json.dumps(log_event),  # JSON format
            }
        )
        now_ms += 1

    # Single PutLogEvents call
    logs_client.put_log_events(
        logGroupName=log_group_name,
        logStreamName=log_stream_name,
        logEvents=events,
    )

def lambda_handler(event, context):
    now_utc = datetime.datetime.now(datetime.timezone.utc)
    start_dt, end_dt = _nearest_slot(now_utc, SLOT_MINUTES)

    start_iso = _isoformat_github(start_dt)
    end_iso = _isoformat_github(end_dt)

    # Small info in normal Lambda log
    print(f"Polling repository {OWNER}/{REPO} for slot {start_iso} .. {end_iso}")

    runs = _fetch_all_runs(OWNER, REPO, start_iso, end_iso)

    # Only write to custom log if there are workflow runs
    if runs:
        # Write workflow run data into dedicated log group
        _write_runs_to_cw_logs(context, start_iso, end_iso, runs)
        print(f"Wrote {len(runs)} workflow runs into {WORKFLOW_RUN_LOG_GROUP}")
    else:
        print(f"No workflow runs found for slot {start_iso} .. {end_iso} - skipping custom log write")

    return {
        "slot_start": start_iso,
        "slot_end": end_iso,
        "count": len(runs),
    }