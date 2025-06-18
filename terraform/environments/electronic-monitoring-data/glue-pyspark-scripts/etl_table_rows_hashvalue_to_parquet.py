
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
sc._jsc.hadoopConfiguration().set("spark.memory.offHeap.enabled", "true")
sc._jsc.hadoopConfiguration().set("spark.memory.offHeap.size", "3g")
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
                       "hashed_output_s3_bucket_name",
                       "parquet_df_write_repartition_num",
                       "parallel_jdbc_conn_num",
                       "rds_sqlserver_db",
                       "rds_sqlserver_db_schema",
                       "rds_sqlserver_db_table",
                       "rds_db_tbl_pkey_column",
                       "rds_db_table_hashed_rows_parent_dir"
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

HASHED_OUTPUT_S3_BUCKET_NAME = args["hashed_output_s3_bucket_name"]
RDS_DB_TABLE_HASHED_ROWS_PARENT_DIR = args["rds_db_table_hashed_rows_parent_dir"]

INT_DATATYPES_LIST = Logical_Constants.INT_DATATYPES_LIST

RECORDED_PKEYS_LIST = Logical_Constants.RECORDED_PKEYS_LIST

# ===============================================================================

def write_parquet_to_s3(hashed_rows_prq_df_write: DataFrame, hashed_rows_prq_fulls3path):

    dydf = DynamicFrame.fromDF(hashed_rows_prq_df_write, glueContext, "final_spark_df")

    glueContext.write_dynamic_frame.from_options(frame=dydf, connection_type='s3', format='parquet',
                                                 connection_options={
                                                     'path': f"""{hashed_rows_prq_fulls3path}/"""
                                                 },
                                                 format_options={
                                                     'useGlueParquetWriter': True,
                                                     'compression': 'snappy',
                                                     'blockSize': 13421773,
                                                     'pageSize': 1048576
                                                 })
    LOGGER.info(f"""hashed_rows_prq_df_write - dataframe written to -> {hashed_rows_prq_fulls3path}/""")

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
    # -------------------------------------------------------
    
    if db_sch_tbl not in rds_sqlserver_db_tbl_list:
        LOGGER.error(f"""'{db_sch_tbl}' - is not an existing table! Exiting ...""")
        sys.exit(1)
    else:
        LOGGER.info(f""">> Given RDS SqlServer-DB Table: {rds_sqlserver_db_table} <<""")
    # -------------------------------------------------------

    rds_db_tbl_pkey_column = args['rds_db_tbl_pkey_column']
    LOGGER.info(f""">> rds_db_tbl_pkey_column = {rds_db_tbl_pkey_column} <<""")

    rds_db_table_empty_df = rds_jdbc_conn_obj.get_rds_db_table_empty_df(rds_sqlserver_db_table)

    # skip_columns = [f'{rds_db_tbl_pkey_column}', 'SmallDateTimeCol', 'DateTime2Col']
    all_columns_except_pkey = list()

    for e in rds_db_table_empty_df.schema.fields:
        if e.name == rds_db_tbl_pkey_column:
            continue
        
        if e.dataType.simpleString() == 'timestamp':
            all_columns_except_pkey.append(f"CONVERT(VARCHAR, {e.name}, 120)") # YYYY-MM-DD HH:MM:SS
        else:
            all_columns_except_pkey.append(f"{e.name}")

    LOGGER.info(f""">> all_columns_except_pkey = {all_columns_except_pkey} <<""")
    # -------------------------------------------------------

    prq_bucket_parent_folder = f"""{HASHED_OUTPUT_S3_BUCKET_NAME}/{RDS_DB_TABLE_HASHED_ROWS_PARENT_DIR}"""
    prq_table_folder_path = f"""{rds_db_name}/{rds_sqlserver_db_schema}/{rds_sqlserver_db_table}"""
    
    if S3Methods.check_s3_folder_path_if_exists(
                    HASHED_OUTPUT_S3_BUCKET_NAME,
                    f'''{RDS_DB_TABLE_HASHED_ROWS_PARENT_DIR}/{prq_table_folder_path}'''
        ):
        hashed_rows_prq_fulls3path = f'''s3://{prq_bucket_parent_folder}/{prq_table_folder_path}'''
    else:
        hashed_rows_prq_fulls3path = ""
    # --------------------------------

    rds_db_select_query_str = f"""
    SELECT {rds_db_tbl_pkey_column}, 
    LOWER(SUBSTRING(CONVERT(VARCHAR(66), 
    HASHBYTES('SHA2_256', CONCAT_WS('', {', '.join(all_columns_except_pkey)})), 1), 3, 66)) AS RowHash
    FROM {rds_sqlserver_db_schema}.[{rds_sqlserver_db_table}]
    """.strip()

    parallel_jdbc_conn_num = int(args['parallel_jdbc_conn_num'])
    parquet_df_write_repartition_num = int(args.get('parquet_df_write_repartition_num', 0))


    if hashed_rows_prq_fulls3path != "":
        LOGGER.info(f"""An existing parquet-table-folder-path found.\n{hashed_rows_prq_fulls3path}""")

        rds_db_query_sample_row_str = rds_db_select_query_str.replace(
                                    f"SELECT {rds_db_tbl_pkey_column}", 
                                    f"SELECT TOP 1 {rds_db_tbl_pkey_column}")
    
        rds_db_query_sample_row_df = rds_jdbc_conn_obj.get_rds_db_query_df(
                                                        rds_db_query_sample_row_str)
        LOGGER.info(f"""rds_db_query_sample_row_df-schema: \n{rds_db_query_sample_row_df.columns}""")

        existing_parquet_table_df = CustomPysparkMethods.get_s3_parquet_df_v2(
                                                            hashed_rows_prq_fulls3path, 
                                                            rds_db_query_sample_row_df.schema
                                    )
        
        existing_parquet_table_df_agg = existing_parquet_table_df.agg(
                                            F.min(rds_db_tbl_pkey_column).alias(f"min_{rds_db_tbl_pkey_column}"),
                                            F.max(rds_db_tbl_pkey_column).alias(f"max_{rds_db_tbl_pkey_column}"),
                                            F.count(rds_db_tbl_pkey_column).alias(f"count_{rds_db_tbl_pkey_column}")
                                        )
        existing_parquet_agg_dict = existing_parquet_table_df_agg.collect()[0]
        existing_parquet_min_pkey = existing_parquet_agg_dict[f"min_{rds_db_tbl_pkey_column}"]
        existing_parquet_max_pkey = existing_parquet_agg_dict[f"max_{rds_db_tbl_pkey_column}"]
        existing_parquet_count_pkey = existing_parquet_agg_dict[f"count_{rds_db_tbl_pkey_column}"]

        LOGGER.info(f"""existing_parquet_min_pkey = {existing_parquet_min_pkey}""")
        LOGGER.info(f"""existing_parquet_max_pkey = {existing_parquet_max_pkey}""")
        LOGGER.info(f"""existing_parquet_count_pkey = {existing_parquet_count_pkey}""")

        # df_rds_table_count = rds_jdbc_conn_obj.get_rds_db_table_row_count(
        #                                         rds_sqlserver_db_table, 
        #                                         rds_db_tbl_pkey_column
        #                         )
        rds_jdbc_min_max_count_df_agg = rds_jdbc_conn_obj.get_rds_df_query_min_max_count(
                                            rds_sqlserver_db_table, 
                                            rds_db_tbl_pkey_column
                                        )

        rds_jdbc_agg_dict = rds_jdbc_min_max_count_df_agg.collect()[0]
        rds_jdbc_min_pkey = rds_jdbc_agg_dict[f"min_value"]
        rds_jdbc_max_pkey = rds_jdbc_agg_dict[f"max_value"]
        rds_jdbc_count_pkey = rds_jdbc_agg_dict[f"count_value"]

        LOGGER.info(f"""rds_jdbc_min_pkey = {rds_jdbc_min_pkey}""")
        LOGGER.info(f"""rds_jdbc_max_pkey = {rds_jdbc_max_pkey}""")
        LOGGER.info(f"""rds_jdbc_count_pkey = {rds_jdbc_count_pkey}""")

        if rds_jdbc_count_pkey == existing_parquet_count_pkey:
            LOGGER.warn(f"""rds_jdbc_count_pkey = existing_parquet_table_df_count = {rds_jdbc_count_pkey}""")
            sys.exit(f"""Both rds_jdbc_count_pkey and existing_parquet_table_df_count are matching. Nothing to move, exiting ...""")
        elif existing_parquet_count_pkey > rds_jdbc_count_pkey:
            LOGGER.warn(f"""existing_parquet_table_df_count > df_rds_table_count""")
            sys.exit(f"""This scenario cannot be possible & needs further investigation, exiting ...""")
        elif existing_parquet_min_pkey != rds_jdbc_min_pkey:
            LOGGER.warn(f"""existing_parquet_min_pkey != rds_jdbc_min_pkey""")
            sys.exit(f"""This scenario cannot be possible & needs further investigation, exiting ...""")      
        # --------------------

        where_clause_exp_str = f"""{rds_db_tbl_pkey_column} > {existing_parquet_max_pkey}""".strip()

        agg_row_dict = rds_jdbc_conn_obj.get_min_max_pkey_filter(
                                            rds_sqlserver_db_table,
                                            rds_db_tbl_pkey_column,
                                            where_clause_exp_str
                                        )
        jdbc_partition_col_lowerbound = agg_row_dict['min_value']
        jdbc_partition_col_upperbound = agg_row_dict['max_value']

        LOGGER.info(f"""jdbc_partition_col_lowerbound = {jdbc_partition_col_lowerbound}""")
        LOGGER.info(f"""jdbc_partition_col_upperbound = {jdbc_partition_col_upperbound}""")

        rds_db_query_filtered_str = rds_db_select_query_str + f""" WHERE {where_clause_exp_str}"""
        LOGGER.info(f"""rds_db_query_filtered_str > \n{rds_db_query_filtered_str}""")

        hashed_rows_prq_df = rds_jdbc_conn_obj.get_rds_df_read_query_pkey_parallel(
                                                        rds_db_query_filtered_str,
                                                        rds_db_tbl_pkey_column,
                                                        jdbc_partition_col_lowerbound,
                                                        jdbc_partition_col_upperbound,
                                                        parallel_jdbc_conn_num
                                )
        LOGGER.info(
        f"""hashed_rows_prq_df: JDBC-READ-PARTITIONS = {hashed_rows_prq_df.rdd.getNumPartitions()}""")
    else:

        agg_row_dict = rds_jdbc_conn_obj.get_min_max_pkey_filter(
                                            rds_sqlserver_db_table,
                                            rds_db_tbl_pkey_column
                                        )
        jdbc_partition_col_lowerbound = agg_row_dict['min_value']
        jdbc_partition_col_upperbound = agg_row_dict['max_value']

        LOGGER.info(f"""jdbc_partition_col_lowerbound = {jdbc_partition_col_lowerbound}""")
        LOGGER.info(f"""jdbc_partition_col_upperbound = {jdbc_partition_col_upperbound}""")

        LOGGER.info(f"""rds_db_select_query_str > \n{rds_db_select_query_str}""")

        hashed_rows_prq_df = rds_jdbc_conn_obj.get_rds_df_read_query_pkey_parallel(
                                                        rds_db_select_query_str,
                                                        rds_db_tbl_pkey_column,
                                                        jdbc_partition_col_lowerbound,
                                                        jdbc_partition_col_upperbound,
                                                        parallel_jdbc_conn_num
                            )
        LOGGER.info(
        f"""hashed_rows_prq_df: JDBC-READ-PARTITIONS = {hashed_rows_prq_df.rdd.getNumPartitions()}""")
    # ---------------------------------------

    if parquet_df_write_repartition_num != 0:
        hashed_rows_prq_df = hashed_rows_prq_df.repartition(
                                                        parquet_df_write_repartition_num, 
                                                        rds_db_tbl_pkey_column)
        LOGGER.info(
            f"""hashed_rows_prq_df: Repartitioned -> {hashed_rows_prq_df.rdd.getNumPartitions()} partitions.""")
    
    hashed_rows_prq_df_sorted = hashed_rows_prq_df.sortWithinPartitions(f"{rds_db_tbl_pkey_column}")
    LOGGER.info(f"""hashed_rows_prq_df - sorted within partitions on '{rds_db_tbl_pkey_column}'.""")

    write_parquet_to_s3(hashed_rows_prq_df_sorted, 
                        f'''s3://{prq_bucket_parent_folder}/{prq_table_folder_path}''')
    # --------------------------------

    job.commit()
