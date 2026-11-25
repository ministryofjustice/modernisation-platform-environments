"""Data quality checks for the nightly DMS full loads.

Triggered three ways:
- DMS task finished (EventBridge): record row counts and load duration, alert on drops and slow loads
- {"action": "deadline", "pipeline": ...} (schedule): alert if the pipeline has not finished
- {"action": "digest"} (schedule): post a summary of every pipeline's run today
"""

import json
import logging
import os
import statistics
import time
from datetime import datetime, timedelta, timezone
from typing import Optional

import boto3

logger = logging.getLogger()
logger.setLevel(os.getenv("LOG_LEVEL", "INFO"))

NAMESPACE = "DMS/DataQuality"
HISTORY_DAYS = 7
MIN_HISTORY_RUNS = 3
FINISHED_REASON = "FULL_LOAD_ONLY_FINISHED"
COMPLETED_TABLE_STATE = "Table completed"
LOADING_TABLE_STATES = {"Before load", "Full load", "Table is being reloaded"}
SETTLE_ATTEMPTS = 10
SETTLE_WAIT_SECONDS = 30
RUNNING_STATUSES = {"starting", "running", "stopping"}
DURATION_KEY = "__duration__"
TOTAL_ROWS_KEY = "__total_rows__"

PIPELINES = json.loads(os.getenv("PIPELINES", "{}"))
ALERTS_TOPIC_ARN = os.getenv("ALERTS_TOPIC_ARN", "")
ROW_DROP_PERCENT = float(os.getenv("ROW_DROP_PERCENT", "20"))
ROW_DROP_MIN_ROWS = int(os.getenv("ROW_DROP_MIN_ROWS", "1000"))
DURATION_OVERRUN_PERCENT = float(os.getenv("DURATION_OVERRUN_PERCENT", "50"))
DURATION_OVERRUN_MIN_MINUTES = float(os.getenv("DURATION_OVERRUN_MIN_MINUTES", "10"))

dms = boto3.client("dms")
cloudwatch = boto3.client("cloudwatch")
sns = boto3.client("sns")


def handler(event, context):  # pylint: disable=unused-argument
    logger.info("Event: %s", json.dumps(event, default=str))
    if event.get("source") == "aws.dms":
        check_run(pipeline_for_task(event["resources"][0]))
    elif event.get("action") == "deadline":
        check_deadline(event["pipeline"])
    elif event.get("action") == "digest":
        send_digest()
    else:
        raise ValueError(f"Unrecognised event: {json.dumps(event, default=str)}")


def pipeline_for_task(task_arn: str) -> str:
    for pipeline, config in PIPELINES.items():
        if config["task_arn"] == task_arn:
            return pipeline
    raise ValueError(f"No pipeline configured for task {task_arn}")


def today_start(now: Optional[datetime] = None) -> datetime:
    now = now or datetime.now(timezone.utc)
    return now.replace(hour=0, minute=0, second=0, microsecond=0)


def row_drop_baseline(rows: float, history: list[float]) -> Optional[float]:
    """Returns the usual row count if rows dropped beyond both thresholds, else None."""
    if len(history) < MIN_HISTORY_RUNS:
        return None
    usual = statistics.median(history)
    drop = usual - rows
    if usual > 0 and drop >= ROW_DROP_MIN_ROWS and drop / usual * 100 >= ROW_DROP_PERCENT:
        return usual
    return None


def duration_overrun_baseline(minutes: float, history: list[float]) -> Optional[float]:
    """Returns the usual duration if the load overran beyond both thresholds, else None."""
    if len(history) < MIN_HISTORY_RUNS:
        return None
    usual = statistics.median(history)
    overrun = minutes - usual
    if usual > 0 and overrun >= DURATION_OVERRUN_MIN_MINUTES and overrun / usual * 100 >= DURATION_OVERRUN_PERCENT:
        return usual
    return None


