
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
                       "rds_to_parquet_output_s3_bucket",
                       "validation_only_run",
                       "validation_sample_fraction_float",
                       "validation_sample_df_repartition_num",
                       "glue_catalog_db_name",
                       "glue_catalog_tbl_name",
                       "glue_catalog_dv_bucket"
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

GLUE_CATALOG_DB_NAME = args["glue_catalog_db_name"]
GLUE_CATALOG_TBL_NAME = args["glue_catalog_tbl_name"]
GLUE_CATALOG_DV_BUCKET = args["glue_catalog_dv_bucket"]

CATALOG_DB_TABLE_PATH = f"""{GLUE_CATALOG_DB_NAME}/{GLUE_CATALOG_TBL_NAME}"""
CATALOG_TABLE_S3_FULL_PATH = f'''s3://{GLUE_CATALOG_DV_BUCKET}/{CATALOG_DB_TABLE_PATH}'''


NVL_DTYPE_DICT = Logical_Constants.NVL_DTYPE_DICT

INT_DATATYPES_LIST = Logical_Constants.INT_DATATYPES_LIST

RECORDED_PKEYS_LIST = Logical_Constants.RECORDED_PKEYS_LIST

QUERY_STR_DICT = SQLServer_Extract_Transform.QUERY_STR_DICT

# ==================================================================
# USER-DEFINED-FUNCTIONS
# ----------------------

def print_existing_s3parquet_stats(prq_table_folder_path):
    total_files, total_size = S3Methods.get_s3_folder_info(
                                PARQUET_OUTPUT_S3_BUCKET_NAME,
                                prq_table_folder_path)
    
    msg_part_1 = f"""> total_files={total_files}"""
    msg_part_2 = f"""> total_size_mb={total_size/1024/1024:.2f}"""
    LOGGER.info(f"""{msg_part_1}, {msg_part_2}""")


