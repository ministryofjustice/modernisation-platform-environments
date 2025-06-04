import sys
import boto3
from logging import getLogger

from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from awsglue.context import GlueContext
from awsglue.dynamicframe import DynamicFrame
from awsglue.job import Job

import pyspark.sql.functions as F
from pyspark.sql.types import StructField, StructType, TimestampType, StringType
from pyspark.sql import DataFrame

# ===============================================================================

sc = SparkContext.getOrCreate()
glueContext = GlueContext(sc)
spark = glueContext.spark_session

LOGGER = glueContext.get_logger()

# ===============================================================================


def resolve_args(args_list):
    LOGGER.info(f">> Resolving Argument Variables: START")
    available_args_list = []
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
                       "rds_db_host_ep",
                       "rds_db_pwd",
                       "csv_src_bucket_name",
                       "parquet_output_bucket_name",
                       "glue_catalog_db_name",
                       "glue_catalog_tbl_name",
                       "rds_sqlserver_dbs",
                       "repartition_factor",
                       "max_table_size_mb",
                       "trim_rds_df_str_columns"
                       ]

OPTIONAL_INPUTS = [
    "rds_sqlserver_tbls"
]

AVAILABLE_ARGS_LIST = resolve_args(DEFAULT_INPUTS_LIST+OPTIONAL_INPUTS)

args = getResolvedOptions(sys.argv, AVAILABLE_ARGS_LIST)

# ------------------------------

job = Job(glueContext)
job.init(args["JOB_NAME"], args)

# ------------------------------

S3_CLIENT = boto3.client("s3")

# ------------------------------

RDS_DB_HOST_ENDPOINT = args["rds_db_host_ep"]
RDS_DB_PORT = 1433
RDS_DB_INSTANCE_USER = "admin"
RDS_DB_INSTANCE_PWD = args["rds_db_pwd"]
RDS_DB_INSTANCE_DRIVER = "com.microsoft.sqlserver.jdbc.SQLServerDriver"

CSV_FILE_SRC_S3_BUCKET_NAME = args["csv_src_bucket_name"]

PARQUET_OUTPUT_S3_BUCKET_NAME = args["parquet_output_bucket_name"]

GLUE_CATALOG_DB_NAME = args["glue_catalog_db_name"]
GLUE_CATALOG_TBL_NAME = args["glue_catalog_tbl_name"]

CATALOG_TABLE_S3_FULL_PATH = f'''s3://{PARQUET_OUTPUT_S3_BUCKET_NAME}/{GLUE_CATALOG_DB_NAME}/{GLUE_CATALOG_TBL_NAME}'''

NVL_DTYPE_DICT = {'string':"''", 'int':0, 'double':0, 'float':0, 'smallint':0, 
                  'boolean':False,
                  'timestamp':"to_timestamp('1900-01-01', 'yyyy-MM-dd')"}

# ===============================================================================
# USER-DEFINED-FUNCTIONS
# ----------------------


def get_rds_db_jdbc_url(in_rds_db_name=None):
    if in_rds_db_name is None:
        return f"""jdbc:sqlserver://{RDS_DB_HOST_ENDPOINT}:{RDS_DB_PORT};"""
    else:
        return f"""jdbc:sqlserver://{RDS_DB_HOST_ENDPOINT}:{RDS_DB_PORT};database={in_rds_db_name}"""


def get_rds_database_list(in_rds_databases):

    if in_rds_databases is None:
        sql_sys_databases_1 = f"""
        SELECT name FROM sys.databases
        WHERE name NOT IN ('master', 'tempdb', 'model', 'msdb', 'experimentation', 'rdsadmin')
        """.strip()
        sql_sys_databases = sql_sys_databases_1
    else:
        if isinstance(in_rds_databases, list):
            rds_db_str = ', '.join(f"\'{db}\'" for db in in_rds_databases)
        elif isinstance(in_rds_databases, str):
            rds_db_str = in_rds_databases

        sql_sys_databases_2 = f"""
        SELECT name FROM sys.databases
        WHERE name IN ({rds_db_str})
        """.strip()
        sql_sys_databases = sql_sys_databases_2

    LOGGER.info(f"""Using SQL Statement >>>\n{sql_sys_databases}""")
    df_rds_sys = (spark.read.format("jdbc")
                            .option("url", get_rds_db_jdbc_url())
                            .option("query", sql_sys_databases)
                            .option("user", RDS_DB_INSTANCE_USER)
                            .option("password", RDS_DB_INSTANCE_PWD)
                            .option("driver", RDS_DB_INSTANCE_DRIVER)
                            .load()
                  )

    return [row[0] for row in df_rds_sys.collect()]


