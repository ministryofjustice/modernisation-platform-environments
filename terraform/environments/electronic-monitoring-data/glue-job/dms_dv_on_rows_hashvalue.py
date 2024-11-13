
import sys
# import typing as RT

# from logging import getLogger
# import pandas as pd

from glue_data_validation_lib import SparkSession
from glue_data_validation_lib import S3Methods
from glue_data_validation_lib import CustomPysparkMethods
from glue_data_validation_lib import RDSConn_Constants
from glue_data_validation_lib import RDS_JDBC_CONNECTION

from awsglue.utils import getResolvedOptions
from awsglue.transforms import *

from awsglue.dynamicframe import DynamicFrame
from awsglue.job import Job

# from pyspark.conf import SparkConf
from pyspark.sql import DataFrame
import pyspark.sql.functions as F
import pyspark.sql.types as T

# from pyspark.storagelevel import StorageLevel

# ===============================================================================

sc = SparkSession.sc
sc._jsc.hadoopConfiguration().set("spark.dynamicAllocation.enabled", "true")

spark = SparkSession.spark

glueContext = SparkSession.glueContext
LOGGER = glueContext.get_logger()

# ===============================================================================


# ===============================================================================

# Organise capturing input parameters.
DEFAULT_INPUTS_LIST = ["JOB_NAME",
                       "script_bucket_name",
                       "rds_hashed_rows_prq_bucket",
                       "rds_hashed_rows_prq_parent_dir",
                       "dms_prq_output_bucket",
                       "rds_database_folder",
                       "rds_db_schema_folder",
                       "table_to_be_validated"
                       "table_pkey_column",
                       "glue_catalog_db_name",
                       "glue_catalog_tbl_name",
                       "glue_catalog_dv_bucket"
                       ]

OPTIONAL_INPUTS = [
]

AVAILABLE_ARGS_LIST = CustomPysparkMethods.resolve_args(DEFAULT_INPUTS_LIST+OPTIONAL_INPUTS)

args = getResolvedOptions(sys.argv, AVAILABLE_ARGS_LIST)

# ------------------------------

job = Job(glueContext)
job.init(args["JOB_NAME"], args)

# ------------------------------

RDS_DB_HOST_ENDPOINT = args["rds_db_host_ep"]
RDS_DB_PORT = RDSConn_Constants.RDS_DB_PORT
RDS_DB_INSTANCE_USER = RDSConn_Constants.RDS_DB_INSTANCE_USER
RDS_DB_INSTANCE_PWD = args["rds_db_pwd"]
RDS_DB_INSTANCE_DRIVER = RDSConn_Constants.RDS_DB_INSTANCE_DRIVER

RDS_HASHED_ROWS_PRQ_BUCKET = args["rds_hashed_rows_prq_bucket"]
RDS_HASHED_ROWS_PRQ_PARENT_DIR = args["rds_hashed_rows_prq_parent_dir"]

DMS_PRQ_OUTPUT_BUCKET = args["dms_prq_output_bucket"]
RDS_DATABASE_FOLDER = args["rds_database_folder"]
RDS_DB_SCHEMA_FOLDER = args["rds_db_schema_folder"]
TABLE_TO_BE_VALIDATED = args["table_to_be_validated"]
TABLE_PKEY_COLUMN = args['table_pkey_column']

GLUE_CATALOG_DB_NAME = args["glue_catalog_db_name"]
GLUE_CATALOG_TBL_NAME = args["glue_catalog_tbl_name"]
GLUE_CATALOG_DV_BUCKET = args["glue_catalog_dv_bucket"]

CATALOG_DB_TABLE_PATH = f"""{GLUE_CATALOG_DB_NAME}/{GLUE_CATALOG_TBL_NAME}"""
CATALOG_TABLE_S3_FULL_PATH = f'''s3://{GLUE_CATALOG_DV_BUCKET}/{CATALOG_DB_TABLE_PATH}'''

# ===============================================================================
# USER-DEFINED-FUNCTIONS
# ----------------------