def compare_rds_parquet_samples(rds_jdbc_conn_obj,
                                rds_db_table_name,
                                df_rds_query_read: DataFrame,
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

    df_parquet_read = spark.read.schema(df_rds_query_read.schema).parquet(s3_table_folder_path)

    df_parquet_read_sample = df_parquet_read.sample(validation_sample_fraction_float)

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

    df_rds_read_sample = df_rds_query_read.join(df_parquet_read_sample,
                                          on=jdbc_partition_column,
                                          how='leftsemi')

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
        temp_msg = f"""{validation_sample_fraction_float} - Sample Rows Validated."""
        df_temp_row = spark.sql(f"""select 
                                    current_timestamp() as run_datetime, 
                                    '' as json_row,
                                    "{temp_msg}" as validation_msg,
                                    '{rds_jdbc_conn_obj.rds_db_name}' as database_name,
                                    '{db_sch_tbl}' as full_table_name,
                                    'False' as table_to_ap
                                """.strip())

        LOGGER.info(f"{rds_db_table_name}: Validation Successful - 1")
        df_dv_output = df_dv_output.union(df_temp_row)
    else:

        LOGGER.warn(
            f"""Parquet-RDS Subtract Report: ({df_prq_read_filtered_count}): Row(s) differences found!""")

        df_subtract_temp = (df_prq_leftanti_rds
                            .withColumn('json_row', F.to_json(F.struct(*[F.col(c)
                                                                         for c in df_rds_query_read.columns])))
                            .selectExpr("json_row")
                            .limit(100))

        temp_msg = f"""{validation_sample_fraction_float}-Rows Sample Used:\n"""
        df_subtract_temp = df_subtract_temp.selectExpr(
            "current_timestamp as run_datetime",
            "json_row",
            f""""{temp_msg}>{df_prq_read_filtered_count} Rows - Validation Failed !" as validation_msg""",
            f"""'{rds_jdbc_conn_obj.rds_db_name}' as database_name""",
            f"""'{db_sch_tbl}' as full_table_name""",
            """'False' as table_to_ap"""
        )
        LOGGER.warn(f"{rds_db_table_name}: Validation Failed - 2")
        df_dv_output = df_dv_output.union(df_subtract_temp)
    # -----------------------------------------------------

    return df_dv_output


def write_rds_to_s3parquet(df_rds_query_read: DataFrame, prq_table_folder_path):

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


def write_dv_report_to_s3parquet(df_dv_output: DataFrame, 
                                 rds_jdbc_conn_obj, 
                                 db_sch_tbl_name):

    db_name = rds_jdbc_conn_obj.rds_db_name
    df_dv_output = df_dv_output.repartition(1)

    prq_table_folder_path = f"""{args["glue_catalog_db_name"]}/{args["glue_catalog_tbl_name"]}"""
    s3_table_folder_path = f'''s3://{GLUE_CATALOG_DV_BUCKET}/{prq_table_folder_path}'''

    if S3Methods.check_s3_folder_path_if_exists(GLUE_CATALOG_DV_BUCKET,
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

    jdbc_read_partitions_num = 1 if jdbc_read_partitions_num <= 0 \
                                    else jdbc_read_partitions_num
    LOGGER.info(f"""jdbc_read_partitions_num = {jdbc_read_partitions_num}""")

    agg_row_dict = rds_jdbc_conn_obj.get_min_max_pkey_filter(
                                        rds_sqlserver_db_table,
                                        rds_db_tbl_pkey_column
                                    )
    min_pkey = agg_row_dict['min_value']
    LOGGER.info(f"""min_pkey = {min_pkey}""")

    max_pkey = agg_row_dict['max_value']
    LOGGER.info(f"""max_pkey = {max_pkey}""")

    rds_transformed_query = QUERY_STR_DICT[f"{db_sch_tbl}"]
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
    LOGGER.info(f"""df_rds_query_read_columns = {df_rds_query_read_columns}""")

    df_rds_query_read_schema = df_rds_query_read.schema
    LOGGER.info(f"""df_rds_query_read_schema = \n{[obj for obj in df_rds_query_read_schema]}""")

    rds_df_repartition_num = int(args['rds_df_repartition_num'])

    if rds_df_repartition_num != 0:
        df_rds_query_read = df_rds_query_read.repartition(rds_df_repartition_num, 
                                                          rds_db_tbl_pkey_column)
        int_repartitions = df_rds_query_read.rdd.getNumPartitions()
        LOGGER.info(
            f"""df_rds_query_read: After Repartitioning -> {int_repartitions} partitions.""")
    # ----------------------------------------------------

    rename_output_table_folder = args.get('rename_migrated_prq_tbl_folder', None)
    prq_table_folder_name = rds_sqlserver_db_table if rename_output_table_folder is None \
                                                    else rename_output_table_folder
    # ---------------------------------------

    prq_table_folder_path = f"""{rds_db_name}/{rds_sqlserver_db_schema}/{prq_table_folder_name}"""
    LOGGER.info(f"""prq_table_folder_path = {prq_table_folder_path}""")

    validation_only_run = args['validation_only_run']

    validation_sample_fraction_float = float(args.get('validation_sample_fraction_float', 0))
    validation_sample_fraction_float = 1.0 if validation_sample_fraction_float > 1 \
                                            else validation_sample_fraction_float

    temp_msg = f"""validation_sample_fraction_float = {validation_sample_fraction_float}"""
    if validation_only_run != "true":
        if validation_sample_fraction_float != 0:
            df_rds_query_read = df_rds_query_read.cache()
            write_rds_to_s3parquet(df_rds_query_read, prq_table_folder_path)
            print_existing_s3parquet_stats(prq_table_folder_path)
            LOGGER.info(f"""> Starting validation: {temp_msg}""")
            df_dv_output = compare_rds_parquet_samples(rds_jdbc_conn_obj,
                                                       rds_sqlserver_db_table,
                                                       df_rds_query_read,
                                                       rds_db_tbl_pkey_column,
                                                       prq_table_folder_path,
                                                       validation_sample_fraction_float
                                                       )
            write_dv_report_to_s3parquet(df_dv_output, rds_jdbc_conn_obj, db_sch_tbl)
            df_rds_query_read.unpersist()
        else:
            write_rds_to_s3parquet(df_rds_query_read, prq_table_folder_path)
            print_existing_s3parquet_stats(prq_table_folder_path)
            LOGGER.warn(f"""{temp_msg}\nValidation not enabled. Skipping ...""")

    else:
        LOGGER.warn(f""">> validation_only_run - ENABLED <<""")
        print_existing_s3parquet_stats(prq_table_folder_path)
        
        if validation_sample_fraction_float != 0:
            LOGGER.info(f"""> Starting validation: {temp_msg}""")
            df_dv_output = compare_rds_parquet_samples(rds_jdbc_conn_obj,
                                                       rds_sqlserver_db_table,
                                                       df_rds_query_read,
                                                       rds_db_tbl_pkey_column,
                                                       prq_table_folder_path,
                                                       validation_sample_fraction_float
                                                       )
            write_dv_report_to_s3parquet(df_dv_output, rds_jdbc_conn_obj, db_sch_tbl)
        else:
            LOGGER.warn(f"""{temp_msg} => Skipping Validation !""")
    # ---------------------------------------------------------------
    
    job.commit()