def run_status(task: dict, since: datetime) -> tuple[str, str]:
    """Classifies the run started since `since` as finished, running, missing or failed."""
    stats = task.get("ReplicationTaskStats", {})
    started = stats.get("StartDate") or task.get("ReplicationTaskStartDate")
    if not started or started < since:
        return "missing", f"Did not start today (last start: {format_time(started)})"

    status = task.get("Status", "")
    if status in RUNNING_STATUSES:
        return "running", (
            f"Still {status}: {stats.get('FullLoadProgressPercent', 0)}% loaded, "
            f"{stats.get('TablesLoaded', 0)} tables done, {stats.get('TablesLoading', 0)} loading, "
            f"{stats.get('TablesQueued', 0)} queued, {stats.get('TablesErrored', 0)} errored"
        )

    stop_reason = task.get("StopReason") or ""
    if FINISHED_REASON in stop_reason:
        return "finished", ""
    return "failed", f"Stopped without finishing: status {status}, stop reason {stop_reason or 'none'}"


def format_time(value: Optional[datetime]) -> str:
    return value.astimezone(timezone.utc).strftime("%Y-%m-%d %H:%M UTC") if value else "never"


def format_minutes(minutes: float) -> str:
    if minutes < 1:
        return "<1m"
    hours, mins = divmod(round(minutes), 60)
    return f"{hours}h{mins:02d}m" if hours else f"{mins}m"


def format_percent_change(value: float, usual: float) -> str:
    return f"{(value - usual) / usual * 100:+.0f}%"


def describe_task(task_arn: str) -> dict:
    response = dms.describe_replication_tasks(
        Filters=[{"Name": "replication-task-arn", "Values": [task_arn]}],
        WithoutSettings=True,
    )
    return response["ReplicationTasks"][0]


def table_statistics(task_arn: str) -> list[dict]:
    tables = []
    kwargs = {"ReplicationTaskArn": task_arn, "MaxRecords": 500}
    while True:
        page = dms.describe_table_statistics(**kwargs)
        tables.extend(page.get("TableStatistics", []))
        if not page.get("Marker"):
            return tables
        kwargs["Marker"] = page["Marker"]


def settled_table_statistics(task_arn: str) -> list[dict]:
    """Table statistics can lag the task's stop event, so wait until no table still shows as loading."""
    for attempt in range(1, SETTLE_ATTEMPTS + 1):
        tables = table_statistics(task_arn)
        loading = [t["TableName"] for t in tables if t.get("TableState") in LOADING_TABLE_STATES]
        if not loading or attempt == SETTLE_ATTEMPTS:
            return tables
        logger.info("Attempt %s: tables still loading %s, waiting %ss", attempt, loading, SETTLE_WAIT_SECONDS)
        time.sleep(SETTLE_WAIT_SECONDS)
    return tables


def load_minutes(task: dict) -> float:
    stats = task.get("ReplicationTaskStats", {})
    start, finish = stats.get("FullLoadStartDate"), stats.get("FullLoadFinishDate")
    if start and finish:
        return (finish - start).total_seconds() / 60
    return stats.get("ElapsedTimeMillis", 0) / 60000


def metric_values(queries: dict[str, tuple[str, dict]], start: datetime, end: datetime) -> dict[str, list[float]]:
    """Daily maximums per query key; queries maps key -> (metric name, dimensions)."""
    keys = list(queries)
    results: dict[str, list[float]] = {key: [] for key in keys}
    for offset in range(0, len(keys), 500):
        chunk = keys[offset:offset + 500]
        kwargs = {
            "MetricDataQueries": [
                {
                    "Id": f"q{index}",
                    "MetricStat": {
                        "Metric": {
                            "Namespace": NAMESPACE,
                            "MetricName": queries[key][0],
                            "Dimensions": [{"Name": name, "Value": value} for name, value in queries[key][1].items()],
                        },
                        "Period": 86400,
                        "Stat": "Maximum",
                    },
                }
                for index, key in enumerate(chunk)
            ],
            "StartTime": start,
            "EndTime": end,
        }
        while True:
            page = cloudwatch.get_metric_data(**kwargs)
            for result in page["MetricDataResults"]:
                results[chunk[int(result["Id"][1:])]].extend(result["Values"])
            if not page.get("NextToken"):
                break
            kwargs["NextToken"] = page["NextToken"]
    return results


