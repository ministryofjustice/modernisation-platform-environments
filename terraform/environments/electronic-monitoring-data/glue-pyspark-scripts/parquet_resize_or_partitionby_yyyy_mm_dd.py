
import sys
# import typing as RT

# from logging import getLogger
# import pandas as pd

from glue_data_validation_lib import SparkSession
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
                       "s3_prq_read_bucket_name",
                       "s3_prq_write_bucket_name",
                       "s3_prq_read_db_folder",
                       "s3_prq_read_db_schema_folder",
                       "s3_prq_read_table_folder",
                       "add_year_partition_bool",
                       "add_month_partition_bool",
                       "s3_prq_write_table_folder",
                       "coalesce_int",
                       "prq_df_repartition_int"
                       ]

OPTIONAL_INPUTS = [
    "date_partition_column",
    "s3_prq_df_read_where_clause",
    "primarykey_column",
    "year_int_equals_to",
    "month_int_equals_to"
]

AVAILABLE_ARGS_LIST = CustomPysparkMethods.resolve_args(DEFAULT_INPUTS_LIST+OPTIONAL_INPUTS)

args = getResolvedOptions(sys.argv, AVAILABLE_ARGS_LIST)

# ------------------------------

job = Job(glueContext)
job.init(args["JOB_NAME"], args)

# ------------------------------

PARQUET_READ_S3_BUCKET_NAME = args["s3_prq_read_bucket_name"]
PARQUET_WRITE_S3_BUCKET_NAME = args["s3_prq_write_bucket_name"]

PRQ_READ_TABLE_FOLDER_PATH = f"""{args['s3_prq_read_db_folder']}/{args['s3_prq_read_db_schema_folder']}/{args['s3_prq_read_table_folder']}"""
PRQ_WRITE_TABLE_FOLDER_PATH = f"""{args['s3_prq_read_db_folder']}/{args['s3_prq_read_db_schema_folder']}/{args['s3_prq_write_table_folder']}"""

# ===============================================================================
# USER-DEFINED-FUNCTIONS
# ----------------------


def write_to_s3_parquet(df_prq_write: DataFrame,
                        partition_by_cols):
    """
    Write dynamic frame in S3 and catalog it.
    """

    # s3://dms-rds-to-parquet-20240606144708618700000001/g4s_emsys_mvp/dbo/GPSPosition_V2/year=2019/month=10/

    s3_table_folder_path = f"""s3://{PARQUET_WRITE_S3_BUCKET_NAME}/{PRQ_WRITE_TABLE_FOLDER_PATH}"""

    dynamic_df_write = glueContext.getSink(
                                    format_options={
                                        "compression": "snappy",
                                        "useGlueParquetWriter": True
                                    },
                                    path=f"""{s3_table_folder_path}/""",
                                    connection_type="s3",
                                    partitionKeys=partition_by_cols
                                )

    dynamic_df_write.setFormat("glueparquet")

    dydf_prq_write = DynamicFrame.fromDF(df_prq_write, glueContext, "final_spark_df")
    dynamic_df_write.writeFrame(dydf_prq_write)

    LOGGER.info(
        f"""'{PRQ_WRITE_TABLE_FOLDER_PATH}' table data written to -> {s3_table_folder_path}/""")


# ===================================================================================================

# s3://dms-rds-to-parquet-20240606144708618700000001/g4s_emsys_mvp/dbo/GPSPosition_V2/year=2020/month=3/