def get_rds_tables_dataframe(in_rds_db_name):
    sql_information_schema = f"""
    SELECT table_catalog, table_schema, table_name
      FROM information_schema.tables
     WHERE table_type = 'BASE TABLE'
    """.strip()

    return (spark.read.format("jdbc")
            .option("url", get_rds_db_jdbc_url(in_rds_db_name))
            .option("query", sql_information_schema)
            .option("user", RDS_DB_INSTANCE_USER)
            .option("password", RDS_DB_INSTANCE_PWD)
            .option("driver", RDS_DB_INSTANCE_DRIVER)
            .load()
            )


def get_rds_db_tbl_list(in_rds_sqlserver_db_list):
    rds_db_tbl_temp_list = list()
    for db in in_rds_sqlserver_db_list:
        rds_sqlserver_db_tbls = get_rds_tables_dataframe(db)
        rds_sqlserver_db_tbls = (rds_sqlserver_db_tbls.select(
            F.concat(rds_sqlserver_db_tbls.table_catalog,
                     F.lit('_'), rds_sqlserver_db_tbls.table_schema,
                     F.lit('_'), rds_sqlserver_db_tbls.table_name).alias("full_table_name")
            )
        )
        rds_db_tbl_temp_list = rds_db_tbl_temp_list + [row[0] for row in rds_sqlserver_db_tbls.collect()]

    return rds_db_tbl_temp_list


def get_rds_dataframe(in_rds_db_name, in_table_name):
    return spark.read.jdbc(url=get_rds_db_jdbc_url(in_rds_db_name),
                           table=in_table_name,
                           properties={"user": RDS_DB_INSTANCE_USER,
                                       "password": RDS_DB_INSTANCE_PWD,
                                       "driver": RDS_DB_INSTANCE_DRIVER})

def get_rds_tbl_col_attributes(in_rds_db_name, in_tbl_name):
    sql_statement = f"""SELECT column_name, data_type, is_nullable 
    FROM information_schema.columns
    WHERE table_name='{in_tbl_name}'
    """
    # ORDER BY ordinal_position
    return (spark.read.format("jdbc")
            .option("url", get_rds_db_jdbc_url(in_rds_db_name))
            .option("query", sql_statement)
            .option("user", RDS_DB_INSTANCE_USER)
            .option("password", RDS_DB_INSTANCE_PWD)
            .option("driver", RDS_DB_INSTANCE_DRIVER)
            .load()
            )

def trim_rds_df_str_columns(in_rds_df: DataFrame) -> DataFrame:
    return (in_rds_df.select(
            *[F.trim(F.col(c[0])).alias(c[0]) if c[1] == 'string' else F.col(c[0]) 
              for c in in_rds_df.dtypes])
           )

def get_rds_tbl_col_attr_dict(df_col_stats: DataFrame) -> DataFrame:
    key_col = 'column_name'; value_col = 'is_nullable'
    return df_col_stats.select(key_col, value_col).rdd.map(lambda row: (row[key_col], row[value_col])).collectAsMap()

def get_dtype(in_rds_df: DataFrame, in_col_name):
    return [dtype for name, dtype in in_rds_df.dtypes if name == in_col_name][0]

def get_dtypes_dict(in_rds_df: DataFrame):
    return {name:dtype for name, dtype in in_rds_df.dtypes}

