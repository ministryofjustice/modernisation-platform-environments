
import sys

# from logging import getLogger
# import pandas as pd

from glue_data_validation_lib import RDSConn_Constants
from glue_data_validation_lib import SparkSession
from glue_data_validation_lib import Logical_Constants
from glue_data_validation_lib import RDS_JDBC_CONNECTION
from glue_data_validation_lib import S3Methods
from glue_data_validation_lib import CustomPysparkMethods

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
                       "rds_db_host_ep",
                       "rds_db_pwd",
                       "jdbc_read_partitions_num",
                       "rds_sqlserver_db",
                       "rds_sqlserver_db_schema",
                       "rds_sqlserver_db_table",
                       "rds_db_tbl_pkey_column",
                       "rds_df_repartition_num",
                       "rds_to_parquet_output_s3_bucket"
                       ]

OPTIONAL_INPUTS = [
    "rename_migrated_prq_tbl_folder"
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

PARQUET_OUTPUT_S3_BUCKET_NAME = args["rds_to_parquet_output_s3_bucket"]

NVL_DTYPE_DICT = Logical_Constants.NVL_DTYPE_DICT

INT_DATATYPES_LIST = Logical_Constants.INT_DATATYPES_LIST

RECORDED_PKEYS_LIST = Logical_Constants.RECORDED_PKEYS_LIST

QUERY_DICT = {
    "CurfewSegment": """
    SELECT [CurfewSegmentID]
        ,[CurfewID]
        ,[CurfewSegmentType]
        ,[BeginDatetime]
        ,[EndDatetime]
        ,[LastModifiedDatetime]
        ,[DayFlags]
        ,[AdditionalInfo]
        ,[WeeksOn]
        ,[WeeksOff]
        ,[WeeksOffset]
        ,[ExportToGovernment]
        ,[PublicHolidaySegmentID]
        ,[IsPublicHoliday]
        ,[RowVersion]
        ,CAST(StartTime as varchar(8)) as StartTime
        ,CAST(EndTime as varchar(12)) as EndTime
        ,[SegmentCategoryLookupID]
        ,[ParentCurfewSegmentID]
        ,[TravelTimeBefore]
        ,[TravelTimeAfter]
    FROM [g4s_emsys_tpims].[dbo].[CurfewSegment]
    """.strip()
}
# ==================================================================
# USER-DEFINED-FUNCTIONS
# ----------------------

def write_parquet_to_s3(df_rds_query_read: DataFrame, prq_table_folder_path):

    s3_table_folder_path = f"""s3://{PARQUET_OUTPUT_S3_BUCKET_NAME}/{prq_table_folder_path}"""

    if S3Methods.check_s3_folder_path_if_exists(PARQUET_OUTPUT_S3_BUCKET_NAME, 
                                                prq_table_folder_path):

        LOGGER.info(f"""Purging S3-path: {s3_table_folder_path}""")
        glueContext.purge_s3_path(s3_table_folder_path, options={"retentionPeriod": 0})
    # --------------------------------------------------------------------

    dydf = DynamicFrame.fromDF(df_rds_query_read, glueContext, "final_spark_df")

    glueContext.write_dynamic_frame.from_options(frame=dydf, connection_type='s3', format='parquet',
                                                 connection_options={
                                                     'path': f"""{s3_table_folder_path}/"""
                                                 },
                                                 format_options={
                                                     'useGlueParquetWriter': True,
                                                     'compression': 'snappy',
                                                     'blockSize': 13421773,
                                                     'pageSize': 1048576
                                                 })
    LOGGER.info(f"""df_rds_query_read - dataframe written to -> {s3_table_folder_path}/""")

# ===================================================================================================


if __name__ == "__main__":

    # -------------------------------------------
    if args.get("rds_sqlserver_db", None) is None:
        LOGGER.error(f"""'rds_sqlserver_db' runtime input is missing! Exiting ...""")
        sys.exit(1)
    else:
        rds_sqlserver_db = args["rds_sqlserver_db"]
        LOGGER.info(f"""Given rds_sqlserver_db = {rds_sqlserver_db}""")

    if args.get("rds_sqlserver_db_schema", None) is None:
        LOGGER.error(
            f"""'rds_sqlserver_db_schema' runtime input is missing! Exiting ...""")
        sys.exit(1)
    else:
        rds_sqlserver_db_schema = args["rds_sqlserver_db_schema"]
        LOGGER.info(
            f"""Given rds_sqlserver_db_schema = {rds_sqlserver_db_schema}""")
    # -------------------------------------------

    rds_jdbc_conn_obj = RDS_JDBC_CONNECTION(RDS_DB_HOST_ENDPOINT,
                                            RDS_DB_INSTANCE_PWD,
                                            rds_sqlserver_db,
                                            rds_sqlserver_db_schema)
    # -------------------------------------------

    try:
        rds_db_name = rds_jdbc_conn_obj.check_if_rds_db_exists()[0]
    except IndexError:
        LOGGER.error(
            f"""Given database name not found! >> {args['rds_sqlserver_db']} <<""")
        sys.exit(1)
    except Exception as e:
        LOGGER.error(e)
    # -------------------------------------------------------

    rds_sqlserver_db_tbl_list = rds_jdbc_conn_obj.get_rds_db_tbl_list()
    if not rds_sqlserver_db_tbl_list:
        LOGGER.error(f"""rds_sqlserver_db_tbl_list - is empty. Exiting ...!""")
        sys.exit(1)
    else:
        message_prefix = f"""Total List of tables available in {rds_db_name}.{rds_sqlserver_db_schema}"""
        LOGGER.info(f"""{message_prefix}\n{rds_sqlserver_db_tbl_list}""")
    # -------------------------------------------------------

    if args.get("rds_sqlserver_db_table", None) is None:
        LOGGER.error(
            f"""'rds_sqlserver_db_table' runtime input is missing! Exiting ...""")
        sys.exit(1)
    else:
        rds_sqlserver_db_table = args["rds_sqlserver_db_table"]
        table_name_prefix = f"""{rds_db_name}_{rds_sqlserver_db_schema}"""
        db_sch_tbl = f"""{table_name_prefix}_{rds_sqlserver_db_table}"""
    # -------------------------------------------------------

    if db_sch_tbl not in rds_sqlserver_db_tbl_list:
        LOGGER.error(f"""'{db_sch_tbl}' - is not an existing table! Exiting ...""")
        sys.exit(1)
    else:
        LOGGER.info(f""">> Given RDS SqlServer-DB Table: {rds_sqlserver_db_table} <<""")
    # -------------------------------------------------------

    rds_db_tbl_pkey_column = args['rds_db_tbl_pkey_column']
    LOGGER.info(f"""rds_db_tbl_pkey_column = {rds_db_tbl_pkey_column}""")
    # -----------------------------------------

    rds_db_table_empty_df = rds_jdbc_conn_obj.get_rds_db_table_empty_df(rds_sqlserver_db_table)

    df_rds_dtype_dict = CustomPysparkMethods.get_dtypes_dict(rds_db_table_empty_df)
    int_dtypes_colname_list = [colname for colname, dtype in df_rds_dtype_dict.items()
                               if dtype in INT_DATATYPES_LIST]

    if rds_db_tbl_pkey_column not in int_dtypes_colname_list:
        LOGGER.error(f"""rds_db_tbl_pkey_column = {rds_db_tbl_pkey_column} is not an integer datatype column!
        """.strip())
        sys.exit(1)
    # ----------------------------------------------------

    jdbc_read_partitions_num = int(args.get('jdbc_read_partitions_num', 0))

    jdbc_read_partitions_num = 1 if jdbc_read_partitions_num <= 0 else jdbc_read_partitions_num
    LOGGER.info(f"""jdbc_read_partitions_num = {jdbc_read_partitions_num}""")

    agg_row_dict = rds_jdbc_conn_obj.get_min_max_pkey_filter(
                                        rds_sqlserver_db_table,
                                        rds_db_tbl_pkey_column
                                    )
    min_pkey = agg_row_dict['min_value']
    LOGGER.info(f"""min_pkey = {min_pkey}""")

    max_pkey = agg_row_dict['max_value']
    LOGGER.info(f"""max_pkey = {max_pkey}""")

    rds_transformed_query = QUERY_DICT[f"{rds_sqlserver_db_table}"]
    LOGGER.info(f"""rds_transformed_query = \n{rds_transformed_query}""")

    df_rds_query_read = rds_jdbc_conn_obj.get_rds_df_read_query_pkey_parallel(
                            rds_transformed_query,
                            rds_db_tbl_pkey_column,
                            min_pkey,
                            max_pkey,
                            jdbc_read_partitions_num
                        )

    LOGGER.info(
        f"""df_rds_query_read-{db_sch_tbl}: READ PARTITIONS = {df_rds_query_read.rdd.getNumPartitions()}""")

    df_rds_query_read_columns = df_rds_query_read.columns
    LOGGER.info(f"""1. df_rds_query_read_columns = {df_rds_query_read_columns}""")

    df_rds_query_read_schema = df_rds_query_read.schema
    LOGGER.info(f"""df_rds_query_read_schema = \n{[obj for obj in df_rds_query_read_schema]}""")

    rds_df_repartition_num = int(args['rds_df_repartition_num'])

    if rds_df_repartition_num != 0:
        df_rds_query_read = df_rds_query_read.repartition(rds_df_repartition_num, rds_db_tbl_pkey_column)
        int_repartitions = df_rds_query_read.rdd.getNumPartitions()
        LOGGER.info(
            f"""df_rds_query_read: After Repartitioning -> {int_repartitions} partitions.""")
    # ----------------------------------------------------

    rename_output_table_folder = args.get('rename_migrated_prq_tbl_folder', '')
    if rename_output_table_folder == '':
        rds_db_table_name = rds_sqlserver_db_table
    else:
        rds_db_table_name = rename_output_table_folder
    # ---------------------------------------

    prq_table_folder_path = f"""{rds_db_name}/{rds_sqlserver_db_schema}/{rds_db_table_name}"""
    LOGGER.info(f"""prq_table_folder_path = {prq_table_folder_path}""")

    write_parquet_to_s3(df_rds_query_read, prq_table_folder_path)

    job.commit()
