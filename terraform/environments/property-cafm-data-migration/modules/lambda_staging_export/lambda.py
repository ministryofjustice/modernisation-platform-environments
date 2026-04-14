import logging
import os
from concurrent.futures import ThreadPoolExecutor, as_completed

import awswrangler as wr

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


def run_table_export(table: str):
    """
    Run ONE Athena query per table (all lots at once).
    """

    lot_list = ",".join([f"'{lot}'" for lot in LOTS])

    sql = f"""
        SELECT *
        FROM {table}
        WHERE ptp_lot IN ({lot_list})
    """

    logger.info("Running query for table=%s", table)

    df = wr.athena.read_sql_query(
        sql=sql,
        database=DATABASE,
        s3_output=S3_ATHENA_RESULTS_PATH,
        ctas_approach=False,
    )

    # Write output split by lot
    for lot in LOTS:
        df_lot = df[df["ptp_lot"] == lot]

        if df_lot.empty:
            continue

        output_path = f"{S3_OUTPUT_PATH}/{lot}/{table}.csv"
        wr.s3.to_csv(df=df_lot, path=output_path, index=False)
        logger.info("Exported %d rows for %s/%s", len(df_lot), lot, table)

    return table


def lambda_handler(event, context):
    results = {"succeeded": [], "failed": []}

    # Run tables in parallel (big speed improvement)
    with ThreadPoolExecutor(max_workers=5) as executor:
        futures = {executor.submit(run_table_export, t): t for t in TABLES}

        for future in as_completed(futures):
            table = futures[future]

            try:
                future.result()
                results["succeeded"].append(table)

            except Exception:
                logger.exception("Failed table=%s", table)
                results["failed"].append(table)

    if results["failed"]:
        raise RuntimeError(f"Export failed for tables: {results['failed']}")

    return {
        "status": "completed",
        "results": results,
    }
