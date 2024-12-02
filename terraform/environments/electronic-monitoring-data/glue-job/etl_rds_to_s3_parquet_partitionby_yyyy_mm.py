
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
# import pyspark.sql.types as T

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
                       "jdbc_read_partition_num",
                       "rds_to_parquet_output_s3_bucket",
                       "rds_sqlserver_db",
                       "rds_sqlserver_db_schema",
                       "rds_sqlserver_db_table",
                       "rds_db_tbl_pkeys_col_list",
                       "date_partition_column_name",
                       "rds_df_repartition_num",
                       "year_partition_bool",
                       "month_partition_bool",
                       "coalesce_int"
                       ]

OPTIONAL_INPUTS = [
    "other_partitionby_columns",
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

ATHENA_RUN_OUTPUT_LOCATION = f"s3://{PARQUET_OUTPUT_S3_BUCKET_NAME}/athena_temp_store/"

NVL_DTYPE_DICT = Logical_Constants.NVL_DTYPE_DICT

INT_DATATYPES_LIST = Logical_Constants.INT_DATATYPES_LIST

RECORDED_PKEYS_LIST = Logical_Constants.RECORDED_PKEYS_LIST

# ===============================================================================


def write_rds_df_to_s3_parquet_v2(df_rds_write: DataFrame,
                                  partition_by_cols,
                                  prq_table_folder_path):
    """
    Write dynamic frame in S3 and catalog it.
    """

    # s3://dms-rds-to-parquet-20240606144708618700000001/g4s_emsys_mvp/dbo/GPSPosition_V2/
    # s3://dms-rds-to-parquet-20240606144708618700000001/g4s_emsys_mvp/dbo/GPSPosition_V2/year=2019/month=10/

    s3_table_folder_path = f"""s3://{PARQUET_OUTPUT_S3_BUCKET_NAME}/{prq_table_folder_path}"""

    # Note: The below block of code erases the existing partition & use cautiously.
    # partition_path = f"""{s3_table_folder_path}/year=2019/month=10/"""
    # if check_s3_folder_path_if_exists(PARQUET_OUTPUT_S3_BUCKET_NAME, partition_path):

    #     LOGGER.info(f"""Purging S3-path: {partition_path}""")
    #     glueContext.purge_s3_path(partition_path, options={"retentionPeriod": 0})
    # # --------------------------------------------------------------------

    dynamic_df_write = glueContext.getSink(
        format_options={
            "compression": "snappy",
            "useGlueParquetWriter": True
        },
        path=f"""{s3_table_folder_path}/""",
        connection_type="s3",
        updateBehavior="UPDATE_IN_DATABASE",
        partitionKeys=partition_by_cols,
        enableUpdateCatalog=True,
        transformation_ctx="dynamic_df_write",
    )

    catalog_db, catalog_db_tbl = prq_table_folder_path.split(f"""/{args['rds_sqlserver_db_schema']}/""")
    dynamic_df_write.setCatalogInfo(
        catalogDatabase=catalog_db.lower(),
        catalogTableName=catalog_db_tbl.lower()
    )

    dynamic_df_write.setFormat("glueparquet")

    dydf_rds_read = DynamicFrame.fromDF(df_rds_write, glueContext, "final_spark_df")
    dynamic_df_write.writeFrame(dydf_rds_read)

    LOGGER.info(f"""'{db_sch_tbl}' table data written to -> {s3_table_folder_path}/""")

    # ddl_refresh_table_partitions = f"msck repair table {catalog_db.lower()}.{catalog_db_tbl.lower()}"
    # LOGGER.info(f"""ddl_refresh_table_partitions:> \n{ddl_refresh_table_partitions}""")

    # # Refresh table prtitions
    # execution_id = run_athena_query(ddl_refresh_table_partitions)
    # LOGGER.info(f"SQL-Statement execution id: {execution_id}")

    # # Check query execution
    # query_status = has_query_succeeded(execution_id=execution_id)
    # LOGGER.info(f"Query state: {query_status}")


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

# ===================================================================================================


if __name__ == "__main__":

    # VERIFY GIVEN INPUTS - START
    # -------------------------------------------

    if args.get("rds_sqlserver_db", None) is None:
        LOGGER.error(f"""'rds_sqlserver_db' runtime input is missing! Exiting ...""")
        sys.exit(1)
    else:
        rds_sqlserver_db = args["rds_sqlserver_db"]
        LOGGER.info(f"""Given rds_sqlserver_db = {rds_sqlserver_db}""")

    if args.get("rds_sqlserver_db_schema", None) is None:
        LOGGER.error(f"""'rds_sqlserver_db_schema' runtime input is missing! Exiting ...""")
        sys.exit(1)
    else:
        rds_sqlserver_db_schema = args["rds_sqlserver_db_schema"]
        LOGGER.info(f"""Given rds_sqlserver_db_schema = {rds_sqlserver_db_schema}""")
    # -------------------------------------------

    rds_jdbc_conn_obj = RDS_JDBC_CONNECTION(RDS_DB_HOST_ENDPOINT,
                                            RDS_DB_INSTANCE_PWD,
                                            rds_sqlserver_db,
                                            rds_sqlserver_db_schema)
    
    try:
        rds_db_name = rds_jdbc_conn_obj.check_if_rds_db_exists()[0]
    except IndexError:
        LOGGER.error(f"""Given database name not found! >> {args['rds_sqlserver_db']} <<""")
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
        LOGGER.error(f"""'rds_sqlserver_db_table' runtime input is missing! Exiting ...""")
        sys.exit(1)
    else:
        rds_sqlserver_db_table = args["rds_sqlserver_db_table"]
        table_name_prefix = f"""{rds_db_name}_{rds_sqlserver_db_schema}"""
        db_sch_tbl = f"""{table_name_prefix}_{rds_sqlserver_db_table}"""
    # --------------------------------------------------------------------

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
        LOGGER.error(
            f"""int_dtypes_colname_list = {int_dtypes_colname_list}""")
        LOGGER.error(
            f"""PrimaryKey column(s) are more than one (OR) not an integer datatype column!""")
        sys.exit(1)
    # ---------------------------------------

    # SET PARQUET-OUTPUT TABLE-FOLDER NAME
    rename_output_table_folder = args.get('rename_migrated_prq_tbl_folder', '')
    if rename_output_table_folder == '':
        rds_db_table_name = rds_sqlserver_db_table
    else:
        rds_db_table_name = rename_output_table_folder
    # ------------------------------------------------

    jdbc_read_partitions_num = int(args['jdbc_read_partition_num'])
    LOGGER.info(f"""jdbc_read_partitions_num = {jdbc_read_partitions_num}""")

    rds_df_repartition_num = int(args['rds_df_repartition_num'])
    LOGGER.info(f"""rds_df_repartition_num = {rds_df_repartition_num}""")

    # ----------------------------------------------------

    partition_by_cols = list()
    if args['year_partition_bool'] == 'true':
        partition_by_cols.append("year")

    if args['month_partition_bool'] == 'true':
        partition_by_cols.append("month")
    
    date_partition_column_name = args.get('date_partition_column_name', '')
    if partition_by_cols and date_partition_column_name == '':
        raise ValueError(f""">> 'date_partition_column_name' not given in the input.<<""")
    
    LOGGER.info(f"""date_partition_column_name = {date_partition_column_name}""")
    # ----------------------------------------------------

    if args.get('other_partitionby_columns', None) is not None:
        other_partitionby_columns = [f"""{column.strip().strip("'").strip('"')}"""
                                     for column in args['other_partitionby_columns'].split(",")]
        partition_by_cols.extend(other_partitionby_columns)
        LOGGER.info(f"""other_partitionby_columns = {other_partitionby_columns}""")

    LOGGER.info(f"""partition_by_cols = {partition_by_cols}""")
    # -----------------------------------------
    # VERIFY GIVEN INPUTS - END
    # -----------------------------------------

    agg_row_dict_list = rds_jdbc_conn_obj.get_min_max_groupby_month(
                                            rds_sqlserver_db_table,
                                            date_partition_column_name,
                                            jdbc_partition_column,
                                            args.get('rds_query_where_clause', None)
                                        )
    LOGGER.info(f"""agg_row_dict_list:>\n{[agg_row_dict for agg_row_dict in agg_row_dict_list]}""")


    prq_table_folder_path = f"""{rds_db_name}/{rds_sqlserver_db_schema}/{rds_db_table_name}"""

    for agg_row_dict in agg_row_dict_list:

        agg_row_year = agg_row_dict['year']
        agg_row_month = agg_row_dict['month']
        min_pkey_value = agg_row_dict['min_pkey_value']
        max_pkey_value = agg_row_dict['max_pkey_value']
        LOGGER.info(f"""agg_row_year = {agg_row_year}""")
        LOGGER.info(f"""agg_row_month = {agg_row_month}""")
        LOGGER.info(f"""min_pkey_value = {min_pkey_value}""")
        LOGGER.info(f"""max_pkey_value = {max_pkey_value}""")

        if jdbc_read_partitions_num == 1:
            df_rds_read = rds_jdbc_conn_obj.get_rds_df_read_pkey_min_max_range(
                                                rds_sqlserver_db_table,
                                                jdbc_partition_column,
                                                min_pkey_value, 
                                                max_pkey_value
                            )
        else:
            df_rds_read = rds_jdbc_conn_obj.get_rds_df_read_pkey_min_max_range(
                                                rds_sqlserver_db_table,
                                                jdbc_partition_column,
                                                min_pkey_value,
                                                max_pkey_value,
                                                jdbc_read_partitions_num
                            )
        # ----------------------------------------------------------
        LOGGER.info(
            f"""df_rds_read-{db_sch_tbl}: READ PARTITIONS = {df_rds_read.rdd.getNumPartitions()}""")

        if args.get('rds_query_where_clause', None) is not None:
            df_rds_read = df_rds_read.where(f"""{args['rds_query_where_clause'].strip()}""")
        # ----------------------------------------------------

        if 'year' in partition_by_cols \
            and 'year' not in df_rds_read.columns:
            df_rds_read = df_rds_read.withColumn("year", F.year(date_partition_column_name))

        if 'month' in partition_by_cols \
            and 'month' not in df_rds_read.columns:
            df_rds_read = df_rds_read.withColumn("month", F.month(date_partition_column_name))

        df_rds_read = df_rds_read.where(f"""year = {agg_row_year} and month = {agg_row_month}""")

        if partition_by_cols and rds_df_repartition_num != 0:
            # Note: Default 'partitionby_columns' values may not be appropriate for all the scenarios.
            # So, the user can edit the list-'partitionby_columns' value(s) if required at runtime.
            # Example: partitionby_columns = ['month']
            # The above scenario may be when the rds-source-dataframe filtered on single 'year' value.
            partitionby_columns = partition_by_cols + [jdbc_partition_column]

            LOGGER.info(f"""df_rds_read-Repartitioning ({rds_df_repartition_num}) on {partitionby_columns}""")
            df_rds_read = df_rds_read.repartition(rds_df_repartition_num, *partitionby_columns)

        elif rds_df_repartition_num != 0:
            # Note: repartitioning on 'jdbc_partition_column' may optimize the joins on this column downstream.
            LOGGER.info(
                f"""df_rds_read-Repartitioning ({rds_df_repartition_num}) on {jdbc_partition_column}""")
            df_rds_read = df_rds_read.repartition(rds_df_repartition_num, jdbc_partition_column)
            LOGGER.info(
                f"""df_rds_read: After Repartitioning -> {df_rds_read.rdd.getNumPartitions()} partitions.""")
        # ----------------------------------------------------

        # Note: If many small size parquet files are created for each partition,
        # consider using 'orderBy', 'coalesce' features appropriately before writing dataframe into S3 bucket.
        # df_rds_write = df_rds_read.coalesce(1)

        # NOTE: When filtered rows (ex: based on 'year') are used in separate consecutive batch runs,
        # consider to appropriately use the parquet write functions with features in built as per the below details.
        # - write_rds_df_to_s3_parquet(): Overwrites the existing partitions by default.
        # - write_rds_df_to_s3_parquet_v2(): Adds the new partitions & also the corresponding partitions are updated in athena tables.
        coalesce_int = int(args.get('coalesce_int', 0))
        if coalesce_int != 0:
            LOGGER.warn(f"""df_rds_read:> coalesce_int = {coalesce_int}""")
            df_rds_write = df_rds_read.coalesce(coalesce_int)
        else:
            df_rds_write = df_rds_read.alias("df_rds_write")

        write_rds_df_to_s3_parquet(df_rds_write,
                                   partition_by_cols,
                                   prq_table_folder_path)
        
        LOGGER.info(f"""Partition - '{prq_table_folder_path}/{agg_row_year}/{agg_row_month}' writing completed.""")
    # -----------------------------------------------

    total_files, total_size = S3Methods.get_s3_folder_info(PARQUET_OUTPUT_S3_BUCKET_NAME, 
                                                           f"{prq_table_folder_path}/")
    msg_part_1 = f"""total_files={total_files}"""
    msg_part_2 = f"""total_size_mb={total_size/1024/1024:.2f}"""
    LOGGER.info(f"""'{prq_table_folder_path}': {msg_part_1}, {msg_part_2}""")

    job.commit()
