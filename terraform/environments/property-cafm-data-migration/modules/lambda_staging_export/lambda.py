import logging
import os
import time
from concurrent.futures import ThreadPoolExecutor, as_completed
from datetime import datetime, timezone
from urllib.parse import urlparse

import boto3

logger = logging.getLogger()
logger.setLevel(logging.INFO)

DATABASE = os.environ["DATABASE"]
S3_OUTPUT_PATH = os.environ["S3_OUTPUT_PATH"].rstrip("/")
S3_ATHENA_RESULTS_PATH = os.environ["S3_ATHENA_RESULTS_PATH"].rstrip("/")

LOTS = ["1", "2", "3", "4", "5"]

LOT_DIR_MAP = {lot: f"LOT{lot}" for lot in LOTS}

TABLES = [
    "property_cafm__acm_action_plan_record",
    "property_cafm__acm_inspection_record",
    "property_cafm__acm_priority_assessment_record",
    "property_cafm__acm_record",
    "property_cafm__ancillary_component_record",
    "property_cafm__building_record",
    "property_cafm__condition_record",
    "property_cafm__external_works_record",
    "property_cafm__fittings_furnishings_and_equipment_record",
    "property_cafm__floor_record",
    "property_cafm__internal_finishes_record",
    "property_cafm__services_record",
    "property_cafm__site_record",
    "property_cafm__space_record",
    "property_cafm__superstructure_record",
]

athena = boto3.client("athena")
s3 = boto3.client("s3")

POLL_INTERVAL = 1  # seconds
MAX_POLL_ATTEMPTS = 900  # 15 minutes max


def parse_s3_uri(uri):
    """
    Parse an S3 URI (e.g. s3://bucket/prefix) into its bucket name and key prefix.

    Args:
        uri: An S3 URI string.

    Returns:
        A tuple of (bucket, prefix) where prefix has no leading slash.
    """
    parsed = urlparse(uri)
    return parsed.netloc, parsed.path.lstrip("/")


def wait_for_query(query_execution_id):
    """
    Poll Athena until the query reaches a terminal state.

    Args:
        query_execution_id: The Athena query execution ID to poll.

    Returns:
        The final GetQueryExecution response when the query succeeds.

    Raises:
        RuntimeError: If the query fails or is cancelled.
        TimeoutError: If the query does not complete within MAX_POLL_ATTEMPTS seconds.
    """
    for _ in range(MAX_POLL_ATTEMPTS):
        response = athena.get_query_execution(QueryExecutionId=query_execution_id)
        state = response["QueryExecution"]["Status"]["State"]

        if state == "SUCCEEDED":
            return response

        if state in ("FAILED", "CANCELLED"):
            reason = response["QueryExecution"]["Status"].get(
                "StateChangeReason", "Unknown"
            )

            raise RuntimeError(f"Query {query_execution_id} {state}: {reason}")

        time.sleep(POLL_INTERVAL)

    raise TimeoutError(f"Query {query_execution_id} did not complete within timeout")


def _run_export(sql, out_key, log_label):
    """
    Execute an Athena query, upload the CSV result to S3, then clean up.

    Args:
        sql:       The SQL string to execute.
        out_key:   The S3 key (within the output bucket) to write the CSV to.
        log_label: A label used in log messages (e.g. 'LOT1/property_cafm__site_record').
    """
    results_bucket, results_prefix = parse_s3_uri(S3_ATHENA_RESULTS_PATH)

    response = athena.start_query_execution(
        QueryString=sql,
        QueryExecutionContext={"Database": DATABASE},
        ResultConfiguration={
            "OutputLocation": S3_ATHENA_RESULTS_PATH,
        },
    )

    query_execution_id = response["QueryExecutionId"]

    wait_for_query(query_execution_id)

    # Read Athena's CSV result from S3
    bucket, prefix = parse_s3_uri(S3_ATHENA_RESULTS_PATH)
    key = (
        f"{prefix}/{query_execution_id}.csv" if prefix else f"{query_execution_id}.csv"
    )
    response = s3.get_object(Bucket=bucket, Key=key)
    csv_data = response["Body"].read()

    row_count = csv_data.count(b"\n") - 1  # subtract header

    output_bucket, _ = parse_s3_uri(S3_OUTPUT_PATH)
    s3.put_object(Bucket=output_bucket, Key=out_key, Body=csv_data)
    logger.info(f"Exported {row_count} rows for {log_label}")

    # Clean up Athena result files
    for suffix in [f"{query_execution_id}.csv", f"{query_execution_id}.csv.metadata"]:
        cleanup_key = f"{results_prefix}/{suffix}" if results_prefix else suffix

        try:
            s3.delete_object(Bucket=results_bucket, Key=cleanup_key)
        except Exception:
            logger.debug(f"Could not clean up {cleanup_key}")


