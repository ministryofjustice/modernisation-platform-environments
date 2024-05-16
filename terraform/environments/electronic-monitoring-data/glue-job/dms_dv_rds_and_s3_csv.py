import sys
import boto3
import time
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

# Organise capturing input parameters.
DEFAULT_INPUTS_LIST = ["JOB_NAME",
                       "rds_db_host_ep",
                       "rds_db_pwd",
                       "csv_src_bucket_name",
                       "parquet_output_bucket_name",
                       "glue_catalog_db_name",
                       "glue_catalog_tbl_name"
                       ]

OPTIONAL_INPUTS = ['rds_sqlserver_dbs', 'rds_sqlserver_tbls']

for e in OPTIONAL_INPUTS:
    if ('--{}'.format(e) in sys.argv):
        DEFAULT_INPUTS_LIST.append(e)

args = getResolvedOptions(sys.argv, DEFAULT_INPUTS_LIST)

for e in OPTIONAL_INPUTS:
    if not ('--{}'.format(e) in sys.argv):
        args[f"{e}"] = None

# ------------------------------

sc = SparkContext.getOrCreate()
glueContext = GlueContext(sc)
spark = glueContext.spark_session

LOGGER = glueContext.get_logger()
LOGGER.info(f"""args = \n{args}""")
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

# ===================================================================================================
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
        rds_db_tbl_temp_list = rds_db_tbl_temp_list + \
            [row[0] for row in rds_sqlserver_db_tbls.collect()]

    return rds_db_tbl_temp_list


def get_rds_dataframe(in_rds_db_name, in_table_name):
    return spark.read.jdbc(url=get_rds_db_jdbc_url(in_rds_db_name),
                           table=in_table_name,
                           properties={"user": RDS_DB_INSTANCE_USER,
                                       "password": RDS_DB_INSTANCE_PWD,
                                       "driver": RDS_DB_INSTANCE_DRIVER})

# -------------------------------------------------------------------------


def check_s3_path_if_exists(in_bucket_name, in_folder_path):
    result = S3_CLIENT.list_objects(
        Bucket=in_bucket_name, Prefix=in_folder_path)
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


def get_s3_csv_dataframe(in_csv_tbl_s3_folder_path, in_rds_df_schema):
    try:
        return spark.read.csv(in_csv_tbl_s3_folder_path, header="true", schema=in_rds_df_schema)
    except Exception as err:
        LOGGER.error(err)

# ===================================================================================================

def process_dv_for_table(rds_db_name, rds_tbl_name, df_dv_output):

    df_rds_temp = get_rds_dataframe(rds_db_name, rds_tbl_name)

    tbl_csv_s3_path = get_s3_csv_tbl_path(rds_db_name, rds_tbl_name)

    if tbl_csv_s3_path is not None:

        df_csv_temp = get_s3_csv_dataframe(tbl_csv_s3_path, df_rds_temp.schema)

        df_rds_temp_count = df_rds_temp.count()
        df_csv_temp_count = df_csv_temp.count()

        if df_rds_temp_count == df_csv_temp_count:

            df_subtract = df_rds_temp.subtract(df_csv_temp).persist()
            df_rds_csv_subtract_row_count = df_subtract.count()
            
            if df_rds_csv_subtract_row_count == 0:
                df_temp = df_dv_output.selectExpr("current_timestamp as run_datetime",
                                                  f"""'{db_dbo_tbl}' as full_table_name""",
                                                  "'' as json_row",
                                                  f"""'{rds_tbl_name} - Validated.' as validation_msg""",
                                                  f"""'{rds_db_name}' as database_name"""
                                                  )

                df_dv_output = df_dv_output.union(df_temp)
            else:
                df_temp = (df_subtract
                            .withColumn('json_row', F.to_json(F.struct(*[F.col(c) for c in df_rds_temp.columns])))
                            .selectExpr("json_row")
                            .limit(1000))

                df_temp = df_temp.selectExpr("current_timestamp as run_datetime",
                                             f"""'{db_dbo_tbl}' as full_table_name""",
                                             "json_row",
                                             f""" "'{rds_tbl_name}' - dataframe-subtract-op ->> {df_rds_csv_subtract_row_count} row-count !" as validation_msg""",
                                             f"""'{rds_db_name}' as database_name"""
                                             )

                df_dv_output = df_dv_output.union(df_temp)

            df_subtract.unpersist()
            
        else:
            df_temp = df_dv_output.selectExpr("current_timestamp as run_datetime",
                                              f"""'{db_dbo_tbl}' as full_table_name""",
                                              "'' as json_row",
                                              f"""'{rds_tbl_name} - Table row-count {df_rds_temp_count}:{df_csv_temp_count} MISMATCHED !' as validation_msg""",
                                              f"""'{rds_db_name}' as database_name"""
                                              )

            df_dv_output = df_dv_output.union(df_temp)
    else:
        df_temp = df_dv_output.selectExpr("current_timestamp as run_datetime",
                                          f"""'{db_dbo_tbl}' as full_table_name""",
                                          "'' as json_row",
                                          f"""'No S3-csv folder path exists for the given {rds_db_name} - {rds_tbl_name}' as validation_msg""",
                                          f"""'{rds_db_name}' as database_name"""
                                          )

        df_dv_output = df_dv_output.union(df_temp)
    
    LOGGER.info(f"""{rds_db_name}.{rds_tbl_name} -- Validation Completed.""")

    return df_dv_output