def put_metrics(metric_data: list[dict]):
    for offset in range(0, len(metric_data), 500):
        cloudwatch.put_metric_data(Namespace=NAMESPACE, MetricData=metric_data[offset:offset + 500])


def metric(name: str, value: float, unit: str, **dimensions: str) -> dict:
    return {
        "MetricName": name,
        "Dimensions": [{"Name": key, "Value": val} for key, val in dimensions.items()],
        "Value": value,
        "Unit": unit,
    }


def publish(lines: list[str]):
    sns.publish(TopicArn=ALERTS_TOPIC_ARN, Message="\n".join(lines))


def check_run(pipeline: str):
    config = PIPELINES[pipeline]
    tables = settled_table_statistics(config["task_arn"])
    task = describe_task(config["task_arn"])
    duration = load_minutes(task)
    rows_by_table = {f"{t['SchemaName']}.{t['TableName']}": t.get("FullLoadRows", 0) for t in tables}
    total_rows = sum(rows_by_table.values())

    today = today_start()
    queries = {table: ("RowsLoaded", {"Pipeline": pipeline, "Table": table}) for table in rows_by_table}
    queries[DURATION_KEY] = ("LoadDurationMinutes", {"Pipeline": pipeline})
    history = metric_values(queries, today - timedelta(days=HISTORY_DAYS), today)

    issues = []
    usual_duration = duration_overrun_baseline(duration, history[DURATION_KEY])
    if usual_duration is not None:
        issues.append(
            f"🐢 Load took {format_minutes(duration)} "
            f"(usual {format_minutes(usual_duration)}, {format_percent_change(duration, usual_duration)})"
        )

    excluded = {table.lower() for table in config.get("exclude_tables", [])}
    for table, rows in sorted(rows_by_table.items()):
        if table.lower() in excluded:
            continue
        usual_rows = row_drop_baseline(rows, history[table])
        if usual_rows is not None:
            issues.append(
                f"📉 {table}: {rows:,.0f} rows (usual {usual_rows:,.0f}, {format_percent_change(rows, usual_rows)})"
            )

    for table in sorted(tables, key=lambda t: (t["SchemaName"], t["TableName"])):
        if table.get("TableState") != COMPLETED_TABLE_STATE:
            issues.append(f"🚫 {table['SchemaName']}.{table['TableName']}: {table.get('TableState', 'unknown state')}")

    put_metrics(
        [metric("RowsLoaded", rows, "Count", Pipeline=pipeline, Table=table) for table, rows in rows_by_table.items()]
        + [
            metric("TotalRowsLoaded", total_rows, "Count", Pipeline=pipeline),
            metric("LoadDurationMinutes", duration, "None", Pipeline=pipeline),
            metric("IssuesFound", len(issues), "Count", Pipeline=pipeline),
        ]
    )

    logger.info(
        "%s: %s rows across %s tables in %s, %s issues",
        pipeline, total_rows, len(tables), format_minutes(duration), len(issues),
    )
    if issues:
        publish([f"⚠️ {pipeline}: DATA QUALITY CHECK"] + issues)


def check_deadline(pipeline: str):
    config = PIPELINES[pipeline]
    state, detail = run_status(describe_task(config["task_arn"]), today_start())
    logger.info("%s deadline check: %s %s", pipeline, state, detail)
    if state != "finished":
        publish([f"⏰ {pipeline}: NOT FINISHED BY {config['deadline']} UTC", detail])


def table_name(table: dict) -> str:
    return f"{table['SchemaName']}.{table['TableName']}"


def usual_suffix(value: float, history: list[float], formatter) -> str:
    if len(history) < MIN_HISTORY_RUNS:
        return ""
    usual = statistics.median(history)
    change = f", {format_percent_change(value, usual)}" if usual else ""
    return f" (usual {formatter(usual)}{change})"


