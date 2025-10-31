
import sys
# import typing as RT

# from logging import getLogger
# import pandas as pd

from itertools import chain

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
                       "rds_db_host_ep",
                       "rds_db_pwd",
                       "script_bucket_name",
                       "rds_hashed_rows_prq_bucket",
                       "rds_hashed_rows_prq_parent_dir",
                       "dms_prq_output_bucket",
                       "dms_prq_table_folder",
                       "rds_database_folder",
                       "rds_db_schema_folder",
                       "rds_table_orignal_name",
                       "table_pkey_column",
                       "date_partition_column_name",
                       "glue_catalog_db_name",
                       "glue_catalog_tbl_name",
                       "glue_catalog_dv_bucket"
                       ]

OPTIONAL_INPUTS = [
    "rds_only_where_clause",
    "prq_df_where_clause",
    "skip_columns_for_hashing",
    "read_rds_tbl_agg_stats_from_parquet"
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
DMS_PRQ_TABLE_FOLDER = args["dms_prq_table_folder"]
TABLE_PKEY_COLUMN = args['table_pkey_column']
DATE_PARTITION_COLUMN_NAME = args['date_partition_column_name']

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

    if args.get("rds_database_folder", None) is None:
        LOGGER.error(f"""'rds_database_folder' runtime input is missing! Exiting ...""")
        sys.exit(1)
    else:
        rds_database_folder = args["rds_database_folder"]
        LOGGER.info(f"""Given rds_database_folder = {rds_database_folder}""")

    if args.get("rds_db_schema_folder", None) is None:
        LOGGER.error(f"""'rds_db_schema_folder' runtime input is missing! Exiting ...""")
        sys.exit(1)
    else:
        rds_db_schema_folder = args["rds_db_schema_folder"]
        LOGGER.info(f"""Given rds_db_schema_folder = {rds_db_schema_folder}""")
    # -------------------------------------------

    rds_jdbc_conn_obj = RDS_JDBC_CONNECTION(RDS_DB_HOST_ENDPOINT,
                                            RDS_DB_INSTANCE_PWD,
                                            RDS_DATABASE_FOLDER,
                                            RDS_DB_SCHEMA_FOLDER)

    try:
        rds_db_name = rds_jdbc_conn_obj.check_if_rds_db_exists()[0]
    except IndexError:
        LOGGER.error(f"""Given database name not found! >> {rds_database_folder} <<""")
        sys.exit(1)
    except Exception as e:
        sys.exit(e)
    # -------------------------------------------------------

    rds_sqlserver_db_tbl_list = rds_jdbc_conn_obj.get_rds_db_tbl_list()
    if not rds_sqlserver_db_tbl_list:
        LOGGER.error(f"""rds_sqlserver_db_tbl_list - is empty. Exiting ...!""")
        sys.exit(1)
    # -------------------------------------------------------

    if args.get("rds_table_orignal_name", None) is None:
        LOGGER.error(f"""'rds_table_orignal_name' runtime input is missing! Exiting ...""")
        sys.exit(1)
    else:
        rds_table_orignal_name = args["rds_table_orignal_name"]
        table_name_prefix = f"""{rds_db_name}_{rds_db_schema_folder}"""
        db_sch_tbl = f"""{table_name_prefix}_{rds_table_orignal_name}"""
    # -------------------------------------------------------

    LOGGER.info(f""">> Given, rds_table_orignal_name = {rds_table_orignal_name} <<""")
    if db_sch_tbl not in rds_sqlserver_db_tbl_list:
        LOGGER.error(f"""'{db_sch_tbl}' - is not an existing table! Exiting ...""")
        sys.exit(1)
    else:
        LOGGER.info(f"""db_sch_tbl = {db_sch_tbl}""")
    # -------------------------------------------------------

    db_schema_dirpath = f'''{RDS_DATABASE_FOLDER}/{RDS_DB_SCHEMA_FOLDER}'''.strip()
    rds_hashed_rows_bucket_parent_dir = f"""{RDS_HASHED_ROWS_PRQ_BUCKET}/{RDS_HASHED_ROWS_PRQ_PARENT_DIR}"""
    rds_hashed_rows_fulls3path = f"""s3://{rds_hashed_rows_bucket_parent_dir}/{db_schema_dirpath}/{rds_table_orignal_name}"""
    dms_output_fulls3path = f"""s3://{DMS_PRQ_OUTPUT_BUCKET}/{db_schema_dirpath}/{DMS_PRQ_TABLE_FOLDER}"""
    db_sch_tbl = f"""{RDS_DATABASE_FOLDER}_{RDS_DB_SCHEMA_FOLDER}_{rds_table_orignal_name}"""
     
    # -------------------------------------------------------

    if not S3Methods.check_s3_folder_path_if_exists(RDS_HASHED_ROWS_PRQ_BUCKET, 
                                                    f"""{RDS_HASHED_ROWS_PRQ_PARENT_DIR}/{db_schema_dirpath}/{rds_table_orignal_name}"""):
          LOGGER.error(f'''>> {rds_hashed_rows_fulls3path} << Path Not Available !!''')
          sys.exit(1)

    if not S3Methods.check_s3_folder_path_if_exists(DMS_PRQ_OUTPUT_BUCKET, 
                                                    f"""{db_schema_dirpath}/{DMS_PRQ_TABLE_FOLDER}"""):
          LOGGER.error(f'''>> {dms_output_fulls3path} << Path Not Available !!''')
          sys.exit(1)
    # --------------------------------------------------------------------------------------

    LOGGER.info(f""">> rds_hashed_rows_fulls3path = {rds_hashed_rows_fulls3path} <<""")
    LOGGER.info(f""">> dms_output_fulls3path = {dms_output_fulls3path} <<""")


    LOGGER.info(f"""TABLE_PKEY_COLUMN = {TABLE_PKEY_COLUMN}""")
    LOGGER.info(f"""DATE_PARTITION_COLUMN_NAME = {DATE_PARTITION_COLUMN_NAME}""")

    group_by_cols_list = ['year', 'month']
    prq_df_where_clause = args.get("prq_df_where_clause", None)

    # EVALUATE RDS-DATAFRAME ROW-COUNT
    read_rds_tbl_agg_stats_from_parquet = args.get("read_rds_tbl_agg_stats_from_parquet", None)
    hashed_rows_agg_schema = CustomPysparkMethods.get_year_month_min_max_count_schema(TABLE_PKEY_COLUMN)

    if read_rds_tbl_agg_stats_from_parquet == 'true':
        rds_table_row_stats_df_agg = CustomPysparkMethods.get_s3_parquet_df_v2(
                                        f"""s3://{rds_hashed_rows_bucket_parent_dir}/rds_table_row_stats_df_agg""", 
                                        hashed_rows_agg_schema
                                        )
        
        if prq_df_where_clause is not None:
            rds_table_row_stats_df_agg = rds_table_row_stats_df_agg.where(f"{prq_df_where_clause}")
        # -----------------------------------------------------------------------------------------
    else:
        rds_table_row_stats_df_agg = rds_jdbc_conn_obj.get_min_max_count_groupby_yyyy_mm(
                                                        rds_table_orignal_name,
                                                        DATE_PARTITION_COLUMN_NAME,
                                                        TABLE_PKEY_COLUMN,
                                                        args.get("rds_only_where_clause", None))

        for e in hashed_rows_agg_schema:
            rds_table_row_stats_df_agg = rds_table_row_stats_df_agg.withColumn(
                                                                        e.name, F.col(f"{e.name}").cast(e.dataType))

        if S3Methods.check_s3_folder_path_if_exists(RDS_HASHED_ROWS_PRQ_BUCKET, 
                                                    f"{rds_hashed_rows_bucket_parent_dir}/rds_table_row_stats_df_agg"):
             
             prq_rds_table_row_stats_df_agg = CustomPysparkMethods.get_s3_parquet_df_v2(
                                                f"""s3://{rds_hashed_rows_bucket_parent_dir}/rds_table_row_stats_df_agg""", 
                                                rds_table_row_stats_df_agg.schema
                                                )
             
             prq_rds_table_row_stats_df_agg_updated = CustomPysparkMethods.update_df1_with_df2(
                                                            prq_rds_table_row_stats_df_agg,
                                                            rds_table_row_stats_df_agg,
                                                            [e.name 
                                                                for e in rds_table_row_stats_df_agg.schema.fields
                                                                    if e.name not in group_by_cols_list
                                                            ],
                                                            group_by_cols_list
                                                        )
            
             prq_rds_table_row_stats_df_agg_updated.write\
                                                   .mode("overwrite")\
                                                   .option("overwriteSchema", "True")\
                                                   .parquet(
                                                    f"""s3://{rds_hashed_rows_bucket_parent_dir}/rds_table_row_stats_df_agg""")
        else:
            rds_table_row_stats_df_agg.write.mode("overwrite").parquet(
                                                    f"""s3://{rds_hashed_rows_bucket_parent_dir}/rds_table_row_stats_df_agg""")
        # --------------------------------------------------------------------
    # --------------------------------------------------------------------
    # +----+-----+-----------------+-----------------+-------------------+
    # |year|month|min_GPSPositionID|max_GPSPositionID|count_GPSPositionID|
    # +----+-----+-----------------+-----------------+-------------------+
    # |1970|1    |41198832         |5785155214       |22972              |
    # |1970|2    |299219990        |5744796584       |54                 |
    # |1970|3    |150852111        |5745141548       |35                 |
    # |1970|4    |603316403        |5328915343       |120                |
    # |1970|5    |652691585        |5317361051       |24                 |
    # |1970|6    |149506526        |5745353009       |111                |
    # |1970|7    |534917358        |5745353143       |65                 |
    # |1970|8    |530552359        |5574165709       |6                  |
    # |1970|9    |396540172        |5287871190       |10                 |
    # |1970|10   |295664992        |5328914939       |7                  |
    # |1970|11   |659003457        |4658994221       |5                  |
    # |1970|12   |1130650220       |5330506101       |9                  |
    # --------------------------------------------------------------------------------------

    rds_db_table_empty_df = rds_jdbc_conn_obj.get_rds_db_table_empty_df(rds_table_orignal_name)

    skip_columns_for_hashing_str = args.get("skip_columns_for_hashing", None)

    skip_columns_for_hashing = list()
    skipped_struct_fields_list = list()
    skipped_cols_condition_list = list()
    skipped_cols_alias = list()
    if skip_columns_for_hashing_str is not None:
        skip_columns_for_hashing = [f"""{col_name.strip().strip("'").strip('"')}"""
                                    for col_name in skip_columns_for_hashing_str.split(",")]
        LOGGER.warn(f"""WARNING ! >> Given skip_columns_for_hashing = {skip_columns_for_hashing}""")

        for sf in rds_db_table_empty_df.schema:
            if sf.name in skip_columns_for_hashing:
                skipped_struct_fields_list.append(sf)

        LOGGER.warn(f"""WARNING ! >> skipped_struct_fields_list = {skipped_struct_fields_list}""")
        skipped_cols_condition_list = [f"(L.{col} != R.{col})" 
                                       for col in skip_columns_for_hashing]
        skipped_cols_alias = list(
                                chain.from_iterable((f'L.{col} as rds_{col}', f'R.{col} as dms_{col}')
                                for col in skip_columns_for_hashing)
                                )


    if skipped_struct_fields_list:
        rds_hashed_rows_prq_df = CustomPysparkMethods.get_s3_parquet_df_v2(
                                    rds_hashed_rows_fulls3path, 
                                    CustomPysparkMethods.get_pyspark_hashed_table_schema(
                                                            TABLE_PKEY_COLUMN, 
                                                            skipped_struct_fields_list)
                                    )
    else:
        rds_hashed_rows_prq_df = CustomPysparkMethods.get_s3_parquet_df_v2(
                                    rds_hashed_rows_fulls3path, 
                                    CustomPysparkMethods.get_pyspark_hashed_table_schema(
                                                            TABLE_PKEY_COLUMN)
                                    )
    
    if prq_df_where_clause is not None:
        rds_hashed_rows_prq_df = rds_hashed_rows_prq_df.where(f"{prq_df_where_clause}")

    rds_hashed_rows_prq_df_agg = rds_hashed_rows_prq_df.groupby(group_by_cols_list)\
                                    .agg(
                                        F.min(TABLE_PKEY_COLUMN).alias(f"min_{TABLE_PKEY_COLUMN}"),
                                        F.max(TABLE_PKEY_COLUMN).alias(f"max_{TABLE_PKEY_COLUMN}"),
                                        F.count(TABLE_PKEY_COLUMN).alias(f"count_{TABLE_PKEY_COLUMN}")
                                        )\
                                    .orderBy(group_by_cols_list, ascending=True)
    # +----+-----+-----------------+-----------------+-------------------+
    # |year|month|min_GPSPositionID|max_GPSPositionID|count_GPSPositionID|
    # +----+-----+-----------------+-----------------+-------------------+
    # |1970|1    |41198832         |5785155214       |22972              |
    # |1970|2    |299219990        |5744796584       |54                 |
    # |1970|3    |150852111        |5745141548       |35                 |
    # |1970|4    |603316403        |5328915343       |120                |
    # |1970|5    |652691585        |5317361051       |24                 |
    # |1970|6    |149506526        |5745353009       |111                |
    # |1970|7    |534917358        |5745353143       |65                 |
    # |1970|8    |530552359        |5574165709       |6                  |
    # |1970|9    |396540172        |5287871190       |10                 |
    # |1970|10   |295664992        |5328914939       |7                  |
    # |1970|11   |659003457        |4658994221       |5                  |
    # |1970|12   |1130650220       |5330506101       |9                  |
    # --------------------------------------------------------------------------------------

    migrated_prq_yyyy_mm_df = CustomPysparkMethods.get_s3_parquet_df_v3(
                                                    dms_output_fulls3path, 
                                                    rds_db_table_empty_df.schema)

    if prq_df_where_clause is not None:
        migrated_prq_yyyy_mm_df = migrated_prq_yyyy_mm_df.where(f"{prq_df_where_clause}")

    migrated_prq_yyyy_mm_df_agg = migrated_prq_yyyy_mm_df.groupby(group_by_cols_list)\
                                    .agg(
                                        F.min(TABLE_PKEY_COLUMN).alias(f"min_{TABLE_PKEY_COLUMN}"),
                                        F.max(TABLE_PKEY_COLUMN).alias(f"max_{TABLE_PKEY_COLUMN}"),
                                        F.count(TABLE_PKEY_COLUMN).alias(f"count_{TABLE_PKEY_COLUMN}")
                                        )\
                                    .orderBy(group_by_cols_list, ascending=True)
    # +----+-----+-----------------+-----------------+-------------------+
    # |year|month|min_GPSPositionID|max_GPSPositionID|count_GPSPositionID|
    # +----+-----+-----------------+-----------------+-------------------+
    # |1970|1    |41198832         |5785155214       |22972              |
    # |1970|2    |299219990        |5744796584       |54                 |
    # |1970|3    |150852111        |5745141548       |35                 |
    # |1970|4    |603316403        |5328915343       |120                |
    # |1970|5    |652691585        |5317361051       |24                 |
    # |1970|6    |149506526        |5745353009       |111                |
    # |1970|7    |534917358        |5745353143       |65                 |
    # |1970|8    |530552359        |5574165709       |6                  |
    # |1970|9    |396540172        |5287871190       |10                 |
    # |1970|10   |295664992        |5328914939       |7                  |
    # |1970|11   |659003457        |4658994221       |5                  |
    # |1970|12   |1130650220       |5330506101       |9                  |
    # --------------------------------------------------------------------------------------

    rds_subtract_rds_hashed_rows_df = rds_table_row_stats_df_agg.subtract(rds_hashed_rows_prq_df_agg)
    rds_subtract_rds_hashed_rows_count = rds_subtract_rds_hashed_rows_df.count()
    if rds_subtract_rds_hashed_rows_count != 0:
        LOGGER.error(f'''>> rds_subtract_rds_hashed_rows_count = {rds_subtract_rds_hashed_rows_count} <<''')
        # rds_subtract_rds_hashed_rows_pd = rds_subtract_rds_hashed_rows_df.toPandas()
        # rds_subtract_rds_hashed_rows_dict = rds_subtract_rds_hashed_rows_pd.to_dict(orient='list')
        LOGGER.error(f'''\n{rds_subtract_rds_hashed_rows_df.limit(10).toPandas()}\n''')
        sys.exit(1)
    # --------------------------------------------------------------------------------------

    rds_hashed_rows_subtract_dms_prq_df = rds_hashed_rows_prq_df_agg.subtract(migrated_prq_yyyy_mm_df_agg)
    rds_hashed_rows_subtract_dms_prq_count = rds_hashed_rows_subtract_dms_prq_df.count()
    if rds_hashed_rows_subtract_dms_prq_count != 0:
        LOGGER.error(f'''>> rds_hashed_rows_subtract_dms_prq_count = {rds_hashed_rows_subtract_dms_prq_count} <<''')
        # rds_hashed_rows_subtract_dms_prq_pd = rds_hashed_rows_subtract_dms_prq_df.toPandas()
        # rds_hashed_rows_subtract_dms_prq_dict = rds_hashed_rows_subtract_dms_prq_pd.to_dict(orient='list')
        LOGGER.error(f'''\n{rds_hashed_rows_subtract_dms_prq_df.limit(10).toPandas()}\n''')
        sys.exit(1)
    # --------------------------------------------------------------------------------------

    LOGGER.info(f""">> Aggregate stats matched between RDS-Original-Table and RDS-Hashed-Output and DMS-Parquet-Output <<""")


    all_columns_except_pkey = [col for col in rds_db_table_empty_df.columns 
                               if col != TABLE_PKEY_COLUMN and (col not in skip_columns_for_hashing)]
    LOGGER.info(f""">> all_columns_except_pkey = {all_columns_except_pkey} <<""")

    if skip_columns_for_hashing:
        dms_hashed_rows_prq_df_t1 = migrated_prq_yyyy_mm_df.withColumn(
                                        "RowHash", F.sha2(F.concat_ws("", *all_columns_except_pkey), 256))\
                                        .select('year', 'month', TABLE_PKEY_COLUMN, 
                                                *skip_columns_for_hashing,
                                                'RowHash')
    else:    
        dms_hashed_rows_prq_df_t1 = migrated_prq_yyyy_mm_df.withColumn(
                                        "RowHash", F.sha2(F.concat_ws("", *all_columns_except_pkey), 256))\
                                        .select('year', 'month', f'{TABLE_PKEY_COLUMN}', 'RowHash')
    
    
    unmatched_condition_str = """(L.RowHash != R.RowHash) or (R.RowHash is null)"""

    if skipped_cols_condition_list:
        unmatched_condition_str = unmatched_condition_str + ' or ' + \
                                    ' or '.join(skipped_cols_condition_list)
    
    LOGGER.info(f""">> unmatched_condition_str = {unmatched_condition_str} <<""")

    unmatched_hashvalues_df = rds_hashed_rows_prq_df.alias('L').join(
                                                        dms_hashed_rows_prq_df_t1.alias('R'), 
                                                        on=['year', 'month', f'{TABLE_PKEY_COLUMN}'],
                                                        how='left')\
                                                    .where(unmatched_condition_str).cache()
    
    unmatched_hashvalues_df_count = unmatched_hashvalues_df.count()

    df_dv_output = CustomPysparkMethods.declare_empty_df_dv_output_v1()

    if unmatched_hashvalues_df_count != 0:
        LOGGER.warn(f"""unmatched_hashvalues_df_count> {unmatched_hashvalues_df_count}: Row differences found!""")
        
        if skipped_cols_alias:
            unmatched_hashvalues_df_select = unmatched_hashvalues_df.selectExpr(
                                        f"L.{TABLE_PKEY_COLUMN} as {TABLE_PKEY_COLUMN}", 
                                        *skipped_cols_alias,
                                        "L.RowHash as rds_row_hash", 
                                        "R.RowHash as dms_output_row_hash",
                                        "L.year as year", "L.month as month"
                                    ).limit(10)
        else:
            unmatched_hashvalues_df_select = unmatched_hashvalues_df.selectExpr(
                                                f"L.{TABLE_PKEY_COLUMN} as {TABLE_PKEY_COLUMN}", 
                                                "L.RowHash as rds_row_hash", 
                                                "R.RowHash as dms_output_row_hash"
                                            ).limit(10)

        df_subtract_temp = (unmatched_hashvalues_df_select
                                .withColumn('json_row', 
                                            F.to_json(F.struct(*[F.col(c) 
                                                                 for c in unmatched_hashvalues_df_select.columns])))
                                .selectExpr("json_row")
                            )

        subtract_validation_msg = f"""'{DMS_PRQ_TABLE_FOLDER}' - {unmatched_hashvalues_df_count}"""
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
                                f"""'{rds_table_orignal_name} - Validated.' as validation_msg""",
                                f"""'{RDS_DATABASE_FOLDER}' as database_name""",
                                f"""'{db_sch_tbl}' as full_table_name""",
                                """'False' as table_to_ap"""
                    )
        LOGGER.info(f"Validation Successful - 1")
        df_dv_output = df_dv_output.union(df_temp)

    write_parquet_to_s3(df_dv_output, RDS_DATABASE_FOLDER, db_sch_tbl)

    unmatched_hashvalues_df.unpersist()

    job.commit()