def write_parquet_to_s3(df_dv_output: DataFrame, database, db_sch_tbl_name):

    df_dv_output = df_dv_output.repartition(1)
    table_partition_path = f'''{CATALOG_DB_TABLE_PATH}/database_name={database}/full_table_name={db_sch_tbl_name}'''
    if S3Methods.check_s3_folder_path_if_exists(
                    GLUE_CATALOG_DV_BUCKET,
                    table_partition_path):
        s3_table_partition_full_path = f"""{CATALOG_TABLE_S3_FULL_PATH}/database_name={database}/full_table_name={db_sch_tbl_name}"""
        LOGGER.info(f"""Purging S3-path: {s3_table_partition_full_path}""")

        glueContext.purge_s3_path(f"""{s3_table_partition_full_path}""", options={"retentionPeriod": 0})
    # ---------------------------------------------------------------------

    dydf = DynamicFrame.fromDF(df_dv_output, glueContext, "final_spark_df")

    glueContext.write_dynamic_frame.from_options(frame=dydf, connection_type='s3', format='parquet',
                                                 connection_options={
                                                     'path': f"""{CATALOG_TABLE_S3_FULL_PATH}/""",
                                                     "partitionKeys": ["database_name", "full_table_name"]
                                                 },
                                                 format_options={
                                                     'useGlueParquetWriter': True,
                                                     'compression': 'snappy',
                                                     'blockSize': 13421773,
                                                     'pageSize': 1048576
                                                 })
    LOGGER.info(f"""{db_sch_tbl_name} validation report written to -> {CATALOG_TABLE_S3_FULL_PATH}/""")

# ===================================================================================================

# s3://dms-rds-to-parquet-20240606144708618700000001/g4s_emsys_mvp/dbo/GPSPosition_V2/year=2020/month=3/

