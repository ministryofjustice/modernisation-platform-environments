import logging
import os

import awswrangler as wr

logger = logging.getLogger()
logger.setLevel(logging.INFO)

DATABASE = os.environ["DATABASE"]
S3_OUTPUT_PATH = os.environ["S3_OUTPUT_PATH"].rstrip("/")
WORKGROUP = "primary"
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


def lambda_handler(event, context):
    results = {"succeeded": [], "failed": []}

    for lot in LOTS:
        for table in TABLES:
            key = f"{lot}/{table}"

            try:
                df = wr.athena.read_sql_query(
                    sql=f'SELECT * FROM "{table}" WHERE ptp_lot = ?',
                    database=DATABASE,
                    workgroup=WORKGROUP,
                    params=[lot],
                )

                output_path = f"{S3_OUTPUT_PATH}/{lot}/{table}.csv"

                wr.s3.to_csv(
                    df=df,
                    path=output_path,
                    index=False,
                )

                logger.info("Exported %d rows for %s to %s", len(df), key, output_path)
                results["succeeded"].append(key)

            except Exception:
                logger.exception("Failed to export %s", key)
                results["failed"].append(key)

    if results["failed"]:
        raise RuntimeError(f"Export failed for: {results['failed']}")

    return {"status": "completed", "results": results}