if __name__ == "__main__":

    s3_prq_read_table_folder_path = f"""s3://{PARQUET_READ_S3_BUCKET_NAME}/{PRQ_READ_TABLE_FOLDER_PATH}/"""
    LOGGER.info(f"""Parquet Source being used: {s3_prq_read_table_folder_path}""")

    if S3Methods.check_s3_folder_path_if_exists(PARQUET_READ_S3_BUCKET_NAME,
                                                PRQ_READ_TABLE_FOLDER_PATH):
        df_parquet_read = spark.read.parquet(s3_prq_read_table_folder_path)
    else:
        raise FileNotFoundError(f"""PATH NOT FOUND:>> {s3_prq_read_table_folder_path}""")
    read_df_msg = f"""READ PARTITIONS = {df_parquet_read.rdd.getNumPartitions()}"""
    LOGGER.info(f"""df_parquet_read-{s3_prq_read_table_folder_path}:\n> {read_df_msg}""")

    df_parquet_read_columns_list = df_parquet_read.columns
    date_partition_column = args.get('date_partition_column', None)
    partition_by_cols = list()
    output_partition_path = PRQ_WRITE_TABLE_FOLDER_PATH

    if date_partition_column is not None:
        if args.get("add_year_partition_bool", "false") == "true":
            if 'year' not in df_parquet_read_columns_list:
                df_parquet_read = df_parquet_read.withColumn("year", F.year(date_partition_column))
            partition_by_cols.append("year")

        if args.get("add_month_partition_bool", "false") == "true":
            if 'month' not in df_parquet_read_columns_list:
                df_parquet_read = df_parquet_read.withColumn("month", F.month(date_partition_column))
            partition_by_cols.append("month")

        # if args.get("add_day_partition_bool", "false") == "true":
        #     if 'day' not in df_parquet_read_columns_list:
        #         df_parquet_read = df_parquet_read.withColumn("day", F.dayofmonth(date_partition_column))
        #     partition_by_cols.append("day")
        
    else:
         LOGGER.warn(f""">> 'date_partition_column' input not given ! << """)
    # ----------------------------------
    LOGGER.info(f"""partition_by_cols = {partition_by_cols}""")

    year_int_equals_to = int(args.get('year_int_equals_to', 0))
    if year_int_equals_to != 0:
        df_parquet_read = df_parquet_read.where(f"""year = {year_int_equals_to}""")
        LOGGER.warn(
            f"""'df_parquet_read' being filtered on year = {year_int_equals_to}.""")
        output_partition_path = output_partition_path + \
            f"""/year={year_int_equals_to}"""
    # ----------------------------------

    month_int_equals_to = int(args.get('month_int_equals_to', 0))
    if month_int_equals_to != 0:
        df_parquet_read = df_parquet_read.where(f"""month = {month_int_equals_to}""")
        LOGGER.warn(
            f"""'df_parquet_read' being filtered on month = {month_int_equals_to}.""")
        output_partition_path = output_partition_path + \
            f"""/month={month_int_equals_to}"""
    # --------------------------------------------------

    s3_prq_df_read_where_clause = args.get('s3_prq_df_read_where_clause', '').strip()
    if s3_prq_df_read_where_clause != '':
        df_parquet_read = df_parquet_read.where(f"""{s3_prq_df_read_where_clause}""")
        LOGGER.warn(
            f"""'df_parquet_read' being filtered on:> {s3_prq_df_read_where_clause}.""")

    prq_df_repartition_int = int(args.get('prq_df_repartition_int', 0))
    primarykey_column = args.get('primarykey_column', '')
    if partition_by_cols and prq_df_repartition_int != 0:
        LOGGER.info(
            f"""df_parquet_read-Repartitioning ({prq_df_repartition_int}) on {partition_by_cols}.""")
        df_parquet_read = df_parquet_read.repartition(prq_df_repartition_int, *partition_by_cols)
    elif prq_df_repartition_int != 0 and primarykey_column != '':
        LOGGER.info(
            f"""df_rds_read-Repartitioning ({prq_df_repartition_int}) on {primarykey_column}.""")
        df_parquet_read = df_parquet_read.repartition(prq_df_repartition_int, primarykey_column)
    elif prq_df_repartition_int != 0:
        LOGGER.info(
            f"""df_rds_read-Repartitioning to {prq_df_repartition_int} partitions.""")
        df_parquet_read = df_parquet_read.repartition(prq_df_repartition_int)

    if prq_df_repartition_int != 0:
        LOGGER.info(
            f"""df_parquet_read: After Repartitioning -> {df_parquet_read.rdd.getNumPartitions()} partitions.""")

    # Note: Just for guidance,> coalesce_int ~= Number of workers * (partition(s) per each worker).
    # This may not be a right formulae for small size data.
    coalesce_int = int(args.get('coalesce_int', 0))
    if coalesce_int != 0:
        LOGGER.warn(f"""df_parquet_read:> coalesce_int = {coalesce_int}""")
        df_parquet_write = df_parquet_read.coalesce(coalesce_int)
    else:
        df_parquet_write = df_parquet_read.alias("df_parquet_write")

    write_df_msg = f"""WRITE PARTITIONS = {df_parquet_write.rdd.getNumPartitions()}"""
    LOGGER.info(f"""df_parquet_write-{output_partition_path}:\n> {write_df_msg}""")

    write_to_s3_parquet(df_parquet_write,
                        partition_by_cols)
    # -----------------------------------------------

    total_files, total_size = S3Methods.get_s3_folder_info(PARQUET_WRITE_S3_BUCKET_NAME,
                                                           f"{output_partition_path}/")
    msg_part_1 = f"""total_files={total_files}"""
    msg_part_2 = f"""total_size_mb={total_size/1024/1024:.2f}"""
    LOGGER.info(f"""'{PRQ_WRITE_TABLE_FOLDER_PATH}': {msg_part_1}, {msg_part_2}""")

    job.commit()