if __name__ == "__main__":

    table_dirpath = f'''{RDS_DATABASE_FOLDER}/{RDS_DB_SCHEMA_FOLDER}/{TABLE_TO_BE_VALIDATED}'''.strip()
    rds_hashed_rows_bucket_parent_dir = f"""{RDS_HASHED_ROWS_PRQ_BUCKET}/{RDS_HASHED_ROWS_PRQ_PARENT_DIR}"""
    rds_hashed_rows_fulls3path = f"""s3://{rds_hashed_rows_bucket_parent_dir}/{table_dirpath}"""
    dms_output_fulls3path = f"""s3://{DMS_PRQ_OUTPUT_BUCKET}/{table_dirpath}"""
    db_sch_tbl = f"""{RDS_DATABASE_FOLDER}_{RDS_DB_SCHEMA_FOLDER}_{TABLE_TO_BE_VALIDATED}"""
    # -------------------------------------------------------

    if not S3Methods.check_s3_folder_path_if_exists(RDS_HASHED_ROWS_PRQ_BUCKET, 
                                                    f"""{RDS_HASHED_ROWS_PRQ_PARENT_DIR}/{table_dirpath}"""):
          LOGGER.error(f'''>> {rds_hashed_rows_fulls3path} << Path Not Available !!''')
          sys.exit(1)
    elif not S3Methods.check_s3_folder_path_if_exists(DMS_PRQ_OUTPUT_BUCKET, 
                                                      table_dirpath):
          LOGGER.error(f'''>> {dms_output_fulls3path} << Path Not Available !!''')
          sys.exit(1)

    hashed_table_schema = T.StructType(
        [T.StructField(f"{TABLE_PKEY_COLUMN}", T.IntegerType(), False),
         T.StructField("RowHash", T.StringType(), False)]
         )

    rds_hashed_rows_prq_df = CustomPysparkMethods.get_s3_parquet_df_v2(
                                    rds_hashed_rows_fulls3path, 
                                    hashed_table_schema
                                )
    rds_hashed_rows_prq_df_count = rds_hashed_rows_prq_df.count()

    dms_table_output_prq_df = spark.read.parquet(dms_output_fulls3path)
    dms_table_output_prq_df_count = dms_table_output_prq_df.count()

    rds_jdbc_conn_obj = RDS_JDBC_CONNECTION(RDS_DB_HOST_ENDPOINT,
                                            RDS_DB_INSTANCE_PWD,
                                            RDS_DATABASE_FOLDER,
                                            RDS_DB_SCHEMA_FOLDER)

    # EVALUATE RDS-DATAFRAME ROW-COUNT
    df_rds_count = rds_jdbc_conn_obj.get_rds_db_table_row_count(
                                        TABLE_TO_BE_VALIDATED, 
                                        TABLE_PKEY_COLUMN
                    )
    if rds_hashed_rows_prq_df_count != df_rds_count:
        error_msg = f"""rds_hashed_rows_prq_df_count ({rds_hashed_rows_prq_df_count}) != df_rds_count ({df_rds_count})"""
        sys.exit(f"""Row Count Mismatch: \n{error_msg}""")     
        # ------------------------------------------------
        #     
        if rds_hashed_rows_prq_df_count != dms_table_output_prq_df_count:
            error_msg = f"""rds_hashed_rows_prq_df_count ({rds_hashed_rows_prq_df_count}) != dms_table_output_prq_df_count ({dms_table_output_prq_df_count})"""
            sys.exit(f"""Row Count Mismatch: \n{error_msg}""")
    # --------------------

    all_columns_except_pkey = [col for col in dms_table_output_prq_df.columns 
                               if col != TABLE_PKEY_COLUMN]
    LOGGER.info(f""">> all_columns_except_pkey = {all_columns_except_pkey} <<""")

    dms_table_output_prq_df_t1 = dms_table_output_prq_df.withColumn(
                                    "RowHash", F.sha2(F.concat_ws("", *all_columns_except_pkey), 256))\
                                    .select(f'{TABLE_PKEY_COLUMN}', 'RowHash')
    
    unmatched_hashvalues_df = rds_hashed_rows_prq_df.alias('L').join(
                                dms_table_output_prq_df_t1.alias('R'), 
                                on=[f'{TABLE_PKEY_COLUMN}'],
                                how='left')\
                                .where("L.RowHash != R.RowHash").cache()
    
    unmatched_hashvalues_df_count = unmatched_hashvalues_df.count()

    df_dv_output = CustomPysparkMethods.declare_empty_df_dv_output_v1()

    if unmatched_hashvalues_df_count != 0:
        LOGGER.warn(f"""unmatched_hashvalues_df_count> {unmatched_hashvalues_df_count}: Row differences found!""")

        df_subtract_temp = (unmatched_hashvalues_df
                                .withColumn('json_row', 
                                            F.to_json(F.struct(*[F.col(c) 
                                                                 for c in unmatched_hashvalues_df.columns])))
                                .selectExpr("json_row")
                                .limit(100))

        subtract_validation_msg = f"""'{TABLE_TO_BE_VALIDATED}' - {unmatched_hashvalues_df_count}"""
        df_subtract_temp = df_subtract_temp.selectExpr(
                                "current_timestamp as run_datetime",
                                "json_row",
                                f""""{subtract_validation_msg} - Non-Zero unmatched Row Count!" as validation_msg""",
                                f"""'{RDS_DATABASE_FOLDER}' as database_name""",
                                f"""'{db_sch_tbl}' as full_table_name""",
                                """'False' as table_to_ap"""
                            )
        LOGGER.warn(f"{db_sch_tbl}: Validation Failed - 2")
        df_dv_output = df_dv_output.union(df_subtract_temp)
    else:
        df_temp = df_dv_output.selectExpr(
                                "current_timestamp as run_datetime",
                                "'' as json_row",
                                f"""'{TABLE_TO_BE_VALIDATED} - Validated.' as validation_msg""",
                                f"""'{RDS_DATABASE_FOLDER}' as database_name""",
                                f"""'{db_sch_tbl}' as full_table_name""",
                                """'False' as table_to_ap"""
                    )
        LOGGER.info(f"Validation Successful - 1")
        df_dv_output = df_dv_output.union(df_temp)

    write_parquet_to_s3(df_dv_output, RDS_DATABASE_FOLDER, db_sch_tbl)

    job.commit()