def get_nvl_select_list(in_rds_df: DataFrame, in_rds_db_name, in_rds_tbl_name):
    df_col_attr = get_rds_tbl_col_attributes(in_rds_db_name, in_rds_tbl_name)
    df_col_attr_dict = get_rds_tbl_col_attr_dict(df_col_attr)
    # print(df_col_attr_dict)
    df_col_dtype_dict = get_dtypes_dict(in_rds_df)
    # print(df_col_dtype_dict)
    
    temp_select_list = list()
    for colmn in in_rds_df.columns:
        if df_col_attr_dict[colmn] == 'YES' and (not df_col_dtype_dict[colmn].startswith("decimal")):
            temp_select_list.append(f"""nvl({colmn}, {NVL_DTYPE_DICT[df_col_dtype_dict[colmn]]}) as {colmn}""")
            # print(f"F.nvl(df_rds.{colmn}, {NVL_DTYPE_DICT[df_col_dtype_dict[colmn]]})")
        else:
            temp_select_list.append(colmn)
            # print(colmn)
    return temp_select_list

# -------------------------------------------------------------------------


def get_s3_folder_info(bucket_name, prefix):
    paginator = S3_CLIENT.get_paginator('list_objects_v2')

    total_size = 0
    total_files = 0

    for page in paginator.paginate(Bucket=bucket_name, Prefix=prefix):
        for obj in page.get('Contents', []):
            total_files += 1
            total_size += obj['Size']

    return total_files, total_size


def check_s3_path_if_exists(in_bucket_name, in_folder_path):
    result = S3_CLIENT.list_objects(Bucket=in_bucket_name, Prefix=in_folder_path)
    exists = False
    if 'Contents' in result:
        exists = True
    return exists


def get_s3_csv_tbl_path(in_database_name, in_table_name):
    dir_path_str = f"{in_database_name}/dbo/{in_table_name}"
    if check_s3_path_if_exists(CSV_FILE_SRC_S3_BUCKET_NAME, dir_path_str):
        return f"s3://{CSV_FILE_SRC_S3_BUCKET_NAME}/{dir_path_str}/"
    else:
        return None

                            #   nullValue="null",
def get_s3_csv_dataframe(in_csv_tbl_s3_folder_path, in_rds_df_schema) -> DataFrame:
    try:
        return spark.read.csv(in_csv_tbl_s3_folder_path, 
                              header="true", 
                              schema=in_rds_df_schema,
                              enforceSchema=True,
                              escape='\"',
                              mode="FAILFAST")
    except Exception as err:
        LOGGER.error(err)

# ===================================================================================================


