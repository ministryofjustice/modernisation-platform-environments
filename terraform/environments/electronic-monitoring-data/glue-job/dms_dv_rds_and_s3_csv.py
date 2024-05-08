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

# Set up Glue context and job
args = getResolvedOptions(sys.argv, ["JOB_NAME",
                                     "rds_db_host_ep",
                                     "rds_db_pwd",
                                     "rds_db_list",
                                     "csv_src_bucket_name",
                                     "parquet_target_bucket_name",
                                     "target_catalog_db_name",
                                     "target_catalog_tbl_name"
                                     ])
# ------------------------------

sc = SparkContext.getOrCreate()
glueContext = GlueContext(sc)
spark = glueContext.spark_session

# ------------------------------

job = Job(glueContext)
job.init(args["JOB_NAME"], args)

# ------------------------------

GLUE_CLIENT = boto3.client('glue', region_name='eu-west-2')
S3_CLIENT = boto3.client("s3")
ATHENA_CLIENT = boto3.client("athena", region_name='eu-west-2')

# ------------------------------

RDS_DB_HOST_ENDPOINT = args["rds_db_host_ep"]
RDS_DB_PORT = 1433
RDS_DB_INSTANCE_USER = "admin"
RDS_DB_INSTANCE_PWD = args["rds_db_pwd"]
RDS_DB_INSTANCE_DRIVER = "com.microsoft.sqlserver.jdbc.SQLServerDriver"

CSV_FILE_SRC_S3_BUCKET_NAME = args["csv_src_bucket_name"]

PARQUET_TARGET_S3_BUCKET_NAME = args["parquet_target_bucket_name"]

PARQUET_TARGET_DB_NAME = args["target_catalog_db_name"]
PARQUET_TARGET_TBL_NAME = args["target_catalog_tbl_name"]

LOGGER = getLogger(__name__)

# ===================================================================================================
# USER-DEFINED-FUNCTIONS
# ----------------------


def get_rds_db_jdbc_url(in_rds_db_name=None):
    if in_rds_db_name is None:
        return f"""jdbc:sqlserver://{RDS_DB_HOST_ENDPOINT}:{RDS_DB_PORT};"""
    else:
        return f"""jdbc:sqlserver://{RDS_DB_HOST_ENDPOINT}:{RDS_DB_PORT};database={in_rds_db_name}"""


def get_rds_database_list(in_rds_databases = None):

    if in_rds_databases is None or in_rds_databases == "":
        sql_sys_databases_1 = f"""
        SELECT name
        FROM sys.databases
        WHERE name NOT IN ('master', 'tempdb', 'model', 'msdb', 'experimentation', 'rdsadmin')
        """.strip()
        sql_sys_databases = sql_sys_databases_1
    else:
        
        if isinstance(in_rds_databases, list):
            rds_db_str = ', '.join(f'`{db}`' for db in in_rds_databases)
        elif isinstance(in_rds_databases, str):
            rds_db_str = in_rds_databases
        
        sql_sys_databases_2 = f"""
        SELECT name
        FROM sys.databases
        WHERE name IN ({rds_db_str})
        """.strip()
        sql_sys_databases = sql_sys_databases_2

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
        return spark.read.csv(in_csv_tbl_s3_folder_path, schema=in_rds_df_schema)
    except Exception as err:
        print(err)

# ===================================================================================================


if __name__ == "__main__":

    TARGET_TABLE_PATH = f'''s3://{PARQUET_TARGET_S3_BUCKET_NAME}/{PARQUET_TARGET_DB_NAME}/{PARQUET_TARGET_TBL_NAME}/'''

    rds_sqlserver_db_tbl_list = get_rds_db_tbl_list(get_rds_database_list(args["rds_db_list"]))

    sql_select_str = f"""
    select cast(null as timestamp) as run_datetime, 
    cast(null as string) as full_table_name, 
    cast(null as string) as json_row,
    cast(null as string) as err_msg
    """.strip()

    df_dv_output = spark.sql(sql_select_str)

    for db_dbo_tbl in rds_sqlserver_db_tbl_list:
        rds_db_name, rds_tbl_name = db_dbo_tbl.split(
            '_dbo_')[0], db_dbo_tbl.split('_dbo_')[1]

        df_rds_temp = get_rds_dataframe(rds_db_name, rds_tbl_name)

        tbl_csv_s3_path = get_s3_csv_tbl_path(rds_db_name, rds_tbl_name)

        # print(tbl_csv_s3_path)
        if tbl_csv_s3_path is not None:

            df_csv_temp = get_s3_csv_dataframe(tbl_csv_s3_path, df_rds_temp.schema)

            if df_rds_temp.count() == df_csv_temp.count():

                if df_rds_temp.subtract(df_csv_temp).count() == 0:
                    LOGGER.info(f"{rds_tbl_name} - Validated.")
                    # print(f"{rds_tbl_name} - Validated.")
                else:
                    df_temp = (df_rds_temp.subtract(df_csv_temp)
                               .withColumn('json_row', F.to_json(F.struct(*[F.col(c) for c in df_rds_temp.columns])))
                               .selectExpr("json_row"))
                
                    df_temp = df_temp.selectExpr("current_timestamp as run_datetime", f"""'{db_dbo_tbl}' as full_table_name""", "json_row",
                                             f""""'{rds_tbl_name}' - dataframe-subtract-op ->> NON-ZERO row-count !" as err_msg""")
                    
                    df_dv_output = df_dv_output.union(df_temp)

                    # print(f"{rds_tbl_name} - subtract op NON-ZERO row count")
            else:
                df_temp = df_dv_output.selectExpr("current_timestamp as run_datetime",
                                                  f"""'{db_dbo_tbl}' as full_table_name""",
                                                  "'' as json_row",
                                                  f"""'{rds_tbl_name} - Table row count MISMATCHED !' as err_msg""")
                
                df_dv_output = df_dv_output.union(df_temp)
                
                # print(f"{rds_tbl_name} - Table row count MISMATCHED.")

        else:
            df_temp = df_dv_output.selectExpr("current_timestamp as run_datetime",
                                              f"""'{db_dbo_tbl}' as full_table_name""",
                                              "'' as json_row",
                                              f"""'No S3-csv folder path exists for the given {rds_db_name} - {rds_tbl_name}' as err_msg""")
            
            df_dv_output = df_dv_output.union(df_temp)
            
            # print(f"No S3-csv folder path found for given {rds_db_name} - {rds_tbl_name}")
        
        if check_s3_path_if_exists(PARQUET_TARGET_S3_BUCKET_NAME, f'''{PARQUET_TARGET_DB_NAME}/{PARQUET_TARGET_TBL_NAME}/full_table_name={db_dbo_tbl}'''):
            glueContext.purge_s3_path(TARGET_TABLE_PATH, options={"retentionPeriod": 0})

    df_dv_output = df_dv_output.dropDuplicates()
    df_dv_output = df_dv_output.where("run_datetime is not null")

    dydf = DynamicFrame.fromDF(df_dv_output, glueContext, "final_spark_df")
    glueContext.write_dynamic_frame.from_options(frame=dydf, connection_type='s3', format='parquet',
                                                 connection_options={
                                                     'path': TARGET_TABLE_PATH,
                                                     "partitionKeys": ["full_table_name"]},
                                                 format_options={
                                                     'useGlueParquetWriter': True,
                                                     # 'compression': 'snappy', 'blockSize': 134217728, 'pageSize': 1048576
                                                 })

    job.commit()