def format_count(value: float) -> str:
    return f"{value:,.0f}"


def pipeline_summary(pipeline: str, config: dict, task: dict, tables: list[dict], history: dict, today: datetime) -> list[str]:
    header = f"{pipeline} ({task.get('ReplicationTaskIdentifier', 'unknown task')})"
    state, detail = run_status(task, today)
    if state == "missing":
        return [f"❌ {header}", detail]

    excluded = {table.lower() for table in config.get("exclude_tables", [])}
    problems = 0
    table_lines = []
    for table in sorted(tables, key=table_name):
        name = table_name(table)
        rows = table.get("FullLoadRows", 0)
        rows_history = history.get(f"{pipeline}|{name}", [])
        parts = [f"{rows:,.0f} rows{usual_suffix(rows, rows_history, format_count)}"]

        table_state = table.get("TableState", "unknown state")
        ended = table.get("FullLoadEndTime")
        if table_state == COMPLETED_TABLE_STATE:
            parts.append(f"done {ended.astimezone(timezone.utc):%H:%M} UTC" if ended else "done")
        elif state == "running" and table_state in LOADING_TABLE_STATES:
            parts.append(f"⏳ {table_state}")
        else:
            parts.append(f"🚫 {table_state}")
            problems += 1

        if state == "finished" and name.lower() not in excluded and row_drop_baseline(rows, rows_history) is not None:
            parts.append("📉 row drop")
            problems += 1
        table_lines.append(f"    • {name}: {', '.join(parts)}")

    if state == "running":
        return [f"⏳ {header}", detail] + table_lines
    if state == "failed":
        return [f"❌ {header}", detail] + table_lines

    duration = load_minutes(task)
    duration_history = history.get(f"{pipeline}|{DURATION_KEY}", [])
    if duration_overrun_baseline(duration, duration_history) is not None:
        problems += 1
    total_rows = sum(t.get("FullLoadRows", 0) for t in tables)
    finished_at = task.get("ReplicationTaskStats", {}).get("FullLoadFinishDate")
    finished = f"{finished_at.astimezone(timezone.utc):%H:%M} UTC" if finished_at else "today"
    return [
        f"{'⚠️' if problems else '✅'} {header}",
        f"Finished {finished} in {format_minutes(duration)}{usual_suffix(duration, duration_history, format_minutes)}, "
        f"{total_rows:,.0f} rows{usual_suffix(total_rows, history.get(f'{pipeline}|{TOTAL_ROWS_KEY}', []), format_count)}, "
        f"{len(tables)} table{'' if len(tables) == 1 else 's'}",
    ] + table_lines


def send_digest():
    today = today_start()
    pipelines = sorted(PIPELINES.items(), key=lambda item: (item[1]["deadline"], item[0]))
    tasks = {pipeline: describe_task(config["task_arn"]) for pipeline, config in pipelines}
    tables = {
        pipeline: table_statistics(config["task_arn"])
        for pipeline, config in pipelines
        if run_status(tasks[pipeline], today)[0] != "missing"
    }

    history_queries = {}
    for pipeline, _ in pipelines:
        history_queries[f"{pipeline}|{DURATION_KEY}"] = ("LoadDurationMinutes", {"Pipeline": pipeline})
        history_queries[f"{pipeline}|{TOTAL_ROWS_KEY}"] = ("TotalRowsLoaded", {"Pipeline": pipeline})
        for table in tables.get(pipeline, []):
            history_queries[f"{pipeline}|{table_name(table)}"] = (
                "RowsLoaded", {"Pipeline": pipeline, "Table": table_name(table)}
            )
    history = metric_values(history_queries, today - timedelta(days=HISTORY_DAYS), today)

    lines = [f"📋 DMS daily summary {today:%Y-%m-%d}"]
    for pipeline, config in pipelines:
        lines.append("")
        lines += pipeline_summary(pipeline, config, tasks[pipeline], tables.get(pipeline, []), history, today)

    publish(lines)
