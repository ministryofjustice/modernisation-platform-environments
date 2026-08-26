
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

# *NOTE:* "EXEC sp_spaceused N'[g4s_emsys_mvp].[dbo].[GPSPosition]';"
# The above SQL Server stored procedure call helps to find the values for
#   - rds_table_total_size_mb

# THIS SCRIPT IS USED TO
#   1. COPY TABLE DATA WITH SPECIFIC PARTITIONS TO S3-PARQUET
#   2. VALIDATE THE SPECIFIED PARTITIONS BETWEEN RDS-TABLE AND S3-PARQUET
#
#
# NOTES-1:> If non-integer datatype or more than one value provided to 'rds_db_tbl_pkeys_col_list', the job fails.
# NOTES-2:> 'validation_only_run' is to be SET TO 'true' if only data validation is to be done.
#           Also, to skip data validation when 'validation_only_run' is 'false' is by setting 'validation_sample_fraction_float' to 0.
# NOTES-2b:> The 'validation' logic in this script expects the 'parquet' source is partitioned on 'year', 'month' consecutively.
# NOTES-3:> 'rds_query_where_clause' optional input rds-db-table query filter clause & is only used while fetching minimum and maximum primary-key values.
# NOTES-4:> 'add_year_partition_bool' and 'add_month_partition_bool' are to be set 'true' if the 'year', 'month' columns are missing in RDS-Dataframe.
#         > ALSO, based on the above settings RDS-Dataframe is repartitioned by 'year' followed by 'month' captured in 'partition_by_cols'.
# NOTES-5:> 'jdbc_read_partition_num' OR 'rds_table_total_size_mb' WITH ANY OF THE BELOW INPUTS DEFINES JDBC-READ PARTITIONS / PARALLEL CONNECTIONS
#        >> 'jdbc_read_256mb_partitions', jdbc_read_512mb_partitions', 'jdbc_read_1gb_partitions', 'jdbc_read_2gb_partitions' <<
#        >> 'jdbc_read_partition_num' value to be given is to be aligned with number of workers & executors. <<
#
# NOTES-6:>
# MANDATORY INPUTS: 'rds_db_tbl_pkeys_col_list',
# CONDITIONAL INPUTS:
#   1. 'date_partition_column_name' MANDATORY IF 'rds_df_year_int_equals_to' OR 'rds_df_month_int_equals_to' are NON-ZERO
#   2. 'date_partition_column_name' MANDATORY IF 'add_year_partition_bool' OR 'add_month_partition_bool' are set to 'true'
# DEFAULT INPUTS: {'rds_df_year_int_equals_to': 0}, {'rds_df_month_int_equals_to': 0}

# ===============================================================================

# Organise capturing input parameters.
DEFAULT_INPUTS_LIST = ["JOB_NAME",
                       "script_bucket_name",
                       "rds_db_host_ep",
                       "rds_db_pwd",
                       "dv_parquet_output_s3_bucket",
                       "glue_catalog_db_name",
                       "glue_catalog_tbl_name",
                       "jdbc_read_partition_num",
                       "jdbc_read_256mb_partitions",
                       "jdbc_read_512mb_partitions",
                       "jdbc_read_1gb_partitions",
                       "jdbc_read_2gb_partitions",
                       "rds_to_parquet_output_s3_bucket",
                       "rds_sqlserver_db",
                       "rds_sqlserver_db_schema",
                       "rds_sqlserver_db_table",
                       "rds_db_tbl_pkeys_col_list",
                       "rds_df_repartition_num",
                       "rds_table_total_size_mb",
                       "add_year_partition_bool",
                       "add_month_partition_bool",
                       "validation_only_run",
                       "validation_sample_fraction_float",
                       "validation_sample_df_repartition_num",
                       "rds_df_year_int_equals_to",
                       "rds_df_month_int_equals_to"
                       ]

