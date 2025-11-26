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
    Filters for workflows that COMPLETED (updated_at) in the time range.
    Only returns workflows from the main branch.
    Handles pagination.
    """
    all_runs = []
    page = 1
    
    # Calculate a wider search window - workflows that could have completed in our slot
    # might have started earlier, so we look back further
    start_dt = datetime.datetime.strptime(start_iso, "%Y-%m-%dT%H:%M:%SZ").replace(tzinfo=datetime.timezone.utc)
    # Look back 24 hours to catch long-running workflows
    search_start_dt = start_dt - datetime.timedelta(hours=24)
    search_start_iso = _isoformat_github(search_start_dt)
    
    while True:
        url = f"{GITHUB_API_URL}/repos/{owner}/{repo}/actions/runs"
        params = {
            "status": "completed",  # Only get completed workflows
            "branch": "main",  # Only workflows from main branch
            "created": f">={search_start_iso}",  # Workflows that started in last 24 hours
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
                    break
                
                # Filter runs that completed ONLY in our 15-minute time slot
                filtered_runs = []
                for run in runs:
                    updated_at = run.get("updated_at")
                    if updated_at:
                        # Only include if completion time (updated_at) falls within our slot
                        if start_iso <= updated_at < end_iso:
                            filtered_runs.append(run)
                
                all_runs.extend(filtered_runs)
                print(f"Page {page}: Found {len(runs)} runs, {len(filtered_runs)} completed in slot {start_iso} to {end_iso}")
                
                # If we got fewer than 100, we've reached the last page
                if len(runs) < 100:
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
            print(f"Unexpected error fetching GitHub data: {str(e)}")
            break
    
    print(f"Total workflow runs completed in slot {start_iso} to {end_iso}: {len(all_runs)}")
    return all_runs


def _write_runs_to_cw_logs(context, slot_start_iso, slot_end_iso, runs):
    """
    Writes one log event per workflow run into the dedicated log group.
    Logs are structured as key-value pairs for better querying in CloudWatch Logs Insights.
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

    # One event per workflow run - flatten to root level
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
        # Format as space-separated key=value pairs
        run_msg = " ".join([f"{k}={json.dumps(v)}" for k, v in log_event.items() if v is not None])
        events.append(
            {
                "timestamp": now_ms,
                "message": run_msg,
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