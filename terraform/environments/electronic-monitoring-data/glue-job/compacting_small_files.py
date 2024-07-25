import sys
import boto3
import time
import typing as RT
# from logging import getLogger
# import pandas as pd

from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
# from pyspark.conf import SparkConf
from awsglue.context import GlueContext
from awsglue.dynamicframe import DynamicFrame
from awsglue.job import Job

import pyspark.sql.functions as F
import pyspark.sql.types as T
from pyspark.sql import DataFrame
# from pyspark.storagelevel import StorageLevel
# ===============================================================================

sc = SparkContext()
sc._jsc.hadoopConfiguration().set("spark.dynamicAllocation.enabled", "true")

glueContext = GlueContext(sc)
spark = glueContext.spark_session

LOGGER = glueContext.get_logger()

# ===============================================================================


def resolve_args(args_list):
    LOGGER.info(f">> Resolving Argument Variables: START")
    available_args_list = list()
    for item in args_list:
        try:
            args = getResolvedOptions(sys.argv, [f'{item}'])
            available_args_list.append(item)
        except Exception as e:
            LOGGER.warn(f"WARNING: Missing argument, {e}")
    LOGGER.info(f"AVAILABLE arguments: {available_args_list}")
    LOGGER.info(">> Resolving Argument Variables: COMPLETE")
    return available_args_list

# ===============================================================================


# Organise capturing input parameters.
DEFAULT_INPUTS_LIST = ["JOB_NAME",
                       "script_bucket_name",
                       "s3_prq_read_bucket_name",
                       "s3_prq_write_bucket_name",
                       "s3_prq_read_db_folder",
                       "s3_prq_read_db_schema_folder",
                       "s3_prq_read_table_folder",
                       "year_partition_str",
                       "month_partition_str",
                       "day_partition_str",
                       "s3_prq_write_table_folder"
                       ]

OPTIONAL_INPUTS = [
]

AVAILABLE_ARGS_LIST = resolve_args(DEFAULT_INPUTS_LIST+OPTIONAL_INPUTS)

args = getResolvedOptions(sys.argv, AVAILABLE_ARGS_LIST)

# ------------------------------

job = Job(glueContext)
job.init(args["JOB_NAME"], args)

# ------------------------------

S3_CLIENT = boto3.client("s3")

# ------------------------------

PARQUET_READ_S3_BUCKET_NAME = args["s3_prq_read_bucket_name"]
PARQUET_WRITE_S3_BUCKET_NAME = args["s3_prq_write_bucket_name"]

PRQ_READ_TABLE_FOLDER_PATH = f"""{args['s3_prq_read_db_folder']}/{args['s3_prq_read_db_schema_folder']}/{args['s3_prq_read_table_folder']}"""
PRQ_WRITE_TABLE_FOLDER_PATH = f"""{args['s3_prq_read_db_folder']}/{args['s3_prq_read_db_schema_folder']}/{args['s3_prq_write_table_folder']}"""

# ===============================================================================
# USER-DEFINED-FUNCTIONS
# ----------------------


def get_s3_folder_info(bucket_name, prefix):
    paginator = S3_CLIENT.get_paginator('list_objects_v2')

    total_size = 0
    total_files = 0

    for page in paginator.paginate(Bucket=bucket_name, Prefix=prefix):
        for obj in page.get('Contents', []):
            total_files += 1
            total_size += obj['Size']

    return total_files, total_size


def check_s3_folder_path_if_exists(in_bucket_name, in_folder_path):
    result = S3_CLIENT.list_objects(
        Bucket=in_bucket_name, Prefix=in_folder_path)
    exists = False
    if 'Contents' in result:
        exists = True
    return exists

# ==================================================================


def write_to_s3_parquet(df_prq_write: DataFrame,
                        partition_by_cols):
    """
    Write dynamic frame in S3 and catalog it.
    """

    # s3://dms-rds-to-parquet-20240606144708618700000001/g4s_emsys_mvp/dbo/GPSPosition_V2/year=2019/month=10/

    s3_table_folder_path = f"""s3://{PARQUET_WRITE_S3_BUCKET_NAME}/{PRQ_WRITE_TABLE_FOLDER_PATH}"""

    dynamic_df_write = glueContext.getSink(
                            format_options = {
                                "compression": "snappy", 
                                "useGlueParquetWriter": True
                                },
                            path = f"""{s3_table_folder_path}/""",
                            connection_type = "s3",
                            partitionKeys = partition_by_cols
    )

    dynamic_df_write.setFormat("glueparquet")

    dydf_prq_write = DynamicFrame.fromDF(df_prq_write, glueContext, "final_spark_df")
    dynamic_df_write.writeFrame(dydf_prq_write)

    LOGGER.info(f"""'{PRQ_WRITE_TABLE_FOLDER_PATH}' table data written to -> {s3_table_folder_path}/""")


# ===================================================================================================


if __name__ == "__main__":


    partition_by_cols = list()
    
    year_partition_str = args.get('year_partition_str', '')
    if year_partition_str != '':
        read_prq_partitioned_path = PRQ_READ_TABLE_FOLDER_PATH+f"""/{year_partition_str}"""

        write_prq_partitioned_path = PRQ_WRITE_TABLE_FOLDER_PATH+f"""/{year_partition_str}"""
        partition_by_cols.append("year")
    
    month_partition_str = args.get('month_partition_str', '')
    if month_partition_str != '':
        read_prq_partitioned_path = read_prq_partitioned_path+f"""/{month_partition_str}"""

        write_prq_partitioned_path = write_prq_partitioned_path+f"""/{month_partition_str}"""
        partition_by_cols.append("month")
    
    day_partition_str = args.get('day_partition_str', '')
    if day_partition_str != '':
        read_prq_partitioned_path = read_prq_partitioned_path+f"""/{day_partition_str}"""
        
        write_prq_partitioned_path = write_prq_partitioned_path+f"""/{day_partition_str}"""
        partition_by_cols.append("day")

    s3_prq_read_table_folder_path = f"""s3://{PARQUET_READ_S3_BUCKET_NAME}/{read_prq_partitioned_path}"""
    LOGGER.info(f"""Parquet Source being used for compactionm: {s3_prq_read_table_folder_path}""")

    if check_s3_folder_path_if_exists(PARQUET_READ_S3_BUCKET_NAME, 
                                      read_prq_partitioned_path):
        df_parquet_read = spark.read.parquet(read_prq_partitioned_path)
    else:
        raise FileNotFoundError(f"""PATH NOT FOUND:>> {read_prq_partitioned_path}""")

    LOGGER.info(f"""df_parquet_read-{s3_prq_read_table_folder_path}:\n> READ PARTITIONS = {df_parquet_read.rdd.getNumPartitions()}""")

    write_to_s3_parquet(df_parquet_read.coalesce(1), 
                        partition_by_cols)
    # -----------------------------------------------

    total_files, total_size = get_s3_folder_info(PARQUET_WRITE_S3_BUCKET_NAME, write_prq_partitioned_path)
    msg_part_1 = f"""total_files={total_files}"""
    msg_part_2 = f"""total_size_mb={total_size/1024/1024:.2f}"""
    LOGGER.info(f"""'{write_prq_partitioned_path}': {msg_part_1}, {msg_part_2}""")


    job.commit()
