import sys
import boto3
from logging import getLogger
import pandas as pd

from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from awsglue.context import GlueContext
from awsglue.dynamicframe import DynamicFrame
from awsglue.job import Job

import pyspark.sql.functions as F
import pyspark.sql.types as T
from pyspark.sql import DataFrame

# ===============================================================================

sc = SparkContext()
sc._jsc.hadoopConfiguration().set("spark.memory.offHeap.enabled", "true")
sc._jsc.hadoopConfiguration().set("spark.memory.offHeap.size", "2g")
sc._jsc.hadoopConfiguration().set("spark.dynamicAllocation.enabled", "true")

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
                       "parquet_src_bucket_name",
                       "parquet_output_bucket_name",
                       "glue_catalog_db_name",
                       "glue_catalog_tbl_name",
                       "rds_sqlserver_db",
                       "rds_sqlserver_db_schema",
                       "num_of_repartitions",
                       "read_partition_size_mb",
                       "max_table_size_mb",
                       "rds_df_trim_str_columns"
                       ]

OPTIONAL_INPUTS = [
    "rds_select_db_tbls",
    "rds_exclude_db_tbls",
    "rds_db_tbl_pkeys_col_list",
    "rds_df_trim_micro_sec_ts_col_list",
    "rds_read_rows_fetch_size",
    "parquet_tbl_folder_if_different"
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

PRQ_FILES_SRC_S3_BUCKET_NAME = args["parquet_src_bucket_name"]

PARQUET_OUTPUT_S3_BUCKET_NAME = args["parquet_output_bucket_name"]

GLUE_CATALOG_DB_NAME = args["glue_catalog_db_name"]
GLUE_CATALOG_TBL_NAME = args["glue_catalog_tbl_name"]

CATALOG_DB_TABLE_PATH = f"""{GLUE_CATALOG_DB_NAME}/{GLUE_CATALOG_TBL_NAME}"""
CATALOG_TABLE_S3_FULL_PATH = f'''s3://{PARQUET_OUTPUT_S3_BUCKET_NAME}/{CATALOG_DB_TABLE_PATH}'''

NVL_DTYPE_DICT = {'string': "''", 'int': 0, 'double': 0, 'float': 0, 'smallint': 0, 'bigint':0,
                  'boolean': False,
                  'timestamp': "to_timestamp('1900-01-01', 'yyyy-MM-dd')", 
                  'date': "to_date('1900-01-01', 'yyyy-MM-dd')"}

INT_DATATYPES_LIST = ['tinyint', 'smallint', 'int', 'bigint']

RECORDED_PKEYS_LIST = {
    'F_History': ['HistorySID']
}

# ===============================================================================
# USER-DEFINED-FUNCTIONS
# ----------------------


def get_rds_db_jdbc_url(in_rds_db_name=None):
    if in_rds_db_name is None:
        return f"""jdbc:sqlserver://{RDS_DB_HOST_ENDPOINT}:{RDS_DB_PORT};"""
    else:
        return f"""jdbc:sqlserver://{RDS_DB_HOST_ENDPOINT}:{RDS_DB_PORT};database={in_rds_db_name}"""


def check_if_rds_db_exists(in_rds_db_str):
    sql_sys_databases = f"""
    SELECT name FROM sys.databases
    WHERE name IN ('{in_rds_db_str}')
    """.strip()

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


def get_rds_tables_dataframe(in_rds_db_name) -> DataFrame:
    given_rds_sqlserver_db_schema = args["rds_sqlserver_db_schema"]
    sql_information_schema = f"""
    SELECT table_catalog, table_schema, table_name
      FROM information_schema.tables
     WHERE table_type = 'BASE TABLE'
       AND table_schema = '{given_rds_sqlserver_db_schema}'
    """.strip()

    LOGGER.info(f"using the SQL Statement:\n{sql_information_schema}")

    return (spark.read.format("jdbc")
            .option("url", get_rds_db_jdbc_url(in_rds_db_name))
            .option("query", sql_information_schema)
            .option("user", RDS_DB_INSTANCE_USER)
            .option("password", RDS_DB_INSTANCE_PWD)
            .option("driver", RDS_DB_INSTANCE_DRIVER)
            .load()
            )

def get_rds_db_tbl_list(in_rds_sqlserver_db_str):
    rds_db_tbl_temp_list = list()

    df_rds_sqlserver_db_tbls = get_rds_tables_dataframe(in_rds_sqlserver_db_str)

    df_rds_sqlserver_db_tbls = (df_rds_sqlserver_db_tbls.select(
                                    F.concat(df_rds_sqlserver_db_tbls.table_catalog,
                                    F.lit('_'), df_rds_sqlserver_db_tbls.table_schema,
                                    F.lit('_'), df_rds_sqlserver_db_tbls.table_name).alias("full_table_name"))
    )

    rds_db_tbl_temp_list = rds_db_tbl_temp_list + \
                            [row[0] for row in df_rds_sqlserver_db_tbls.collect()]

    return rds_db_tbl_temp_list


def get_rds_dataframe(in_rds_db_name, in_table_name) -> DataFrame:
    return spark.read.jdbc(url=get_rds_db_jdbc_url(in_rds_db_name),
                           table=f"""{given_rds_sqlserver_db_schema}.[{in_table_name}]""",
                           properties={"user": RDS_DB_INSTANCE_USER,
                                       "password": RDS_DB_INSTANCE_PWD,
                                       "driver": RDS_DB_INSTANCE_DRIVER})


def get_rds_db_table_empty_df(in_rds_db_name, 
                              in_table_name) -> DataFrame:
    given_rds_sqlserver_db_schema = args["rds_sqlserver_db_schema"]
    
    query_str = f"""
    SELECT *
    FROM {given_rds_sqlserver_db_schema}.[{in_table_name}]
    WHERE 1 = 2
    """.strip()

    return (spark.read.format("jdbc")
                .option("url", get_rds_db_jdbc_url(in_rds_db_name))
                .option("driver", RDS_DB_INSTANCE_DRIVER)
                .option("user", RDS_DB_INSTANCE_USER)
                .option("password", RDS_DB_INSTANCE_PWD)
                .option("query", f"""{query_str}""")
                .load())


def get_df_read_rds_db_tbl_int_pkey(in_rds_db_name, in_table_name,
                                    jdbc_partition_column, 
                                    jdbc_partition_col_upperbound, 
                                    jdbc_read_partitions_num,
                                    jdbc_rows_fetch_size
                                    ) -> DataFrame:
    given_rds_sqlserver_db_schema = args["rds_sqlserver_db_schema"]
    
    numPartitions = jdbc_read_partitions_num
    # Note: numPartitions is normally equal to number of executors defined.
    # The maximum number of partitions that can be used for parallelism in table reading and writing. 
    # This also determines the maximum number of concurrent JDBC connections. 

    fetchSize = jdbc_rows_fetch_size
    # The JDBC fetch size, which determines how many rows to fetch per round trip. 
    # This can help performance on JDBC drivers which default to low fetch size (e.g. Oracle with 10 rows).
    # Too Small: => frequent round trips to database
    # Too Large: => Consume a lot of memory

    query_str = f"""
    SELECT *
    FROM {given_rds_sqlserver_db_schema}.[{in_table_name}]
    """.strip()

    return (spark.read.format("jdbc")
                .option("url", get_rds_db_jdbc_url(in_rds_db_name))
                .option("driver", RDS_DB_INSTANCE_DRIVER)
                .option("user", RDS_DB_INSTANCE_USER)
                .option("password", RDS_DB_INSTANCE_PWD)
                .option("dbtable", f"""({query_str}) as t""")
                .option("partitionColumn", jdbc_partition_column)
                .option("lowerBound", "0")
                .option("upperBound", jdbc_partition_col_upperbound)
                .option("numPartitions", numPartitions)
                .option("fetchSize", fetchSize)
                .load())


def get_rds_db_table_row_count(in_rds_db_name, 
                               in_table_name, 
                               in_pkeys_col_list) -> DataFrame:
    given_rds_sqlserver_db_schema = args["rds_sqlserver_db_schema"]
    
    query_str = f"""
    SELECT count({', '.join(in_pkeys_col_list)}) as row_count
    FROM {given_rds_sqlserver_db_schema}.[{in_table_name}]
    """.strip()

    return (spark.read.format("jdbc")
                    .option("url", get_rds_db_jdbc_url(in_rds_db_name))
                    .option("driver", RDS_DB_INSTANCE_DRIVER)
                    .option("user", RDS_DB_INSTANCE_USER)
                    .option("password", RDS_DB_INSTANCE_PWD)
                    .option("query", f"""{query_str}""")
                    .load()).collect()[0].row_count


def get_rds_tbl_col_attributes(in_rds_db_name, in_tbl_name) -> DataFrame:
    given_rds_sqlserver_db_schema = args["rds_sqlserver_db_schema"]

    sql_statement = f"""
    SELECT column_name, data_type, is_nullable 
    FROM information_schema.columns
    WHERE table_schema = '{given_rds_sqlserver_db_schema}'
      AND table_name = '{in_tbl_name}'
    """.strip()
    # ORDER BY ordinal_position

    return (spark.read.format("jdbc")
            .option("url", get_rds_db_jdbc_url(in_rds_db_name))
            .option("query", sql_statement)
            .option("user", RDS_DB_INSTANCE_USER)
            .option("password", RDS_DB_INSTANCE_PWD)
            .option("driver", RDS_DB_INSTANCE_DRIVER)
            .load()
            )


def rds_df_trim_str_columns(in_rds_df: DataFrame) -> DataFrame:
    return (in_rds_df.select(
            *[F.trim(F.col(c[0])).alias(c[0]) if c[1] == 'string' else F.col(c[0])
              for c in in_rds_df.dtypes])
            )


def rds_df_trim_microseconds_timestamp(in_rds_df: DataFrame, in_col_list) -> DataFrame:
    return (in_rds_df.select(
            *[F.date_format(F.col(c[0]),'yyyy-MM-dd HH:mm:ss.SSS').alias(c[0]).cast('timestamp') 
              if c[1] == 'timestamp' and c[0] in in_col_list else F.col(c[0])
              for c in in_rds_df.dtypes])
            )


def get_rds_tbl_col_attr_dict(df_col_stats: DataFrame) -> DataFrame:
    key_col = 'column_name'
    value_col = 'is_nullable'
    return (df_col_stats.select(key_col, value_col)
            .rdd.map(lambda row: (row[key_col], row[value_col])).collectAsMap())


def get_dtypes_dict(in_rds_df: DataFrame):
    return {name: dtype for name, dtype in in_rds_df.dtypes}


def get_nvl_select_list(in_rds_df: DataFrame, in_rds_db_name, in_rds_tbl_name):
    df_col_attr = get_rds_tbl_col_attributes(in_rds_db_name, in_rds_tbl_name)
    df_col_attr_dict = get_rds_tbl_col_attr_dict(df_col_attr)
    df_col_dtype_dict = get_dtypes_dict(in_rds_df)

    temp_select_list = list()
    for colmn in in_rds_df.columns:
        if df_col_attr_dict[colmn] == 'YES' and \
           (not df_col_dtype_dict[colmn].startswith("decimal")) and \
           (not df_col_dtype_dict[colmn].startswith("binary")):
            
            temp_select_list.append(f"""nvl({colmn}, {NVL_DTYPE_DICT[df_col_dtype_dict[colmn]]}) as {colmn}""")
        else:
            temp_select_list.append(colmn)
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


def check_s3_folder_path_if_exists(in_bucket_name, in_folder_path):
    result = S3_CLIENT.list_objects(
        Bucket=in_bucket_name, Prefix=in_folder_path)
    exists = False
    if 'Contents' in result:
        exists = True
    return exists


def get_s3_table_folder_path(in_database_name, in_table_name):
    dir_path_str = f"{in_database_name}/{args['rds_sqlserver_db_schema']}/{in_table_name}"
    tbl_full_dir_path_str = f"s3://{PRQ_FILES_SRC_S3_BUCKET_NAME}/{dir_path_str}/"

    if check_s3_folder_path_if_exists(PRQ_FILES_SRC_S3_BUCKET_NAME, dir_path_str):
        return tbl_full_dir_path_str
    else:
        LOGGER.info(f"{tbl_full_dir_path_str} -- Table-Folder-S3-Path Not Found !")
        return None


def get_s3_parquet_df_v1(in_s3_parquet_folder_path, in_rds_df_schema) -> DataFrame:
    return spark.createDataFrame(spark.read.parquet(in_s3_parquet_folder_path).rdd, in_rds_df_schema)

def get_s3_parquet_df_v2(in_s3_parquet_folder_path, in_rds_df_schema) -> DataFrame:
    return spark.read.schema(in_rds_df_schema).parquet(in_s3_parquet_folder_path)

def get_s3_parquet_df_v3(in_s3_parquet_folder_path, in_rds_df_schema) -> DataFrame:
    return spark.read.format("parquet").load(in_s3_parquet_folder_path, schema=in_rds_df_schema)


# ===================================================================================================


def get_jdbc_partition_column(rds_db_name, rds_tbl_name, rds_tbl_pkeys_list):

    rds_db_table_empty_df = get_rds_db_table_empty_df(rds_db_name, rds_tbl_name)
    df_rds_dtype_dict = get_dtypes_dict(rds_db_table_empty_df)
    int_dtypes_colname_list = [colname for colname, dtype in df_rds_dtype_dict.items() 
                                if dtype in INT_DATATYPES_LIST]

    if len(rds_tbl_pkeys_list) == 1 and \
        (rds_tbl_pkeys_list[0] in int_dtypes_colname_list):

        return rds_tbl_pkeys_list[0]
    else:
        LOGGER.error(f"""int_dtypes_colname_list = {int_dtypes_colname_list}""")
        LOGGER.error(f"""PrimaryKey column(s) are more than one (OR) not an integer datatype column!""")
        sys.exit(1)


def get_df_jdbc_read_rds_partitions(rds_db_name, 
                                    rds_tbl_name, 
                                    rds_tbl_pkeys_list,
                                    jdbc_partition_column,
                                    read_partitions,
                                    total_files) -> DataFrame:

    jdbc_read_partitions_num = read_partitions \
                                if read_partitions > total_files else total_files

    df_rds_count = get_rds_db_table_row_count(rds_db_name, 
                                              rds_tbl_name, 
                                              rds_tbl_pkeys_list)

    jdbc_partition_col_upperbound = int(df_rds_count/jdbc_read_partitions_num)

    rds_read_rows_fetch_size = int(args["rds_read_rows_fetch_size"])

    jdbc_rows_fetch_size = jdbc_partition_col_upperbound \
                                if jdbc_partition_col_upperbound > rds_read_rows_fetch_size \
                                    else rds_read_rows_fetch_size

    df_rds_temp = get_df_read_rds_db_tbl_int_pkey(rds_db_name, rds_tbl_name, 
                                                  jdbc_partition_column,
                                                  jdbc_partition_col_upperbound,
                                                  jdbc_read_partitions_num,
                                                  jdbc_rows_fetch_size)

    return df_rds_temp


def process_dv_for_table(rds_db_name, 
                         rds_tbl_name, 
                         total_files, 
                         total_size_mb) -> DataFrame:

    read_partitions = int(total_size_mb/int(args['read_partition_size_mb']))
    
    num_of_repartitions = int(args['num_of_repartitions'])

    sql_select_str = f"""
    select cast(null as timestamp) as run_datetime,
    cast(null as string) as json_row,
    cast(null as string) as validation_msg,
    cast(null as string) as database_name,
    cast(null as string) as full_table_name,
    cast(null as string) as table_to_ap
    """.strip()

    df_dv_output = spark.sql(sql_select_str).repartition(3)

    parquet_tbl_folder_if_different = args.get('parquet_tbl_folder_if_different', '')
    if parquet_tbl_folder_if_different != '':
        tbl_prq_s3_folder_path = get_s3_table_folder_path(rds_db_name, 
                                                          parquet_tbl_folder_if_different)
        LOGGER.info(f"""Using a different parquet folder: {parquet_tbl_folder_if_different}""")
    else:
        tbl_prq_s3_folder_path = get_s3_table_folder_path(rds_db_name, rds_tbl_name)
    # -------------------------------------------------------

    LOGGER.info(f"""tbl_prq_s3_folder_path: {tbl_prq_s3_folder_path}""")
    
    pkey_partion_read_used = False
    if tbl_prq_s3_folder_path is not None:
        
        # READ RDS-SQLSERVER-DB --> DATAFRAME
        if args.get('rds_db_tbl_pkeys_col_list', None) is None:
            
            if RECORDED_PKEYS_LIST.get(rds_tbl_name, None) is None:
                LOGGER.warn(f"""No READ-partition columns given !""")
                df_rds_temp = get_rds_dataframe(rds_db_name, rds_tbl_name)

            else:

                if isinstance(RECORDED_PKEYS_LIST[rds_tbl_name], list):

                    jdbc_partition_column = get_jdbc_partition_column(rds_db_name, 
                                                                      rds_tbl_name, 
                                                                      RECORDED_PKEYS_LIST[rds_tbl_name])
                    LOGGER.info(f"""RECORDED_PKEYS_LIST[{rds_tbl_name}] = {jdbc_partition_column}""")

                    df_rds_temp = get_df_jdbc_read_rds_partitions(rds_db_name, 
                                                                  rds_tbl_name, 
                                                                  RECORDED_PKEYS_LIST[rds_tbl_name],
                                                                  jdbc_partition_column,
                                                                  read_partitions,
                                                                  total_files)
                    pkey_partion_read_used = True
                else:
                    LOGGER.error(f"""RECORDED_PKEYS_LIST[f"{rds_tbl_name}"] = {RECORDED_PKEYS_LIST[{rds_tbl_name}]}""")
                    LOGGER.error(f"""RECORDED_PKEYS_LIST[f"{rds_tbl_name}"] - value is not a list""")
                    sys.exit(1)
                # -------------------------------------------------------

            # -------------------------------------------------------
            
        else:
            rds_db_tbl_pkeys_col_list = [f"""{column.strip().strip("'").strip('"')}""" 
                                         for column in args['rds_db_tbl_pkeys_col_list'].split(",")]

            jdbc_partition_column = get_jdbc_partition_column(rds_db_name, 
                                                              rds_tbl_name, 
                                                              rds_db_tbl_pkeys_col_list)
            LOGGER.info(f"""jdbc_partition_column = {jdbc_partition_column}""")

            df_rds_temp = get_df_jdbc_read_rds_partitions(rds_db_name, 
                                                          rds_tbl_name, 
                                                          rds_db_tbl_pkeys_col_list,
                                                          jdbc_partition_column,
                                                          read_partitions,
                                                          total_files)
            pkey_partion_read_used = True
        # -------------------------------------------------------

        LOGGER.info(f"""df_rds_temp-{rds_tbl_name}: READ PARTITIONS = {df_rds_temp.rdd.getNumPartitions()}""")
        
        # READ PARQUET --> DATAFRAME
        LOGGER.info(f"""S3-Folder-Parquet-Read: Total Size >> {total_size_mb}MB""")
        df_prq_temp = get_s3_parquet_df_v2(tbl_prq_s3_folder_path, df_rds_temp.schema)
        LOGGER.info(f"""df_prq_temp-{rds_tbl_name}: READ PARTITIONS = {df_prq_temp.rdd.getNumPartitions()}""")


        if num_of_repartitions != 0 and pkey_partion_read_used:
            df_rds_temp = df_rds_temp.repartition(num_of_repartitions, jdbc_partition_column)
            LOGGER.info(f"""df_rds_temp-{rds_tbl_name}: RE-PARTITIONS-1 = {df_rds_temp.rdd.getNumPartitions()}""")

            df_prq_temp = df_prq_temp.repartition(num_of_repartitions, jdbc_partition_column)
            LOGGER.info(f"""df_prq_temp-{rds_tbl_name}: RE-PARTITIONS-1 = {df_prq_temp.rdd.getNumPartitions()}""")

        elif num_of_repartitions != 0 and (not pkey_partion_read_used):
            df_rds_temp = df_rds_temp.repartition(num_of_repartitions)
            LOGGER.info(f"""df_rds_temp-{rds_tbl_name}: RE-PARTITIONS-2 = {df_rds_temp.rdd.getNumPartitions()}""")

            df_prq_temp = df_prq_temp.repartition(num_of_repartitions)
            LOGGER.info(f"""df_prq_temp-{rds_tbl_name}: RE-PARTITIONS-2 = {df_prq_temp.rdd.getNumPartitions()}""")

        elif num_of_repartitions == 0 and (not pkey_partion_read_used):
            df_rds_temp = df_rds_temp.repartition(df_prq_temp.rdd.getNumPartitions())
            LOGGER.info(f"""df_rds_temp-{rds_tbl_name}: RE-PARTITIONS-3 = {df_prq_temp.rdd.getNumPartitions()}""")
        # -------------------------------------------------------

        df_rds_temp_t1 = df_rds_temp.selectExpr(*get_nvl_select_list(df_rds_temp, rds_db_name, rds_tbl_name))


        trim_str_msg = ""
        t2_rds_str_col_trimmed = False
        if args.get("rds_df_trim_str_columns", "false") == "true":
            LOGGER.info(f"""Given -> rds_df_trim_str_columns = 'true'""")
            LOGGER.warn(f""">> Stripping string column spaces <<""")

            df_rds_temp_t2 = df_rds_temp_t1.transform(rds_df_trim_str_columns)

            trim_str_msg = "; [str column(s) - extra spaces trimmed]"
            t2_rds_str_col_trimmed = True
        # -------------------------------------------------------

        trim_ts_ms_msg = ""
        t3_rds_ts_col_msec_trimmed = False
        if args.get("rds_df_trim_micro_sec_ts_col_list", None) is not None:

            msg_prefix = f"""Given -> rds_df_trim_micro_sec_ts_col_list = {given_rds_df_trim_micro_seconds_col_list}"""
            given_rds_df_trim_micro_seconds_col_str = args["rds_df_trim_micro_sec_ts_col_list"]
            given_rds_df_trim_micro_seconds_col_list = [f"""{col.strip().strip("'").strip('"')}"""
                                                        for col in given_rds_df_trim_micro_seconds_col_str.split(",")]
            LOGGER.info(f"""{msg_prefix}, {type(given_rds_df_trim_micro_seconds_col_list)}""")

            if t2_rds_str_col_trimmed == True:
                df_rds_temp_t3 = rds_df_trim_microseconds_timestamp(df_rds_temp_t2, 
                                                                    given_rds_df_trim_micro_seconds_col_list)
            else:
                df_rds_temp_t3 = rds_df_trim_microseconds_timestamp(df_rds_temp_t1, 
                                                                    given_rds_df_trim_micro_seconds_col_list)
            # -------------------------------------------------------

            trim_ts_ms_msg = "; [timestamp column(s) - micro-seconds trimmed]"
            t3_rds_ts_col_msec_trimmed = True
        # -------------------------------------------------------

        if t3_rds_ts_col_msec_trimmed:
            df_rds_temp_t4 = df_rds_temp_t3
        elif t2_rds_str_col_trimmed:
            df_rds_temp_t4 = df_rds_temp_t2
        else:
            df_rds_temp_t4 = df_rds_temp_t1
        # -------------------------------------------------------

        df_rds_temp_t5 = df_rds_temp_t4.cache()

        df_prq_temp_t1 = df_prq_temp.selectExpr(*get_nvl_select_list(df_rds_temp, 
                                                                     rds_db_name, 
                                                                     rds_tbl_name)
                            ).cache()

        df_rds_temp_count = df_rds_temp_t5.count()
        df_prq_temp_count = df_prq_temp_t1.count()
        # -------------------------------------------------------

        if df_rds_temp_count == df_prq_temp_count:

            df_rds_prq_subtract_t1 = df_rds_temp_t5.subtract(df_prq_temp_t1)
            df_rds_prq_subtract_row_count = df_rds_prq_subtract_t1.count()

            if df_rds_prq_subtract_row_count == 0:
                df_temp = df_dv_output.selectExpr(
                                        "current_timestamp as run_datetime",
                                        "'' as json_row",
                                        f"""'{rds_tbl_name} - Validated.\n{trim_str_msg}\n{trim_ts_ms_msg}' as validation_msg""",
                                        f"""'{rds_db_name}' as database_name""",
                                        f"""'{db_sch_tbl}' as full_table_name""",
                                        """'False' as table_to_ap"""
                            )
                LOGGER.info(f"Validation Successful - 1")
                df_dv_output = df_dv_output.union(df_temp)
            else:
                df_subtract_temp = (df_rds_prq_subtract_t1
                           .withColumn('json_row', F.to_json(F.struct(*[F.col(c) for c in df_rds_temp.columns])))
                           .selectExpr("json_row")
                           .limit(100))

                subtract_validation_msg = f"""'{rds_tbl_name}' - {df_rds_prq_subtract_row_count}"""
                df_subtract_temp = df_subtract_temp.selectExpr(
                                        "current_timestamp as run_datetime",
                                        "json_row",
                                        f""""{subtract_validation_msg} - Dataframe(s)-Subtract Non-Zero Row Count!" as validation_msg""",
                                        f"""'{rds_db_name}' as database_name""",
                                        f"""'{db_sch_tbl}' as full_table_name""",
                                        """'False' as table_to_ap"""
                                    )
                LOGGER.warn(f"Validation Failed - 2")
                df_dv_output = df_dv_output.union(df_subtract_temp)
            # -------------------------------------------------------

        else:
            mismatch_validation_msg_1 = "MISMATCHED Dataframe(s) Row Count!"
            mismatch_validation_msg_2 = f"""'{rds_tbl_name} - {df_rds_temp_count}:{df_prq_temp_count} {mismatch_validation_msg_1}' as validation_msg"""
            LOGGER.warn(f"df_rds_row_count={df_rds_temp_count} ; df_prq_row_count={df_prq_temp_count} ; {mismatch_validation_msg_1}")
            df_temp = df_dv_output.selectExpr(
                                    "current_timestamp as run_datetime",
                                    "'' as json_row",
                                    mismatch_validation_msg_2,
                                    f"""'{rds_db_name}' as database_name""",
                                    f"""'{db_sch_tbl}' as full_table_name""",
                                    """'False' as table_to_ap"""
                        )
            LOGGER.warn(f"Validation Failed - 3")
            df_dv_output = df_dv_output.union(df_temp)
        # -------------------------------------------------------

        df_rds_temp_t5.unpersist(True)
        df_prq_temp_t1.unpersist(True)

    else:

        df_temp = df_dv_output.selectExpr(
                                "current_timestamp as run_datetime",
                                "'' as json_row",
                                f"""'{db_sch_tbl} - S3-Parquet folder path does not exist !' as validation_msg""",
                                f"""'{rds_db_name}' as database_name""",
                                f"""'{db_sch_tbl}' as full_table_name""",
                                """'False' as table_to_ap"""
                    )
        LOGGER.warn(f"Validation not applicable - 4")
        df_dv_output = df_dv_output.union(df_temp)
    # -------------------------------------------------------

    LOGGER.info(f"""{rds_db_name}.{rds_tbl_name} -- Validation Completed.""")

    return df_dv_output


def write_parquet_to_s3(df_dv_output: DataFrame, database, table):
    df_dv_output = df_dv_output.dropDuplicates()
    df_dv_output = df_dv_output.where("run_datetime is not null")

    df_dv_output = df_dv_output.orderBy("database_name", "full_table_name").repartition(1)

    if check_s3_folder_path_if_exists(PARQUET_OUTPUT_S3_BUCKET_NAME,
                                      f'''{CATALOG_DB_TABLE_PATH}/database_name={database}/full_table_name={table}'''
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
    LOGGER.info(
        f"""{rds_db_name}.{rds_tbl_name} validation report written to -> {CATALOG_TABLE_S3_FULL_PATH}/""")

# ===================================================================================================


if __name__ == "__main__":

    LOGGER.info(f"""Given database: {args.get("rds_sqlserver_db", None)}""")
    rds_sqlserver_db_list = check_if_rds_db_exists(args.get("rds_sqlserver_db", None))
    rds_sqlserver_db_str = '' if len(rds_sqlserver_db_list) == 0 else rds_sqlserver_db_list[0]
    
    # -------------------------------------------------------
    
    if rds_sqlserver_db_str == '':
        LOGGER.error(f"""Given database name not found! >> {args['rds_sqlserver_db']} <<""")
        sys.exit(1)
    # -------------------------------------------------------
    
    LOGGER.info(f"""Using database(s): {rds_sqlserver_db_str}""")
    
    given_rds_sqlserver_db_schema = args["rds_sqlserver_db_schema"]
    LOGGER.info(f"""Given rds_sqlserver_db_schema = {given_rds_sqlserver_db_schema}""")

    rds_sqlserver_db_tbl_list = get_rds_db_tbl_list(rds_sqlserver_db_str)

    # -------------------------------------------------------

    if not rds_sqlserver_db_tbl_list:
            LOGGER.error(f"""rds_sqlserver_db_tbl_list - is empty. Exiting ...!""")
            sys.exit(1)
    # -------------------------------------------------------

    message_prefix = f"""Total List of tables available in {rds_sqlserver_db_str}.{given_rds_sqlserver_db_schema}"""
    LOGGER.info(f"""{message_prefix}\n{rds_sqlserver_db_tbl_list}""")
    
    # -------------------------------------------------------

    if args.get("rds_select_db_tbls", None) is None:
        # -------------------------------------------------------
        
        if args.get("rds_exclude_db_tbls", None) is None:
            exclude_rds_db_tbls_list = list()
        else:
            table_name_prefix = f"""{args['rds_sqlserver_db']}_{given_rds_sqlserver_db_schema}"""
            exclude_rds_db_tbls_list = [f"""{table_name_prefix}_{tbl.strip().strip("'").strip('"')}"""
                                        for tbl in args['rds_exclude_db_tbls'].split(",")]
            LOGGER.warn(f"""Given list of tables being exluded:\n{exclude_rds_db_tbls_list}""")
        # -------------------------------------------------------

        filtered_rds_sqlserver_db_tbl_list = [tbl for tbl in rds_sqlserver_db_tbl_list
                                              if tbl not in exclude_rds_db_tbls_list]
        # -------------------------------------------------------

        if not filtered_rds_sqlserver_db_tbl_list:
            LOGGER.error(
                f"""filtered_rds_sqlserver_db_tbl_list - is empty. Exiting ...!""")
            sys.exit(1)
        else:
            LOGGER.info(
                f"""List of tables to be processed: {filtered_rds_sqlserver_db_tbl_list}""")
        # -------------------------------------------------------

        for db_sch_tbl in filtered_rds_sqlserver_db_tbl_list:
            rds_db_name, rds_tbl_name = db_sch_tbl.split(f"_{given_rds_sqlserver_db_schema}_")[0], \
                                        db_sch_tbl.split(f"_{given_rds_sqlserver_db_schema}_")[1]

            total_files, total_size = get_s3_folder_info(PRQ_FILES_SRC_S3_BUCKET_NAME, 
                                                         f"{rds_db_name}/{given_rds_sqlserver_db_schema}/{rds_tbl_name}")
            total_size_mb = total_size/1024/1024

            dv_ctlg_tbl_partition_path = f'''
                {GLUE_CATALOG_DB_NAME}/{GLUE_CATALOG_TBL_NAME}/database_name={rds_db_name}/full_table_name={db_sch_tbl}/'''.strip()
            # -------------------------------------------------------

            if check_s3_folder_path_if_exists(PARQUET_OUTPUT_S3_BUCKET_NAME, dv_ctlg_tbl_partition_path):
                LOGGER.info(
                    f"""Already exists, 
                    Skipping --> {CATALOG_TABLE_S3_FULL_PATH}/database_name={rds_db_name}/full_table_name={db_sch_tbl}""")
                continue

            elif total_size_mb > int(args["max_table_size_mb"]):
                LOGGER.info(
                    f"""Size greaterthan {args["max_table_size_mb"]}MB ({total_size_mb}MB), 
                    Skipping --> {CATALOG_TABLE_S3_FULL_PATH}/database_name={rds_db_name}/full_table_name={db_sch_tbl}""")
                continue
            # -------------------------------------------------------

            df_dv_output = process_dv_for_table(rds_db_name, 
                                                rds_tbl_name, 
                                                total_files, 
                                                total_size_mb)

            write_parquet_to_s3(df_dv_output, rds_db_name, db_sch_tbl)

    else:
        given_rds_sqlserver_tbls_str = args["rds_select_db_tbls"]

        LOGGER.info(f"""Given specific tables: {given_rds_sqlserver_tbls_str}, {type(given_rds_sqlserver_tbls_str)}""")

        table_name_prefix = f"""{args['rds_sqlserver_db']}_{given_rds_sqlserver_db_schema}"""
        given_rds_sqlserver_tbls_list = [f"""{table_name_prefix}_{tbl.strip().strip("'").strip('"')}"""
                                         for tbl in given_rds_sqlserver_tbls_str.split(",")]

        LOGGER.info(f"""Given specific tables list: {given_rds_sqlserver_tbls_list}, {type(given_rds_sqlserver_tbls_list)}""")

        # ---------------------------------------------------------------------------

        selected_tables_not_found_list = [tbl for tbl in given_rds_sqlserver_tbls_list 
                                          if tbl not in rds_sqlserver_db_tbl_list]
        if selected_tables_not_found_list:
            LOGGER.error(f"""{selected_tables_not_found_list} - NOT FOUND ! Exiting ...""")
            sys.exit(1)
        # ---------------------------------------------------------------------------
        
        filtered_rds_sqlserver_db_tbl_list = [tbl for tbl in given_rds_sqlserver_tbls_list 
                                              if tbl in rds_sqlserver_db_tbl_list]
        LOGGER.info(f"""List of tables to be processed: {filtered_rds_sqlserver_db_tbl_list}""")

        for db_sch_tbl in filtered_rds_sqlserver_db_tbl_list:
            rds_db_name, rds_tbl_name = db_sch_tbl.split(f"_{given_rds_sqlserver_db_schema}_")[0], \
                                        db_sch_tbl.split(f"_{given_rds_sqlserver_db_schema}_")[1]

            total_files, total_size = get_s3_folder_info(PRQ_FILES_SRC_S3_BUCKET_NAME, 
                                                         f"{rds_db_name}/{given_rds_sqlserver_db_schema}/{rds_tbl_name}")
            total_size_mb = total_size/1024/1024
            # -------------------------------------------------------

            if total_size_mb > int(args["max_table_size_mb"]):
                LOGGER.warn(f""">> Size greaterthan {args["max_table_size_mb"]}MB ({total_size_mb}MB) <<""")
            # -------------------------------------------------------

            df_dv_output = process_dv_for_table(rds_db_name, 
                                                rds_tbl_name, 
                                                total_files, 
                                                total_size_mb)

            write_parquet_to_s3(df_dv_output, rds_db_name, db_sch_tbl)
    # -------------------------------------------------------

    job.commit()