def run_lot_export(table, lot):
    """
    Export a single lot's rows from an Athena table to S3 as a CSV file.

    Writes to {LOT_DIR_MAP[lot]}/{table}.csv in the staging output bucket.

    Args:
        table: The Athena table name to query.
        lot:   The lot number to filter on (e.g. '1').
    """
    sql = f"""
        SELECT *
        FROM {table}
        WHERE lot_number = '{lot}'
    """

    lot_dir = LOT_DIR_MAP[lot]
    _, output_prefix = parse_s3_uri(S3_OUTPUT_PATH)
    export_date = datetime.now(timezone.utc).strftime("%Y%m%d")
    
    out_key = (
        f"{output_prefix}/{lot_dir}/{table}_{export_date}.csv"
        if output_prefix
        else f"{lot_dir}/{table}_{export_date}.csv"
    )

    logger.info(f"Running query for table={table} lot={lot}")
    _run_export(sql, out_key, f"{lot_dir}/{table}")


def run_wsm_export(table):
    """
    Export all rows from an Athena table (across all lots) to S3 as a CSV file under WSM/.

    Writes to WSM/{table}.csv in the staging output bucket.

    Args:
        table: The Athena table name to query.
    """
    lot_list = ",".join(f"'{lot}'" for lot in LOTS)
    sql = f"SELECT * FROM {table} WHERE lot_number IN ({lot_list})"

    _, output_prefix = parse_s3_uri(S3_OUTPUT_PATH)
    export_date = datetime.now(timezone.utc).strftime("%Y%m%d")
    out_key = (
        f"{output_prefix}/WSM/{table}_{export_date}.csv"
        if output_prefix
        else f"WSM/{table}_{export_date}.csv"
    )

    logger.info(f"Running WSM query for table={table}")
    _run_export(sql, out_key, f"WSM/{table}")


def run_table_export(table):
    """
    Export all lots for a single table by running one query per lot.

    Iterates over LOTS sequentially to keep peak memory usage bounded,
    then returns the table name on completion.

    Args:
        table: The Athena table name to export.

    Returns:
        The table name.
    """
    for lot in LOTS:
        run_lot_export(table, lot)

    run_wsm_export(table)

    return table


def lambda_handler(event, context):
    """
    Lambda entry point. Exports all CAFM tables from Athena to the staging S3 bucket.

    Processes up to 5 tables concurrently. Each table's lots are exported
    sequentially (one Athena query per lot) to limit memory usage.
    Raises RuntimeError if any table export fails.

    Args:
        event:   Lambda event payload (unused).
        context: Lambda context object (unused).

    Returns:
        A dict with 'status' and 'results' keys listing succeeded/failed tables.
    """
    results = {"succeeded": [], "failed": []}

    with ThreadPoolExecutor(max_workers=5) as executor:
        futures = {executor.submit(run_table_export, t): t for t in TABLES}

        for future in as_completed(futures):
            table = futures[future]

            try:
                future.result()
                results["succeeded"].append(table)
            except Exception:
                logger.exception(f"Failed table={table}")
                results["failed"].append(table)

    if results["failed"]:
        raise RuntimeError(f"Export failed for tables: {results['failed']}")

    return {
        "status": "completed",
        "results": results,
    }
