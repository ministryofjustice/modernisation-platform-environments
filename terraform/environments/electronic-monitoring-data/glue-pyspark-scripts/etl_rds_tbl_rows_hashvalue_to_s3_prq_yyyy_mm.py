
import sys

# from logging import getLogger
# import pandas as pd

from glue_data_validation_lib import RDSConn_Constants
from glue_data_validation_lib import SparkSession
from glue_data_validation_lib import Logical_Constants
from glue_data_validation_lib import RDS_JDBC_CONNECTION
from glue_data_validation_lib import S3Methods
from glue_data_validation_lib import CustomPysparkMethods
from rds_transform_queries import SQLServer_Extract_Transform

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
                       "rds_sqlserver_db",
                       "rds_sqlserver_db_schema",
                       "rds_sqlserver_db_table",
                       "rds_db_tbl_pkey_column",
                       "date_partition_column_name",
                       "rds_yyyy_mm_df_repartition_num",
                       "year_partition_bool",
                       "month_partition_bool",
                       "hashed_output_s3_bucket_name",
                       "rds_db_table_hashed_rows_parent_dir",
                       "incremental_run_bool"
                       ]

OPTIONAL_INPUTS = [
    "rds_query_where_clause",
    "df_where_clause",
    "coalesce_int",
    "parallel_jdbc_conn_num",
    "pkey_lower_bound_int",
    "pkey_upper_bound_int",
    "skip_columns_for_hashing"
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

HASHED_OUTPUT_S3_BUCKET_NAME = args["hashed_output_s3_bucket_name"]
RDS_DB_TABLE_HASHED_ROWS_PARENT_DIR = args["rds_db_table_hashed_rows_parent_dir"]

ATHENA_RUN_OUTPUT_LOCATION = f"s3://{HASHED_OUTPUT_S3_BUCKET_NAME}/athena_temp_store/"

INT_DATATYPES_LIST = Logical_Constants.INT_DATATYPES_LIST

TRANSFORM_COLS_FOR_HASHING_DICT = SQLServer_Extract_Transform.TRANSFORM_COLS_FOR_HASHING_DICT

# ===============================================================================


def write_rds_df_to_s3_parquet_v2(df_rds_write: DataFrame,
                                  partition_by_cols,
                                  prq_table_folder_path):
    """
    Write dynamic frame in S3 and catalog it.
    """

    # s3://dms-rds-to-parquet-20240606144708618700000001/g4s_emsys_mvp/dbo/GPSPosition_V2/
    # s3://dms-rds-to-parquet-20240606144708618700000001/g4s_emsys_mvp/dbo/GPSPosition_V2/year=2019/month=10/

    s3_table_folder_path = f"""s3://{HASHED_OUTPUT_S3_BUCKET_NAME}/{prq_table_folder_path}"""

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

    s3_table_folder_path = f"""s3://{HASHED_OUTPUT_S3_BUCKET_NAME}/{prq_table_folder_path}"""

    df_rds_write.write.mode("overwrite").format("parquet")\
                .partitionBy(partition_by_cols)\
                .save(s3_table_folder_path)
    
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

    rds_db_tbl_pkey_column = args['rds_db_tbl_pkey_column']
    LOGGER.info(f""">> rds_db_tbl_pkey_column = {rds_db_tbl_pkey_column} <<""")

    rds_db_table_empty_df = rds_jdbc_conn_obj.get_rds_db_table_empty_df(
                                                rds_sqlserver_db_table)

    df_rds_dtype_dict = CustomPysparkMethods.get_dtypes_dict(rds_db_table_empty_df)
    int_dtypes_colname_list = [colname for colname, dtype in df_rds_dtype_dict.items()
                               if dtype in INT_DATATYPES_LIST]
    
    if rds_db_tbl_pkey_column not in int_dtypes_colname_list:
        LOGGER.error(
            f"""PrimaryKey column-'{rds_db_tbl_pkey_column}' is not an integer datatype !""")
        sys.exit(1)
    # ---------------------------------------

    skip_columns_for_hashing_str = args.get("skip_columns_for_hashing", None)
    skip_columns_for_hashing = list()
    if skip_columns_for_hashing_str is not None:
        skip_columns_for_hashing = [f"""{col_name.strip().strip("'").strip('"')}"""
                                    for col_name in skip_columns_for_hashing_str.split(",")]
        LOGGER.warn(f"""WARNING ! >> Given skip_columns_for_hashing = {skip_columns_for_hashing}""")
    
    all_columns_except_pkey = list()
    conversion_col_list = list()
    if TRANSFORM_COLS_FOR_HASHING_DICT.get(f"{db_sch_tbl}", None) is not None:
        conversion_col_list = list(TRANSFORM_COLS_FOR_HASHING_DICT[f"{db_sch_tbl}"].keys())

    for e in rds_db_table_empty_df.schema.fields:
        if (e.name == rds_db_tbl_pkey_column) \
            or (e.name in skip_columns_for_hashing):
            continue
        
        if e.name in conversion_col_list:
            all_columns_except_pkey.append(
                TRANSFORM_COLS_FOR_HASHING_DICT[f"{db_sch_tbl}"][f"{e.name}"]
                )
        else:
            all_columns_except_pkey.append(f"{e.name}")

    LOGGER.info(f""">> all_columns_except_pkey = {all_columns_except_pkey} <<""")
    # ---------------------------------------

    date_partition_column_name = args['date_partition_column_name']
    LOGGER.info(f"""date_partition_column_name = {date_partition_column_name}""")

    rds_yyyy_mm_df_repartition_num = int(args['rds_yyyy_mm_df_repartition_num'])
    LOGGER.info(f"""rds_yyyy_mm_df_repartition_num = {rds_yyyy_mm_df_repartition_num}""")

    yyyy_mm_partition_by_cols = list()
    if args['year_partition_bool'] == 'true':
        yyyy_mm_partition_by_cols.append("year")

    if args['month_partition_bool'] == 'true':
        yyyy_mm_partition_by_cols.append("month")

    LOGGER.info(f"""yyyy_mm_partition_by_cols = {yyyy_mm_partition_by_cols}""")

    prq_table_folder_path = f"""
    {RDS_DB_TABLE_HASHED_ROWS_PARENT_DIR}/{rds_db_name}/{rds_sqlserver_db_schema}/{rds_sqlserver_db_table}""".lstrip()
    # -----------------------------------------
    # VERIFY GIVEN INPUTS - END
    # -----------------------------------------

    partial_select_str = f"""SELECT {rds_db_tbl_pkey_column}, """
    if skip_columns_for_hashing_str is not None:
        partial_select_str = partial_select_str + ', '.join(skip_columns_for_hashing)
    
    rds_db_hash_cols_query_str = f"""
    {partial_select_str},
    LOWER(SUBSTRING(CONVERT(VARCHAR(66), 
    HASHBYTES('SHA2_256', CONCAT_WS('', {', '.join(all_columns_except_pkey)})), 1), 3, 66)) AS RowHash,
    YEAR({date_partition_column_name}) AS year,
    MONTH({date_partition_column_name}) AS month
    FROM {rds_sqlserver_db}.{rds_sqlserver_db_schema}.{rds_sqlserver_db_table}
    """.strip()

    incremental_run_bool = args.get('incremental_run_bool', 'false')
    rds_query_where_clause = args.get('rds_query_where_clause', None)

    if rds_query_where_clause is not None:

        rds_db_hash_cols_query_str = rds_db_hash_cols_query_str + \
                                        f""" WHERE {rds_query_where_clause.rstrip()}"""

    elif incremental_run_bool == 'true':
        existing_prq_hashed_rows_df = CustomPysparkMethods.get_s3_parquet_df_v2(
                                    prq_table_folder_path, 
                                    CustomPysparkMethods.get_pyspark_hashed_table_schema(
                                        rds_db_tbl_pkey_column)
                                    )

        existing_prq_hashed_rows_df_agg = existing_prq_hashed_rows_df.agg(
                                            F.max(rds_db_tbl_pkey_column).alias(
                                                f"max_{rds_db_tbl_pkey_column}")
                                            )
        existing_prq_hashed_rows_agg_dict = existing_prq_hashed_rows_df_agg.collect()[0]
        existing_prq_hashed_rows_max_pkey = existing_prq_hashed_rows_agg_dict[f"max_{rds_db_tbl_pkey_column}"]
        rds_query_where_clause = f""" {rds_db_tbl_pkey_column} > {existing_prq_hashed_rows_max_pkey}"""

        rds_db_hash_cols_query_str = rds_db_hash_cols_query_str + \
                                        f""" WHERE {rds_query_where_clause}"""
    # ----------------------------------------------------------

    LOGGER.info(f"""rds_db_hash_cols_query_str = {rds_db_hash_cols_query_str}""")

    pkey_lower_bound_int = int(args.get('pkey_lower_bound_int', 0))
    pkey_upper_bound_int = int(args.get('pkey_upper_bound_int', 0))

    if pkey_lower_bound_int > 0 and pkey_upper_bound_int > 0:

        parallel_jdbc_conn_num = int(args.get('parallel_jdbc_conn_num', 1))
        LOGGER.info(f"""parallel_jdbc_conn_num = {parallel_jdbc_conn_num}""")

        rds_hashed_rows_df = rds_jdbc_conn_obj.get_rds_df_read_query_pkey_parallel(
                                    rds_db_hash_cols_query_str,
                                    rds_db_tbl_pkey_column,
                                    pkey_lower_bound_int,
                                    pkey_upper_bound_int,
                                    parallel_jdbc_conn_num
                                )
    else:
        rds_hashed_rows_df = rds_jdbc_conn_obj.get_rds_df_read_query(rds_db_hash_cols_query_str)
    # ----------------------------------------------------------

    LOGGER.info(
        f"""rds_hashed_rows_df: READ PARTITIONS = {rds_hashed_rows_df.rdd.getNumPartitions()}""")

    if 'year' in yyyy_mm_partition_by_cols \
        and 'year' not in rds_hashed_rows_df.columns:
        rds_hashed_rows_df = rds_hashed_rows_df.withColumn(
                                "year", F.year(date_partition_column_name))
    # ----------------------------------------------------------

    if 'month' in yyyy_mm_partition_by_cols \
        and 'month' not in rds_hashed_rows_df.columns:
        rds_hashed_rows_df = rds_hashed_rows_df.withColumn(
                                "month", F.month(date_partition_column_name))
    # ----------------------------------------------------------

    df_where_clause = args.get('df_where_clause', None)
    if df_where_clause is not None:
        rds_hashed_rows_df = rds_hashed_rows_df.where(f"{df_where_clause}")

    if rds_yyyy_mm_df_repartition_num != 0:
        # Note: Default 'partitionby_columns' values may not be appropriate for all the scenarios.
        # So, the user can edit the list-'partitionby_columns' value(s) if required at runtime.
        # Example: partitionby_columns = ['month']
        # The above scenario may be when the rds-source-dataframe filtered on single 'year' value.
        partitionby_columns = yyyy_mm_partition_by_cols + [rds_db_tbl_pkey_column]

        LOGGER.info(f"""rds_hashed_rows_df: Repartitioning on {partitionby_columns}""")
        rds_hashed_rows_df = rds_hashed_rows_df.repartition(rds_yyyy_mm_df_repartition_num, 
                                                            *partitionby_columns)

        LOGGER.info(
            f"""rds_hashed_rows_df: After Repartitioning -> {rds_hashed_rows_df.rdd.getNumPartitions()} partitions.""")
    # ----------------------------------------------------

    # Note: If many small size parquet files are created for each partition,
    # consider using 'orderBy', 'coalesce' features appropriately before writing dataframe into S3 bucket.
    # df_rds_write = rds_hashed_rows_df.coalesce(1)

    # NOTE: When filtered rows (ex: based on 'year') are used in separate consecutive batch runs,
    # consider to appropriately use the parquet write functions with features in built as per the below details.
    # - write_rds_df_to_s3_parquet(): Overwrites the existing partitions by default.
    # - write_rds_df_to_s3_parquet_v2(): Adds the new partitions & also the corresponding partitions are updated in athena tables.
    coalesce_int = int(args.get('coalesce_int', 0))
    if coalesce_int != 0:
        LOGGER.warn(f"""WARNING ! >> Given coalesce_int = {coalesce_int}""")
        rds_hashed_rows_df_write = rds_hashed_rows_df.coalesce(coalesce_int)
    else:
        rds_hashed_rows_df_write = rds_hashed_rows_df.alias("rds_hashed_rows_df_write")
    # ----------------------------------------------------------

    # rds_hashed_rows_df_write = rds_hashed_rows_df_write.cache()
    # unique_partitions_df = rds_hashed_rows_df_write\
    #                         .select(*yyyy_mm_partition_by_cols)\
    #                         .distinct()\
    #                         .orderBy(yyyy_mm_partition_by_cols, ascending=True)
    
    # for row in unique_partitions_df.toLocalIterator():
    #     LOGGER.info(f"""year: {row[yyyy_mm_partition_by_cols[0]]}, 
    #                 month: {row[yyyy_mm_partition_by_cols[1]]}""")
    
    # write_rds_df_to_s3_parquet_v2(rds_hashed_rows_df_write, 
    #                               yyyy_mm_partition_by_cols, 
    #                               prq_table_folder_path)

    LOGGER.info(f"""write_rds_df_to_s3_parquet() - function called.""")
    write_rds_df_to_s3_parquet(rds_hashed_rows_df_write,
                                yyyy_mm_partition_by_cols,
                                prq_table_folder_path)
    
    LOGGER.info(f"""'{prq_table_folder_path}' writing completed.""")
    # rds_hashed_rows_df_write.unpersist()


    total_files, total_size = S3Methods.get_s3_folder_info(HASHED_OUTPUT_S3_BUCKET_NAME, 
                                                          f"{prq_table_folder_path}/")
    msg_part_1 = f"""total_files={total_files}"""
    msg_part_2 = f"""total_size_mb={total_size/1024/1024:.2f}"""
    LOGGER.info(f"""'{prq_table_folder_path}': {msg_part_1}, {msg_part_2}""")

    job.commit()