def process_dv_for_table(rds_db_name, rds_tbl_name, total_files, input_repartition_factor) -> DataFrame:

    default_repartition_factor = input_repartition_factor if total_files <= 1 \
                                    else total_files * input_repartition_factor

    sql_select_str = f"""
    select cast(null as timestamp) as run_datetime,
    cast(null as string) as json_row,
    cast(null as string) as validation_msg,
    cast(null as string) as database_name,
    cast(null as string) as full_table_name
    """.strip()

    df_dv_output = spark.sql(sql_select_str).repartition(input_repartition_factor)

    tbl_csv_s3_path = get_s3_csv_tbl_path(rds_db_name, rds_tbl_name)

    if tbl_csv_s3_path is not None:

        df_rds_temp = get_rds_dataframe(rds_db_name, rds_tbl_name).repartition(default_repartition_factor)

        if args.get("trim_rds_df_str_columns", "false") == "true":
            LOGGER.info(f"""Given -> trim_rds_df_str_columns = {args["trim_rds_df_str_columns"]}, {type(args["trim_rds_df_str_columns"])}""")
            df_rds_temp_t1 = df_rds_temp.transform(trim_rds_df_str_columns)
            df_rds_temp_t2 = df_rds_temp_t1.selectExpr(*get_nvl_select_list(df_rds_temp, rds_db_name, rds_tbl_name)).cache()
        else:
            df_rds_temp_t2 = df_rds_temp.selectExpr(*get_nvl_select_list(df_rds_temp, rds_db_name, rds_tbl_name)).cache()

        LOGGER.info(f"""RDS-Read-dataframe['{rds_db_name}.dbo.{rds_tbl_name}'] partitions --> {df_rds_temp.rdd.getNumPartitions()}""")
    
        df_csv_temp = get_s3_csv_dataframe(tbl_csv_s3_path, df_rds_temp.schema).repartition(default_repartition_factor)
        df_csv_temp_t1 = df_csv_temp.selectExpr(*get_nvl_select_list(df_rds_temp, rds_db_name, rds_tbl_name)).cache()

        LOGGER.info(
            f"""S3-CSV-Read-dataframe['{rds_db_name}/dbo/{rds_tbl_name}'] partitions --> {df_csv_temp.rdd.getNumPartitions()}, {total_size} bytes""")

        df_rds_temp_count = df_rds_temp_t2.count()
        df_csv_temp_count = df_csv_temp_t1.count()

        if df_rds_temp_count == df_csv_temp_count:

            df_subtract_t1 = df_rds_temp_t2.subtract(df_csv_temp_t1)
            df_rds_csv_subtract_row_count = df_subtract_t1.count()

            if df_rds_csv_subtract_row_count == 0:
                df_temp = df_dv_output.selectExpr("current_timestamp as run_datetime",
                                                  "'' as json_row",
                                                  f"""'{rds_tbl_name} - Validated.' as validation_msg""",
                                                  f"""'{rds_db_name}' as database_name""",
                                                  f"""'{db_dbo_tbl}' as full_table_name"""
                                                  )

                df_dv_output = df_dv_output.union(df_temp)
            else:
                df_temp = (df_subtract_t1
                           .withColumn('json_row', F.to_json(F.struct(*[F.col(c) for c in df_rds_temp.columns])))
                           .selectExpr("json_row")
                           .limit(100))

                df_temp = df_temp.selectExpr("current_timestamp as run_datetime",
                                             "json_row",
                                             f""" "'{rds_tbl_name}' - dataframe-subtract-op ->> {df_rds_csv_subtract_row_count} row-count !" as validation_msg""",
                                             f"""'{rds_db_name}' as database_name""",
                                             f"""'{db_dbo_tbl}' as full_table_name"""
                                             )

                df_dv_output = df_dv_output.union(df_temp)

        else:
            df_temp = df_dv_output.selectExpr("current_timestamp as run_datetime",
                                              "'' as json_row",
                                              f"""'{rds_tbl_name} - Table row-count {df_rds_temp_count}:{df_csv_temp_count} MISMATCHED !' as validation_msg""",
                                              f"""'{rds_db_name}' as database_name""",
                                              f"""'{db_dbo_tbl}' as full_table_name"""
                                              )

            df_dv_output = df_dv_output.union(df_temp)
        
        df_rds_temp_t2.unpersist()
        df_csv_temp_t1.unpersist()
    else:
        df_temp = df_dv_output.selectExpr("current_timestamp as run_datetime",
                                          "'' as json_row",
                                          f"""'No S3-csv folder path exists for the given {rds_db_name} - {rds_tbl_name}' as validation_msg""",
                                          f"""'{rds_db_name}' as database_name""",
                                          f"""'{db_dbo_tbl}' as full_table_name"""
                                          )

        df_dv_output = df_dv_output.union(df_temp)

    LOGGER.info(f"""{rds_db_name}.{rds_tbl_name} -- Validation Completed.""")

    return df_dv_output


def write_parquet_to_s3(df_dv_output: DataFrame, database, table):
    df_dv_output = df_dv_output.dropDuplicates()
    df_dv_output = df_dv_output.where("run_datetime is not null")

    LOGGER.info(
        f"""Dataframe-'df_dv_output' partitions before repartition: {df_dv_output.rdd.getNumPartitions()}""")

    df_dv_output = df_dv_output.orderBy("database_name", "full_table_name").repartition(1)

    if check_s3_path_if_exists(PARQUET_OUTPUT_S3_BUCKET_NAME,
                               f'''{GLUE_CATALOG_DB_NAME}/{GLUE_CATALOG_TBL_NAME}/database_name={database}/full_table_name={table}'''
                               ):
        LOGGER.info(f"""Purging S3-path: {CATALOG_TABLE_S3_FULL_PATH}/database_name={database}/full_table_name={table}""")

        glueContext.purge_s3_path(f"""{CATALOG_TABLE_S3_FULL_PATH}/database_name={database}/full_table_name={table}""",
                                  options={"retentionPeriod": 0}
                                  )

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
    LOGGER.info(f"""{rds_db_name}.{rds_tbl_name} validation report written to -> {CATALOG_TABLE_S3_FULL_PATH}/""")