OPTIONAL_INPUTS = [
    "date_partition_column_name",
    "rename_migrated_prq_tbl_folder",
    "rds_query_where_clause"
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
DV_PARQUET_OUTPUT_S3_BUCKET_NAME = args["dv_parquet_output_s3_bucket"]

ATHENA_RUN_OUTPUT_LOCATION = f"s3://{PARQUET_OUTPUT_S3_BUCKET_NAME}/athena_temp_store/"

NVL_DTYPE_DICT = Logical_Constants.NVL_DTYPE_DICT

INT_DATATYPES_LIST = Logical_Constants.INT_DATATYPES_LIST

RECORDED_PKEYS_LIST = Logical_Constants.RECORDED_PKEYS_LIST

# ==================================================================
# USER-DEFINED-FUNCTIONS
# ----------------------


# def write_rds_df_to_s3_parquet_v2(df_rds_write: DataFrame,
#                                   partition_by_cols,
#                                   prq_table_folder_path):
#     """
#     Write dynamic frame in S3 and catalog it.
#     """

#     # s3://dms-rds-to-parquet-20240606144708618700000001/g4s_emsys_mvp/dbo/GPSPosition_V2/
#     # s3://dms-rds-to-parquet-20240606144708618700000001/g4s_emsys_mvp/dbo/GPSPosition_V2/year=2019/month=10/

#     s3_table_folder_path = f"""s3://{PARQUET_OUTPUT_S3_BUCKET_NAME}/{prq_table_folder_path}"""

#     # Note: The below block of code erases the existing partition & use cautiously.
#     # partition_path = f"""{s3_table_folder_path}/year=2019/month=10/"""
#     # if check_s3_folder_path_if_exists(PARQUET_OUTPUT_S3_BUCKET_NAME, partition_path):

#     #     LOGGER.info(f"""Purging S3-path: {partition_path}""")
#     #     glueContext.purge_s3_path(partition_path, options={"retentionPeriod": 0})
#     # # --------------------------------------------------------------------

#     dynamic_df_write = glueContext.getSink(
#                             format_options = {
#                                 "compression": "snappy",
#                                 "useGlueParquetWriter": True
#                                 },
#                             path = f"""{s3_table_folder_path}/""",
#                             connection_type = "s3",
#                             updateBehavior = "UPDATE_IN_DATABASE",
#                             partitionKeys = partition_by_cols,
#                             enableUpdateCatalog = True,
#                             transformation_ctx = "dynamic_df_write",
#     )

#     catalog_db, catalog_db_tbl = prq_table_folder_path.split(f"""/{args['rds_sqlserver_db_schema']}/""")
#     dynamic_df_write.setCatalogInfo(
#                         catalogDatabase = catalog_db.lower(),
#                         catalogTableName = catalog_db_tbl.lower()
#     )

#     dynamic_df_write.setFormat("glueparquet")

#     dydf_rds_read = DynamicFrame.fromDF(df_rds_write, glueContext, "final_spark_df")
#     dynamic_df_write.writeFrame(dydf_rds_read)

#     LOGGER.info(f"""'{db_sch_tbl}' table data written to -> {s3_table_folder_path}/""")

#     # ddl_refresh_table_partitions = f"msck repair table {catalog_db.lower()}.{catalog_db_tbl.lower()}"
#     # LOGGER.info(f"""ddl_refresh_table_partitions:> \n{ddl_refresh_table_partitions}""")

#     # # Refresh table prtitions
#     # execution_id = run_athena_query(ddl_refresh_table_partitions)
#     # LOGGER.info(f"SQL-Statement execution id: {execution_id}")

#     # # Check query execution
#     # query_status = has_query_succeeded(execution_id=execution_id)
#     # LOGGER.info(f"Query state: {query_status}")


def write_rds_df_to_s3_parquet(df_rds_write: DataFrame,
                               partition_by_cols,
                               prq_table_folder_path):

    # s3://dms-rds-to-parquet-20240606144708618700000001/g4s_cap_dw/dbo/F_History/

    s3_table_folder_path = f"""s3://{PARQUET_OUTPUT_S3_BUCKET_NAME}/{prq_table_folder_path}"""

    if S3Methods.check_s3_folder_path_if_exists(PARQUET_OUTPUT_S3_BUCKET_NAME,
                                                prq_table_folder_path):

        LOGGER.info(f"""Purging S3-path: {s3_table_folder_path}""")
        glueContext.purge_s3_path(s3_table_folder_path, options={"retentionPeriod": 0})
    # --------------------------------------------------------------------

    # catalog_db, catalog_db_tbl = prq_table_folder_path.split(f"""/{args['rds_sqlserver_db_schema']}/""")

    dydf = DynamicFrame.fromDF(df_rds_write, glueContext, "final_spark_df")

    glueContext.write_dynamic_frame.from_options(frame=dydf, connection_type='s3', format='parquet',
                                                 connection_options={
                                                     'path': f"""{s3_table_folder_path}/""",
                                                     "partitionKeys": partition_by_cols
                                                 },
                                                 format_options={
                                                     'useGlueParquetWriter': True,
                                                     'compression': 'snappy',
                                                     'blockSize': 13421773,
                                                     'pageSize': 1048576
                                                 })
    LOGGER.info(f"""'{db_sch_tbl}' table data written to -> {s3_table_folder_path}/""")


def compare_rds_parquet_samples(rds_jdbc_conn_obj,
                                rds_db_table_name,
                                df_rds_read: DataFrame,
                                jdbc_partition_column,
                                prq_table_folder_path,
                                validation_sample_fraction_float) -> DataFrame:

    df_dv_output_schema = T.StructType(
        [T.StructField("run_datetime", T.TimestampType(), True),
         T.StructField("json_row", T.StringType(), True),
         T.StructField("validation_msg", T.StringType(), True),
         T.StructField("database_name", T.StringType(), True),
         T.StructField("full_table_name", T.StringType(), True),
         T.StructField("table_to_ap", T.StringType(), True)])

    df_dv_output = CustomPysparkMethods.get_pyspark_empty_df(df_dv_output_schema)

    s3_table_folder_path = f"""s3://{PARQUET_OUTPUT_S3_BUCKET_NAME}/{prq_table_folder_path}"""
    LOGGER.info(f"""Parquet Source being used for comparison: {s3_table_folder_path}""")

    df_parquet_read = spark.read.schema(df_rds_read.schema).parquet(s3_table_folder_path)

    rds_df_year_int_equals_to = int(args.get('rds_df_year_int_equals_to', 0))
    rds_df_month_int_equals_to = int(args.get('rds_df_month_int_equals_to', 0))
    if rds_df_year_int_equals_to != 0:
        df_parquet_read = df_parquet_read.where(f"""year = {rds_df_year_int_equals_to}""")
    if rds_df_month_int_equals_to != 0:
        df_parquet_read = df_parquet_read.where(f"""month = {rds_df_month_int_equals_to}""")

    df_compare_columns_list = [col for col in df_parquet_read.columns
                               if col not in ['year', 'month', 'day']]

    df_parquet_read_sample = df_parquet_read.sample(validation_sample_fraction_float)\
                                .select(*df_compare_columns_list)

    df_parquet_read_sample_t1 = df_parquet_read_sample.selectExpr(
                                                        *CustomPysparkMethods.get_nvl_select_list(
                                                            df_parquet_read_sample,
                                                            rds_jdbc_conn_obj,
                                                            rds_db_table_name
                                                        )
                                )

    validation_sample_df_repartition_num = int(args['validation_sample_df_repartition_num'])
    if validation_sample_df_repartition_num != 0:
        df_parquet_read_sample_t1 = df_parquet_read_sample_t1.repartition(
                                        validation_sample_df_repartition_num,
                                        jdbc_partition_column
                                    )
    # --------

    df_rds_read_sample = df_rds_read.join(df_parquet_read_sample,
                                          on=jdbc_partition_column,
                                          how='leftsemi')\
                            .select(*df_compare_columns_list)

    df_rds_read_sample_t1 = df_rds_read_sample.selectExpr(
                                *CustomPysparkMethods.get_nvl_select_list(
                                    df_rds_read_sample,
                                    rds_jdbc_conn_obj,
                                    rds_db_table_name
                                )
                            )
    if validation_sample_df_repartition_num != 0:
        df_rds_read_sample_t1 = df_rds_read_sample_t1.repartition(
                                    validation_sample_df_repartition_num,
                                    jdbc_partition_column
                                )
    # --------

    df_prq_leftanti_rds = df_parquet_read_sample_t1.alias("L")\
                            .join(df_rds_read_sample_t1.alias("R"),
                                on=df_parquet_read_sample_t1.columns,
                                how='leftanti')

    # df_prq_leftanti_rds = df_parquet_read_sample_t1.alias("L")\
    #                             .join(df_rds_read_sample_t1.alias("R"),
    #                                   on=jdbc_partition_column, how='left')\
    #                             .where(" or ".join([f"L.{column} != R.{column}"
    #                                                 for column in df_rds_read_sample_t1.columns
    #                                                 if column != jdbc_partition_column]))\
    #                             .select("L.*")

    df_prq_read_filtered_count = df_prq_leftanti_rds.count()

    LOGGER.info(f"""Rows sample taken = {df_parquet_read_sample.count()}""")

    if df_prq_read_filtered_count == 0:
        df_temp_row = spark.sql(f"""select 
                                    current_timestamp() as run_datetime, 
                                    '' as json_row,
                                    "{rds_db_table_name} - Sample Rows Validated." as validation_msg,
                                    '{rds_jdbc_conn_obj.rds_db_name}' as database_name,
                                    '{db_sch_tbl}' as full_table_name,
                                    'False' as table_to_ap
                                """.strip())

        LOGGER.info(f"{rds_db_table_name}: Validation Successful - 1")
        df_dv_output = df_dv_output.union(df_temp_row)
    else:
        msg_part_1 = f"""df_rds_read_count = {df_rds_read.count()}"""
        msg_part_2 = f"""df_parquet_read_count = {df_parquet_read.count()}"""
        LOGGER.warn(f"""{msg_part_1}; {msg_part_2}""")

        LOGGER.warn(
            f"""Parquet-RDS Subtract Report: ({df_prq_read_filtered_count}): Row differences found!""")

        df_subtract_temp = (df_prq_leftanti_rds
                            .withColumn('json_row', F.to_json(F.struct(*[F.col(c)
                                                                         for c in df_rds_read.columns])))
                            .selectExpr("json_row")
                            .limit(100))

        subtract_validation_msg = f"""'{rds_db_table_name}' - {df_prq_read_filtered_count}"""
        df_subtract_temp = df_subtract_temp.selectExpr(
            "current_timestamp as run_datetime",
            "json_row",
            f""""{subtract_validation_msg} - Dataframe(s)-Subtract Non-Zero Sample Row Count!" as validation_msg""",
            f"""'{rds_jdbc_conn_obj.rds_db_name}' as database_name""",
            f"""'{db_sch_tbl}' as full_table_name""",
            """'False' as table_to_ap"""
        )
        LOGGER.warn(f"{rds_db_table_name}: Validation Failed - 2")
        df_dv_output = df_dv_output.union(df_subtract_temp)
    # -----------------------------------------------------

    return df_dv_output


def write_to_s3_parquet(df_dv_output: DataFrame,
                        rds_jdbc_conn_obj,
                        db_sch_tbl_name):

    db_name = rds_jdbc_conn_obj.rds_db_name
    df_dv_output = df_dv_output.repartition(1)

    prq_table_folder_path = f"""{args["glue_catalog_db_name"]}/{args["glue_catalog_tbl_name"]}"""
    s3_table_folder_path = f'''s3://{DV_PARQUET_OUTPUT_S3_BUCKET_NAME}/{prq_table_folder_path}'''

    if S3Methods.check_s3_folder_path_if_exists(DV_PARQUET_OUTPUT_S3_BUCKET_NAME,
                                                f'''{prq_table_folder_path}/database_name={db_name}/full_table_name={db_sch_tbl_name}'''
                                                ):
        LOGGER.info(
            f"""Purging S3-path: {s3_table_folder_path}/database_name={db_name}/full_table_name={db_sch_tbl_name}""")

        glueContext.purge_s3_path(f"""{s3_table_folder_path}/database_name={db_name}/full_table_name={db_sch_tbl_name}""",
                                  options={"retentionPeriod": 0}
                                  )
    # ---------------------------------------------------------------------

    dydf = DynamicFrame.fromDF(df_dv_output, glueContext, "final_spark_df")

    glueContext.write_dynamic_frame.from_options(frame=dydf, connection_type='s3', format='parquet',
                                                 connection_options={
                                                     'path': f"""{s3_table_folder_path}/""",
                                                     "partitionKeys": ["database_name", "full_table_name"]
                                                 },
                                                 format_options={
                                                     'useGlueParquetWriter': True,
                                                     'compression': 'snappy',
                                                     'blockSize': 13421773,
                                                     'pageSize': 1048576
                                                 })
    LOGGER.info(
        f"""'{db_sch_tbl_name}' validation report written to -> {s3_table_folder_path}/""")

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

    if args.get('rds_db_tbl_pkeys_col_list', None) is None:
        try:
            rds_db_tbl_pkeys_col_list = [column.strip()
                                         for column in RECORDED_PKEYS_LIST[rds_sqlserver_db_table]]
        except Exception as e:
            LOGGER.error(
                f"""Runtime Parameter 'rds_db_tbl_pkeys_col_list' - value(s) not given!
                AND
                Global Dictionary - 'RECORDED_PKEYS_LIST' has no key '{rds_sqlserver_db_table}'!
                """.strip())
            sys.exit(1)
    else:
        rds_db_tbl_pkeys_col_list = [f"""{column.strip().strip("'").strip('"')}"""
                                     for column in args['rds_db_tbl_pkeys_col_list'].split(",")]
        LOGGER.info(f"""rds_db_tbl_pkeys_col_list = {rds_db_tbl_pkeys_col_list}""")
    # -----------------------------------------

    rds_db_table_empty_df = rds_jdbc_conn_obj.get_rds_db_table_empty_df(rds_sqlserver_db_table)

    df_rds_dtype_dict = CustomPysparkMethods.get_dtypes_dict(rds_db_table_empty_df)
    int_dtypes_colname_list = [colname for colname, dtype in df_rds_dtype_dict.items()
                               if dtype in INT_DATATYPES_LIST]

    if len(rds_db_tbl_pkeys_col_list) == 1 and \
            (rds_db_tbl_pkeys_col_list[0] in int_dtypes_colname_list):

        jdbc_partition_column = rds_db_tbl_pkeys_col_list[0]
        LOGGER.info(f"""jdbc_partition_column = {jdbc_partition_column}""")
    else:
        LOGGER.error(f"""int_dtypes_colname_list = {int_dtypes_colname_list}
        PrimaryKey column(s) are more than one (OR) not an integer datatype column!
        """.strip())
        sys.exit(1)
    # ----------------------------------------------------

    rds_df_year_int_equals_to = int(args.get('rds_df_year_int_equals_to', 0))
    rds_df_month_int_equals_to = int(args.get('rds_df_month_int_equals_to', 0))

    # Note:> 'rds_df_year_int_equals_to', 'rds_df_month_int_equals_to' are mandatory if 'rds_query_where_clause' is given
    # Note:> 'rds_df_year_int_equals_to', 'rds_df_month_int_equals_to' used in RDS-DB-Table and Parquet Dataframe(s) filetrs.
    if args.get('rds_query_where_clause', '') != '':
        if rds_df_year_int_equals_to == 0 or rds_df_month_int_equals_to == 0:
            LOGGER.error(
                f"""The values for 'rds_df_year_int_equals_to' or 'rds_df_month_int_equals_to' not given""")
            sys.exit(1)

    rds_table_total_size_mb = int(args['rds_table_total_size_mb'])
    if rds_table_total_size_mb != 0:
        if args.get("jdbc_read_256mb_partitions", "false") == "true":
            jdbc_read_partitions_num = int(rds_table_total_size_mb/256)
        elif args.get("jdbc_read_512mb_partitions", "false") == "true":
            jdbc_read_partitions_num = int(rds_table_total_size_mb/512)
        elif args.get("jdbc_read_1gb_partitions", "false") == "true":
            jdbc_read_partitions_num = int(rds_table_total_size_mb/1024)
        elif args.get("jdbc_read_2gb_partitions", "false") == "true":
            jdbc_read_partitions_num = int((rds_table_total_size_mb/1024)/2)
        else:
            raise ValueError(
                """>> When 'rds_table_total_size_mb' != 0, one of the 'jdbc_read_partition' size inputs needs to be enabled ! <<""")
    else:
        jdbc_read_partitions_num = int(args.get('jdbc_read_partition_num', 0))
    # ------------------------------

    jdbc_read_partitions_num = 1 if jdbc_read_partitions_num <= 0 else jdbc_read_partitions_num
    LOGGER.info(f"""jdbc_read_partitions_num = {jdbc_read_partitions_num}""")

    # rds_jdbc_conn_obj.get_min_max_pkey(jdbc_partition_column, 'min')
    # rds_jdbc_conn_obj.get_min_max_pkey(jdbc_partition_column, 'max')
    agg_row_dict = rds_jdbc_conn_obj.get_min_max_pkey_filter(
                                        rds_sqlserver_db_table,
                                        jdbc_partition_column,
                                        args.get('rds_query_where_clause', None)
                                    )
    # 'rds_query_where_clause' filter used to fetch minimum & maximum primary-key values ...
    min_pkey = agg_row_dict['min_value']
    max_pkey = agg_row_dict['max_value']

    if jdbc_read_partitions_num == 1:
        # Here 'min_pkey' and 'max_pkey' are used as table-row filters.
        df_rds_read = rds_jdbc_conn_obj.get_rds_df_read_pkey_min_max_range(
                                            rds_sqlserver_db_table,
                                            jdbc_partition_column,
                                            min_pkey,
                                            max_pkey)
    else:
        # Here 'min_pkey' and 'max_pkey' are used
        # 1. as table-row filters.
        # 2. as 'lowerBound' and 'upperBound' along with 'partitionColumn'
        df_rds_read = rds_jdbc_conn_obj.get_rds_df_read_pkey_min_max_range(
                                            rds_sqlserver_db_table,
                                            jdbc_partition_column,
                                            min_pkey,
                                            max_pkey,
                                            jdbc_read_partitions_num)
    # ----------------------------------------------------------
    LOGGER.info(
        f"""df_rds_read-{db_sch_tbl}: READ PARTITIONS = {df_rds_read.rdd.getNumPartitions()}""")

    rds_read_columns = df_rds_read.columns
    LOGGER.info(f"""1. rds_read_columns = {rds_read_columns}""")

    date_partition_column_name = args.get('date_partition_column_name', None)

    # Add 'YEAR', 'MONTH', 'DAY' columns to the dataframe.
    if date_partition_column_name is not None:
        LOGGER.info(f"""date_partition_column_name = {date_partition_column_name}""")

        if args['add_year_partition_bool'] == 'true' and \
            'year' not in rds_read_columns:
            df_rds_read = df_rds_read.withColumn("year", F.year(date_partition_column_name))
        # --------------------------------------------------------------------------------

        if args['add_month_partition_bool'] == 'true' and \
            'month' not in rds_read_columns:
            df_rds_read = df_rds_read.withColumn("month", F.month(date_partition_column_name))
        # --------------------------------------------------------------------------------

        # if args['day_partition_bool'] == 'true':
        #     df_rds_read = df_rds_read.withColumn("day", F.dayofmonth(given_date_column))
        #     partition_by_cols.append("day")
        # ----------------------------------------------------

    else:
        LOGGER.warn(f""">> 'date_partition_column_name' input not given <<""")
    # ----------------------------------------------------

    rds_read_columns = df_rds_read.columns
    LOGGER.info(f"""2. rds_read_columns = {rds_read_columns}""")

    partition_by_cols = list()

    if 'year' in rds_read_columns:
        partition_by_cols.append("year")
        if rds_df_year_int_equals_to != 0:
            LOGGER.info(f"""rds_df_year_int_equals_to = {rds_df_year_int_equals_to}""")
            df_rds_read = df_rds_read.where(f"""year = {rds_df_year_int_equals_to}""")
    else:
        LOGGER.error(f""">> 'year' column missing in 'df_rds_read'-dataframe <<""")
        sys.exit(1)
    # ----------------------------------------------------------------------------

    if 'month' in rds_read_columns:
        partition_by_cols.append("month")
        if rds_df_month_int_equals_to != 0:
            LOGGER.info(f"""rds_df_month_int_equals_to = {rds_df_month_int_equals_to}""")
            df_rds_read = df_rds_read.where(f"""month = {rds_df_month_int_equals_to}""")
    else:
        LOGGER.error(f""">> 'month' column missing in 'df_rds_read'-dataframe <<""")
        sys.exit(1)
    # ----------------------------------------------------------------------------

    rds_df_repartition_num = int(args['rds_df_repartition_num'])

    if partition_by_cols and rds_df_repartition_num != 0:
        LOGGER.info(f"""partition_by_cols = {partition_by_cols}""")
        # Note: Default 'orderby_columns' values may not be appropriate for all the scenarios.
        # So, the user can edit the list-'orderby_columns' value(s) if required at runtime.
        # Example: orderby_columns = ['month']
        # The above scenario may be when the rds-source-dataframe filtered on single 'year' value.
        orderby_columns = partition_by_cols + [jdbc_partition_column]

        LOGGER.info(
            f"""df_rds_read-Repartitioning ({rds_df_repartition_num}) on {orderby_columns}""")
        df_rds_read = df_rds_read.repartition(rds_df_repartition_num, *orderby_columns)
    elif rds_df_repartition_num != 0:
        # Note: repartitioning on 'jdbc_partition_column' may optimize the joins on this column downstream.
        LOGGER.info(
            f"""df_rds_read-Repartitioning ({rds_df_repartition_num}) on {jdbc_partition_column}""")
        df_rds_read = df_rds_read.repartition(rds_df_repartition_num, jdbc_partition_column)
        LOGGER.info(
            f"""df_rds_read: After Repartitioning -> {df_rds_read.rdd.getNumPartitions()} partitions.""")
        # ----------------------------------------------------

    rename_output_table_folder = args.get('rename_migrated_prq_tbl_folder', '')
    if rename_output_table_folder == '':
        rds_db_table_name = rds_sqlserver_db_table
    else:
        rds_db_table_name = rename_output_table_folder
    # ---------------------------------------

    prq_table_folder_path = f"""{rds_db_name}/{rds_sqlserver_db_schema}/{rds_db_table_name}"""
    LOGGER.info(f"""prq_table_folder_path = {prq_table_folder_path}""")

    total_files, total_size = S3Methods.get_s3_folder_info(PARQUET_OUTPUT_S3_BUCKET_NAME,
                                                           f"{prq_table_folder_path}/")
    msg_part_1 = f"""> total_files={total_files}"""
    msg_part_2 = f"""> total_size_mb={total_size/1024/1024:.2f}"""
    LOGGER.info(f"""{msg_part_1}, {msg_part_2}""")

    validation_only_run = args['validation_only_run']

    validation_sample_fraction_float = float(args.get('validation_sample_fraction_float', 0))
    if validation_only_run != "true":
        if validation_sample_fraction_float != 0:
            df_rds_read = df_rds_read.cache()

        # Note: If many small size parquet files are created for each partition,
        # consider using 'orderBy', 'coalesce' features appropriately before writing dataframe into S3 bucket.
        # df_rds_write = df_rds_read.coalesce(1)

        # NOTE: When filtered rows (ex: based on 'year') are used in separate consecutive batch runs,
        # consider to appropriately use the parquet write functions with features in built as per the below details.
        # - write_rds_df_to_s3_parquet(): Overwrites the existing partitions by default.
        # - write_rds_df_to_s3_parquet_v2(): Adds the new partitions & also the corresponding partitions are updated in athena tables.
        write_rds_df_to_s3_parquet(df_rds_read,
                                   partition_by_cols,
                                   prq_table_folder_path)
    else:
        LOGGER.info(f"""** validation_only_run = '{validation_only_run}' **""")
    # -----------------------------------------------

    if validation_sample_fraction_float != 0:
        LOGGER.info(
            f"""Validating {validation_sample_fraction_float}-sample rows from the migrated data.""")
        # The below function runs a 'leftsemi' join between RDS-DB-Table Dataframe and the Parquet-Dataframe
        df_dv_output = compare_rds_parquet_samples(rds_jdbc_conn_obj,
                                                   rds_sqlserver_db_table,
                                                   df_rds_read,
                                                   jdbc_partition_column,
                                                   prq_table_folder_path,
                                                   validation_sample_fraction_float)

        write_to_s3_parquet(df_dv_output, rds_jdbc_conn_obj, db_sch_tbl)

        df_rds_read.unpersist(True)
    else:
        LOGGER.warn(f""">> No data validation process was run <<""")
    # ------------------------------------------------------------

    job.commit()