# ===================================================================================================


if __name__ == "__main__":

    catalog_table_s3_full_path = f'''s3://{PARQUET_OUTPUT_S3_BUCKET_NAME}/{GLUE_CATALOG_DB_NAME}/{GLUE_CATALOG_TBL_NAME}'''

    LOGGER.info(f"""Given database(s): {args["rds_sqlserver_dbs"]}""")
    rds_sqlserver_db_list = get_rds_database_list(args["rds_sqlserver_dbs"])
    LOGGER.info(f"""Using database(s): {rds_sqlserver_db_list}""")

    rds_sqlserver_db_tbl_list = get_rds_db_tbl_list(rds_sqlserver_db_list)
    LOGGER.info(f"""List of tables to be processed: {rds_sqlserver_db_tbl_list}""")

    sql_select_str = f"""
    select cast(null as timestamp) as run_datetime,
    cast(null as string) as full_table_name, 
    cast(null as string) as json_row,
    cast(null as string) as validation_msg,
    cast(null as string) as database_name
    """.strip()
    
    df_dv_output = spark.sql(sql_select_str)

    for db_dbo_tbl in rds_sqlserver_db_tbl_list:
        rds_db_name, rds_tbl_name = db_dbo_tbl.split('_dbo_')[0], db_dbo_tbl.split('_dbo_')[1]

        df_dv_output = process_dv_for_table(rds_db_name, rds_tbl_name, df_dv_output).persist()

    df_dv_output = df_dv_output.dropDuplicates()
    df_dv_output = df_dv_output.where("run_datetime is not null")
    df_dv_output = df_dv_output.orderBy("database_name", "full_table_name").repartition("database_name")

    for db in rds_sqlserver_db_list:
        if check_s3_path_if_exists(PARQUET_OUTPUT_S3_BUCKET_NAME,
                                   f'''{GLUE_CATALOG_DB_NAME}/{GLUE_CATALOG_TBL_NAME}/database_name={db}'''
                                   ):
            LOGGER.info(f"""Purging S3-path: {catalog_table_s3_full_path}/database_name={db}""")
            glueContext.purge_s3_path(f"""{catalog_table_s3_full_path}/database_name={db}""", 
                                      options={"retentionPeriod": 0}
                                      )
    
    dydf = DynamicFrame.fromDF(df_dv_output, glueContext, "final_spark_df")
    LOGGER.info(f"""Writing Dataframe to {catalog_table_s3_full_path}/""")
    glueContext.write_dynamic_frame.from_options(frame=dydf, connection_type='s3', format='parquet',
                                                 connection_options={
                                                     'path': f"""{catalog_table_s3_full_path}/""",
                                                     "partitionKeys": ["database_name"]
                                                 },
                                                 format_options={
                                                     'useGlueParquetWriter': True,
                                                     'compression': 'snappy', 
                                                     'blockSize': 13421773, 
                                                     'pageSize': 1048576
                                                 })

    df_dv_output.unpersist()
    
    job.commit()