# ===================================================================================================


if __name__ == "__main__":

    LOGGER.info(f"""Given database(s): {args.get("rds_sqlserver_dbs", None)}""")
    rds_sqlserver_db_list = get_rds_database_list(args.get("rds_sqlserver_dbs", None))
    LOGGER.info(f"""Using database(s): {rds_sqlserver_db_list}""")

    rds_sqlserver_db_tbl_list = get_rds_db_tbl_list(rds_sqlserver_db_list)

    if args.get("rds_sqlserver_tbls", None) is None:
        LOGGER.info(f"""List of tables to be processed: {rds_sqlserver_db_tbl_list}""")

        for db_dbo_tbl in rds_sqlserver_db_tbl_list:
            rds_db_name, rds_tbl_name = db_dbo_tbl.split('_dbo_')[0], db_dbo_tbl.split('_dbo_')[1]

            total_files, total_size = get_s3_folder_info(CSV_FILE_SRC_S3_BUCKET_NAME, f"{rds_db_name}/dbo/{rds_tbl_name}")

            if check_s3_path_if_exists(PARQUET_OUTPUT_S3_BUCKET_NAME,
                                       f'''{GLUE_CATALOG_DB_NAME}/{GLUE_CATALOG_TBL_NAME}/database_name={rds_db_name}/full_table_name={db_dbo_tbl}'''
                                       ):
                LOGGER.info(
                    f"""Already exists, Skipping --> {CATALOG_TABLE_S3_FULL_PATH}/database_name={rds_db_name}/full_table_name={db_dbo_tbl}""")
                continue

            elif total_size/1024/1024 > int(args["max_table_size_mb"]):
                LOGGER.info(
                    f"""Size greaterthan {args["max_table_size_mb"]}MB ({total_size} bytes), Skipping --> {CATALOG_TABLE_S3_FULL_PATH}/database_name={rds_db_name}/full_table_name={db_dbo_tbl}""")
                continue

            input_repartition_factor = int(args["repartition_factor"])

            df_dv_output = process_dv_for_table(rds_db_name, rds_tbl_name, total_files, input_repartition_factor)

            write_parquet_to_s3(df_dv_output, rds_db_name, db_dbo_tbl)

    else:
        LOGGER.info(f"""List of tables available: {rds_sqlserver_db_tbl_list}""")

        given_rds_sqlserver_tbls_str = args["rds_sqlserver_tbls"]

        LOGGER.info(
            f"""Given specific tables: {given_rds_sqlserver_tbls_str}, {type(given_rds_sqlserver_tbls_str)}""")

        given_rds_sqlserver_tbls_list = [e.strip().strip("'") for e in given_rds_sqlserver_tbls_str.split(",")]

        LOGGER.info(
            f"""Given specific tables list: {given_rds_sqlserver_tbls_list}, {type(given_rds_sqlserver_tbls_list)}""")

        filtered_rds_sqlserver_db_tbl_list = [tbl for tbl in given_rds_sqlserver_tbls_list \
                                              if tbl in rds_sqlserver_db_tbl_list]

        LOGGER.info(f"""List of tables to be processed: {filtered_rds_sqlserver_db_tbl_list}""")

        for db_dbo_tbl in filtered_rds_sqlserver_db_tbl_list:
            rds_db_name, rds_tbl_name = db_dbo_tbl.split('_dbo_')[0], db_dbo_tbl.split('_dbo_')[1]

            total_files, total_size = get_s3_folder_info(CSV_FILE_SRC_S3_BUCKET_NAME, 
                                                         f"{rds_db_name}/dbo/{rds_tbl_name}")

            input_repartition_factor = int(args["repartition_factor"])

            df_dv_output = process_dv_for_table(rds_db_name, rds_tbl_name, total_files, input_repartition_factor)

            write_parquet_to_s3(df_dv_output, rds_db_name, db_dbo_tbl)

    job.commit()
