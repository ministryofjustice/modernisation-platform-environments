import csv
import io
import logging
import os
import time
from concurrent.futures import ThreadPoolExecutor, as_completed
from urllib.parse import urlparse

import boto3

logger = logging.getLogger()
logger.setLevel(logging.INFO)

DATABASE = os.environ["DATABASE"]
S3_OUTPUT_PATH = os.environ["S3_OUTPUT_PATH"].rstrip("/")
S3_ATHENA_RESULTS_PATH = os.environ["S3_ATHENA_RESULTS_PATH"].rstrip("/")

LOTS = ["LOT1", "LOT2", "LOT3", "LOT4", "LOT5"]

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
    """Parse an S3 URI into bucket and prefix."""
    parsed = urlparse(uri)
    return parsed.netloc, parsed.path.lstrip("/")


def wait_for_query(query_execution_id):
    """Poll Athena for query completion, raise if it fails or times out."""
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


def get_query_result_csv(query_execution_id):
    """Read the Athena CSV result file directly from S3."""
    results_path = S3_ATHENA_RESULTS_PATH
    bucket, prefix = parse_s3_uri(results_path)

    key = (
        f"{prefix}/{query_execution_id}.csv" if prefix else f"{query_execution_id}.csv"
    )

    response = s3.get_object(Bucket=bucket, Key=key)
    return response["Body"].read().decode("utf-8")


def split_csv_by_lot(csv_text, lot_number_index):
    """Split CSV text into per-lot CSV strings."""
    reader = csv.reader(io.StringIO(csv_text))
    header = next(reader)

    lot_rows = {lot: [] for lot in LOTS}

    for row in reader:
        lot_value = row[lot_number_index]

        if lot_value in lot_rows:
            lot_rows[lot_value].append(row)

    result = {}

    for lot, rows in lot_rows.items():
        buf = io.StringIO()
        writer = csv.writer(buf)
        writer.writerow(header)
        writer.writerows(rows)
        result[lot] = buf.getvalue()

    return result


def run_table_export(table):
    """Run one Athena query per table, split result by lot, upload to staging."""
    lot_list = ",".join(f"'{lot}'" for lot in LOTS)

    sql = f"""
        SELECT *
        FROM {table}
        WHERE lot_number IN ({lot_list})
    """

    logger.info(f"Running query for table={table}")

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

    # Read Athena's CSV result
    csv_text = get_query_result_csv(query_execution_id)

    # Find lot_number column index from header
    header = csv_text.split("\n", 1)[0]
    columns = next(csv.reader(io.StringIO(header)))
    lot_number_index = columns.index("lot_number")

    # Split by lot and upload
    lot_csvs = split_csv_by_lot(csv_text, lot_number_index)
    output_bucket, output_prefix = parse_s3_uri(S3_OUTPUT_PATH)

    for lot, csv_data in lot_csvs.items():
        row_count = csv_data.count("\n") - 1  # subtract header

        key = (
            f"{output_prefix}/{lot}/{table}.csv"
            if output_prefix
            else f"{lot}/{table}.csv"
        )

        s3.put_object(Bucket=output_bucket, Key=key, Body=csv_data.encode("utf-8"))
        logger.info(f"Exported {row_count} rows for {lot}/{table}")

    # Clean up Athena result files
    for suffix in [f"{query_execution_id}.csv", f"{query_execution_id}.csv.metadata"]:
        cleanup_key = f"{results_prefix}/{suffix}" if results_prefix else suffix

        try:
            s3.delete_object(Bucket=results_bucket, Key=cleanup_key)
        except Exception:
            logger.debug(f"Could not clean up {cleanup_key}")

    return table


def lambda_handler(event, context):
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
