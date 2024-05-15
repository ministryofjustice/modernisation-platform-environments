import sys
import boto3
import time
from logging import getLogger
from awsglue.utils import getResolvedOptions


# Set up Glue context and job
args = getResolvedOptions(sys.argv, ["JOB_NAME",
                                     "parquet_output_bucket_name",
                                     "glue_catalog_db_name",
                                     "glue_catalog_tbl_name"
                                     ])


ATHENA_CLIENT = boto3.client("athena", region_name='eu-west-2')

PARQUET_OUTPUT_S3_BUCKET_NAME = args["parquet_output_bucket_name"]

ATHENA_RUN_OUTPUT_LOCATION = f"s3://{PARQUET_OUTPUT_S3_BUCKET_NAME}/athena_temp_store/"

GLUE_CATALOG_DB_NAME = args["glue_catalog_db_name"]
GLUE_CATALOG_TBL_NAME = args["glue_catalog_tbl_name"]

# F10 - Function to run athena create-external-table DDL query.
# Uses 'BOTO3'/athena library.
def create_table(table_ddl):
    response = ATHENA_CLIENT.start_query_execution(
        QueryString=table_ddl,
        ResultConfiguration={"OutputLocation": ATHENA_RUN_OUTPUT_LOCATION}
    )
    return response["QueryExecutionId"]

# F11 - Function to check the status of the submitted athena query
# Uses 'BOTO3'/athena library.
def has_query_succeeded(execution_id):
    state = "RUNNING"
    max_execution = 5

    while max_execution > 0 and state in ["RUNNING", "QUEUED"]:
        max_execution -= 1
        response = ATHENA_CLIENT.get_query_execution(
            QueryExecutionId=execution_id)
        if (
            "QueryExecution" in response
            and "Status" in response["QueryExecution"]
            and "State" in response["QueryExecution"]["Status"]
        ):
            state = response["QueryExecution"]["Status"]["State"]
            if state == "SUCCEEDED":
                return True

        time.sleep(30)

    return False

if __name__ == "__main__":

    table_ddl_drop = f"drop table if exists {GLUE_CATALOG_DB_NAME}.{GLUE_CATALOG_TBL_NAME}"

    # Drop table if exists Table
    execution_id = create_table(table_ddl_drop)
    print(f"Create Table execution id: {execution_id}")
    # LOGGER.info(f"Create Table execution id: {execution_id}")

    # Check query execution
    query_status = has_query_succeeded(execution_id=execution_id)
    print(f"Query state: {query_status}")
    # LOGGER.info(f"Query state: {query_status}")

    # =================================================================================

    table_ddl_create = f'''
    CREATE EXTERNAL TABLE `{GLUE_CATALOG_DB_NAME}`.`{GLUE_CATALOG_TBL_NAME}`(
    `run_datetime` timestamp, 
    `full_table_name` string, 
    `json_row` string, 
    `validation_msg` string)
    PARTITIONED BY ( 
        `database_name` string)
    ROW FORMAT SERDE 
        'org.apache.hadoop.hive.ql.io.parquet.serde.ParquetHiveSerDe' 
    STORED AS INPUTFORMAT 
        'org.apache.hadoop.hive.ql.io.parquet.MapredParquetInputFormat' 
    OUTPUTFORMAT 
        'org.apache.hadoop.hive.ql.io.parquet.MapredParquetOutputFormat'
    LOCATION
        's3://dms-data-validation-20240509174326500600000002/dms_data_validation/glue_df_output/'
    TBLPROPERTIES (
        'classification'='parquet', 
        'partition_filtering.enabled'='true',
        'typeOfData'='file')
    '''.strip()

    # Create Table
    execution_id = create_table(table_ddl_create)
    print(f"Create Table execution id: {execution_id}")
    # LOGGER.info(f"Create Table execution id: {execution_id}")

    # Check query execution
    query_status = has_query_succeeded(execution_id=execution_id)
    print(f"Query state: {query_status}")
    # LOGGER.info(f"Query state: {query_status}")

    # =================================================================================

    table_ddl_partitions_refresh = f"msck repair table {GLUE_CATALOG_DB_NAME}.{GLUE_CATALOG_TBL_NAME}"

    # Refresh table prtitions
    execution_id = create_table(table_ddl_partitions_refresh)
    print(f"Create Table execution id: {execution_id}")
    # LOGGER.info(f"Create Table execution id: {execution_id}")

    # Check query execution
    query_status = has_query_succeeded(execution_id=execution_id)
    print(f"Query state: {query_status}")
    # LOGGER.info(f"Query state: {query_status}")
