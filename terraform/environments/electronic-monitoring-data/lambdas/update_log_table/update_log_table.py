import pandas as pd
import logging
import os

logger = logging.getLogger(__name__)

logger.setLevel(logging.INFO)

S3_LOG_BUCKET = os.environ.get("S3_LOG_BUCKET")

def handler(event, context):
    database_name, schema_name, table_name = event.get("db_info")
    s3_path = f"s3://{S3_LOG_BUCKET}/dms_data_validation/glue_df_output/database_name={database_name}/full_table_name={database_name}_{schema_name}_{table_name}/"
    log_table = pd.read_parquet(s3_path)
    log_table["table_to_ap"] = "True"
    try:
        log_table.to_parquet(s3_path)
    except Exception as e:
        msg = f"An error has occured: {e}"
        logger.error(msg)
        raise msg
    return {}