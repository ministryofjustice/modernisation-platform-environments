import sys
import boto3
# from logging import getLogger
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
                       "parquet_src_bucket_name",
                       "parquet_output_bucket_name",
                       "glue_catalog_db_name",
                       "glue_catalog_tbl_name",
                       "rds_sqlserver_db",
                       "rds_sqlserver_db_schema",
                       "rds_sqlserver_db_table",
                       "rds_db_tbl_primary_key_list",
                       "rds_df_trim_str_col_list",
                       "repartition_factor"
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

RDS_DB_HOST_ENDPOINT = args["rds_db_host_ep"]
RDS_DB_PORT = 1433
RDS_DB_INSTANCE_USER = "admin"
RDS_DB_INSTANCE_PWD = args["rds_db_pwd"]
RDS_DB_INSTANCE_DRIVER = "com.microsoft.sqlserver.jdbc.SQLServerDriver"

PRQ_FILES_SRC_S3_BUCKET_NAME = args["parquet_src_bucket_name"]

PARQUET_OUTPUT_S3_BUCKET_NAME = args["parquet_output_bucket_name"]

GLUE_CATALOG_DB_NAME = args["glue_catalog_db_name"]
GLUE_CATALOG_TBL_NAME = args["glue_catalog_tbl_name"]

CATALOG_TABLE_S3_FULL_PATH = f'''s3://{PARQUET_OUTPUT_S3_BUCKET_NAME}/{GLUE_CATALOG_DB_NAME}/{GLUE_CATALOG_TBL_NAME}'''

NVL_DTYPE_DICT = {
    'tinyint': 0, 'smallint': 0, 'int': 0, 'bigint':0,
    'double': 0, 'float': 0, 'string': "''", 'boolean': False,
    'timestamp': "to_timestamp('1900-01-01', 'yyyy-MM-dd')", 
    'date': "to_date('1900-01-01', 'yyyy-MM-dd')"}

"""
# Use the below query to fetch the existing primary keys defined in RDS-DB-Schema.
# -------------------------------------------------------------------------------------
SELECT TC.TABLE_CATALOG, TC.TABLE_SCHEMA, TC.TABLE_NAME, COLUMN_NAME
       -- , TC.CONSTRAINT_NAME
  FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS TC
       INNER JOIN INFORMATION_SCHEMA.KEY_COLUMN_USAGE KCU
    ON TC.CONSTRAINT_NAME = KCU.CONSTRAINT_NAME 
 WHERE CONSTRAINT_TYPE = 'PRIMARY KEY' 
   AND TC.TABLE_NAME LIKE 'F_%'
--  ORDER BY TABLE_CATALOG, TABLE_SCHEMA, TABLE_NAME
;
"""
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
    return [row[0] for row in df_rds_sys.collect()][0]


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

    rds_db_tbl_temp_list = rds_db_tbl_temp_list + [row[0] for row in df_rds_sqlserver_db_tbls.collect()]

    return rds_db_tbl_temp_list


def get_rds_dataframe(in_rds_db_name, in_table_name) -> DataFrame:
    return spark.read.jdbc(url=get_rds_db_jdbc_url(in_rds_db_name),
                           table=in_table_name,
                           properties={"user": RDS_DB_INSTANCE_USER,
                                       "password": RDS_DB_INSTANCE_PWD,
                                       "driver": RDS_DB_INSTANCE_DRIVER})


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


def trim_rds_df_str_columns(in_rds_df: DataFrame) -> DataFrame:
    return (in_rds_df.select(
            *[F.trim(F.col(c[0])).alias(c[0]) if c[1] == 'string' else F.col(c[0])
              for c in in_rds_df.dtypes])
            )


def strip_rds_tbl_col_chars(in_rds_df: DataFrame, 
                            in_transformed_colmn_list_1, 
                            replace_substring) -> DataFrame:
    count = 0
    for transform_colmn in in_transformed_colmn_list_1:
        if count == 0:
            rds_df = in_rds_df.withColumn(transform_colmn, 
                                          F.regexp_replace(in_rds_df[transform_colmn], replace_substring, ""))
            count += 1
        else:
            rds_df = rds_df.withColumn(transform_colmn, 
                                       F.regexp_replace(in_rds_df[transform_colmn], replace_substring, ""))
    return rds_df


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

def get_pyspark_empty_df(in_empty_df_schema) -> DataFrame:
    return spark.createDataFrame(sc.emptyRDD(), schema=in_empty_df_schema)

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
        LOGGER.error(f"{tbl_full_dir_path_str} -- Table-Folder-S3-Path Not Found !")
        sys.exit(1)


def get_s3_parquet_df_v1(in_s3_parquet_folder_path, in_rds_df_schema) -> DataFrame:
    return spark.createDataFrame(spark.read.parquet(in_s3_parquet_folder_path).rdd, in_rds_df_schema)

def get_s3_parquet_df_v2(in_s3_parquet_folder_path, in_rds_df_schema) -> DataFrame:
    return spark.read.schema(in_rds_df_schema).parquet(in_s3_parquet_folder_path)

def get_s3_parquet_df_v3(in_s3_parquet_folder_path, in_rds_df_schema) -> DataFrame:
    return spark.read.format("parquet").load(in_s3_parquet_folder_path, schema=in_rds_df_schema)

def get_altered_df_schema_object(in_df_rds: DataFrame, in_transformed_column_list):
    altered_schema_object = T.StructType([])
    rds_df_column_list = in_df_rds.schema.fields

    for colmn in in_transformed_column_list:
        if colmn not in rds_df_column_list:
            LOGGER.error(f"""Given transformed column '{colmn}' is not an existing RDS-DB-Table-Column! Exiting ...""")
            sys.exit(1)

    for field_obj in in_df_rds.schema.fields:
        if field_obj.name not in in_transformed_column_list:
            altered_schema_object.add(field_obj)
    else:
        for field_obj in in_df_rds.schema.fields:
            if field_obj.name in in_transformed_column_list:
                altered_schema_object.add(field_obj)
    return altered_schema_object

# ===================================================================================================


def process_dv_for_table(rds_db_name, db_sch_tbl, total_files, total_size_mb, input_repartition_factor) -> DataFrame:
    
    rds_tbl_name = db_sch_tbl.split(f"_{args['rds_sqlserver_db_schema']}_")[1]
    default_repartition_factor = input_repartition_factor if total_files <= 1 \
        else total_files * input_repartition_factor

    df_dv_output_schema = T.StructType(
        [T.StructField("run_datetime", T.TimestampType(), True),
         T.StructField("json_row", T.StringType(), True),
         T.StructField("validation_msg", T.StringType(), True),
         T.StructField("database_name", T.StringType(), True),
         T.StructField("full_table_name", T.StringType(), True),
         T.StructField("table_in_ap", T.StringType(), True)])

    df_dv_output = get_pyspark_empty_df(df_dv_output_schema)

    additional_validation_msg = ''
    
    final_validation_msg = f"""{rds_db_name}.{rds_tbl_name} -- Validation Completed."""

    given_rds_sqlserver_db_schema = args["rds_sqlserver_db_schema"]

    tbl_prq_s3_folder_path = get_s3_table_folder_path(rds_db_name, rds_tbl_name)
    # -------------------------------------------------------
    if tbl_prq_s3_folder_path is not None:

        df_rds = get_rds_dataframe(rds_db_name, rds_tbl_name).repartition(default_repartition_factor)
        rds_df_created_msg_1 = f"""RDS-Read-dataframe['{rds_db_name}.{given_rds_sqlserver_db_schema}.{rds_tbl_name}']"""
        rds_df_created_msg_2 = f""" >> rds_read_df_partitions = {df_rds.rdd.getNumPartitions()}"""
        LOGGER.info(f"""{rds_df_created_msg_1}\n{rds_df_created_msg_2}""")
        
        df_prq = get_s3_parquet_df_v2(tbl_prq_s3_folder_path, df_rds.schema).repartition(default_repartition_factor)
        prq_df_created_msg_1 = f"""S3-Folder-Parquet-Read-['{rds_db_name}/{given_rds_sqlserver_db_schema}/{rds_tbl_name}'] - {total_size_mb}MB"""
        prq_df_created_msg_2 = f""" >> parquet_read_df_partitions = {df_prq.rdd.getNumPartitions()}"""
        LOGGER.info(f"""{prq_df_created_msg_1}\n{prq_df_created_msg_2}""")

        df_rds_count = df_rds.count
        df_prq_count = df_prq.count
        # -------------------------------------------------------
        if not (df_rds_count == df_prq_count):
            validation_msg = f"""'{rds_tbl_name} - Table row-count {df_rds_count}:{df_prq_count} MISMATCHED !' as validation_msg"""
            df_dv_temp = df_dv_output.selectExpr("current_timestamp as run_datetime",
                                                 "'' as json_row",
                                                 validation_msg,
                                                 f"""'{rds_db_name}' as database_name""",
                                                 f"""'{db_sch_tbl}' as full_table_name""",
                                                 """'False' as table_in_ap"""
                                                 )
            LOGGER.warn(f"Validation Failed - 3")
            df_dv_output = df_dv_output.union(df_dv_temp)

            LOGGER.info(final_validation_msg)
            return df_dv_output
        # -------------------------------------------------------

        if args.get('rds_db_tbl_primary_key_list', None) is None:
            rds_db_tbl_primary_key_list = [column.strip() for column in RECORDED_PKEYS_LIST[rds_tbl_name]]
        else:
            rds_db_tbl_primary_key_list = [f"""{column.strip().strip("'").strip('"')}""" 
                                           for column in args['rds_db_tbl_primary_key_list'].split(",")]
        # -------------------------------------------------------

        if not rds_db_tbl_primary_key_list:
            LOGGER.error(f"""rds_db_tbl_primary_key_list - value(s) not given! Exiting ...""")
            sys.exit(1)
        # -------------------------------------------------------

        rds_df_trim_str_col_list = [f"""{column.strip().strip("'").strip('"')}""" 
                                    for column in args.get('rds_df_trim_str_col_list', '').split(",")]
        
        trim_col_msg = f"""Given -> trim_rds_df_str_columns = {args["trim_rds_df_str_columns"]}, 
                        {type(args["trim_rds_df_str_columns"])}""".strip()
        
        validated_colmn_msg_list = list()

        for_loop_count = 0
        for rds_column in df_rds.columns:
            for_loop_count += 1
            if rds_column in rds_db_tbl_primary_key_list:
                continue

            temp_select_list = list()
            temp_select_list = temp_select_list+rds_db_tbl_primary_key_list
            temp_select_list.append(rds_column)
            
            LOGGER.info(f"""{for_loop_count}-Processing - {rds_tbl_name}.{rds_column}.""")
            LOGGER.info(f"""Using 'select' column list: {temp_select_list}""")

            df_rds_temp = df_rds.select(*temp_select_list)

            # -------------------------------------------------------
            
            if rds_column in rds_df_trim_str_col_list:
                LOGGER.info(trim_col_msg)
                    
                df_rds_temp_t1 = df_rds_temp.transform(trim_rds_df_str_columns)
                additional_validation_msg = " - [After trimming string-column spaces]"
                df_rds_temp_t2 = df_rds_temp_t1.selectExpr(*get_nvl_select_list(df_rds_temp, rds_db_name, rds_tbl_name))
            else:
                df_rds_temp_t2 = df_rds_temp.selectExpr(*get_nvl_select_list(df_rds_temp, rds_db_name, rds_tbl_name))
            # -------------------------------------------------------

            df_prq_temp = df_prq.select(*temp_select_list)            

            df_prq_temp_t1 = df_prq_temp.selectExpr(*get_nvl_select_list(df_rds_temp, rds_db_name, rds_tbl_name))

            # -------------------------------------------------------

            df_rds_prq_subtract_transform = df_rds_temp_t2.subtract(df_prq_temp_t1).cache()
            df_rds_prq_subtract_row_count = df_rds_prq_subtract_transform.count()

            # -------------------------------------------------------
            if df_rds_prq_subtract_row_count == 0:
                validated_colmn_msg_list.append(f"""'{rds_column}'{additional_validation_msg}""")

            else:
                df_temp = (df_rds_prq_subtract_transform
                           .withColumn('json_row', F.to_json(F.struct(*[F.col(c) for c in df_rds_temp.columns])))
                           .selectExpr("json_row")
                           .limit(5))

                validation_msg = f""" "'{rds_tbl_name}.{rds_column}' - dataframe-subtract-op ->> {df_rds_prq_subtract_row_count} row-count !" as validation_msg"""
                df_temp = df_temp.selectExpr("current_timestamp as run_datetime",
                                             "json_row",
                                             validation_msg,
                                             f"""'{rds_db_name}' as database_name""",
                                             f"""'{db_sch_tbl}' as full_table_name""",
                                             """'False' as table_in_ap"""
                                             )
                LOGGER.warn(f"Validation Failed - 2")
                df_dv_output = df_dv_output.union(df_temp)
            # -------------------------------------------------------

            df_rds_prq_subtract_transform.unpersist(True)

            if validated_colmn_msg_list:
                total_non_primary_key_columns = len(df_rds_temp.columns) - len(rds_db_tbl_primary_key_list)
                if total_non_primary_key_columns == len(validated_colmn_msg_list):
                    df_temp = df_dv_output.selectExpr("current_timestamp as run_datetime",
                                                  "'' as json_row",
                                                  f"""'{rds_tbl_name} - Validated.{additional_validation_msg}' as validation_msg""",
                                                  f"""'{rds_db_name}' as database_name""",
                                                  f"""'{db_sch_tbl}' as full_table_name""",
                                                  """'False' as table_to_ap"""
                                                  )
                    LOGGER.info(f"Validation Successful - 1")
                    df_dv_output = df_dv_output.union(df_temp)
                else:
                    df_temp = df_dv_output.selectExpr("current_timestamp as run_datetime",
                                                  "'' as json_row",
                                                  f"""{',chr(10)'.join(e for e in validated_colmn_msg_list)} - Validated""",
                                                  f"""'{rds_db_name}' as database_name""",
                                                  f"""'{db_sch_tbl}' as full_table_name""",
                                                  """'False' as table_in_ap"""
                                                  )
                    LOGGER.info(f"Not all table columns validated - 1b")
                    df_dv_output = df_dv_output.union(df_temp)

    else:

        df_temp = df_dv_output.selectExpr("current_timestamp as run_datetime",
                                          "'' as json_row",
                                          f"""'{db_sch_tbl} - S3-Parquet folder path does not exist !' as validation_msg""",
                                          f"""'{rds_db_name}' as database_name""",
                                          f"""'{db_sch_tbl}' as full_table_name""",
                                          """'False' as table_in_ap"""
                                          )
        LOGGER.warn(f"Validation not applicable - 4")
        df_dv_output = df_dv_output.union(df_temp)
    # -------------------------------------------------------

    LOGGER.info(final_validation_msg)

    return df_dv_output


def write_parquet_to_s3(df_dv_output: DataFrame, database, db_sch_tbl_name):

    df_dv_output = df_dv_output.orderBy("database_name", "full_table_name").repartition(1)

    if check_s3_folder_path_if_exists(PARQUET_OUTPUT_S3_BUCKET_NAME,
                                      f'''{GLUE_CATALOG_DB_NAME}/{GLUE_CATALOG_TBL_NAME}/database_name={database}/full_table_name={db_sch_tbl_name}'''
                                      ):
        LOGGER.info(f"""Purging S3-path: {CATALOG_TABLE_S3_FULL_PATH}/database_name={database}/full_table_name={db_sch_tbl_name}""")

        glueContext.purge_s3_path(f"""{CATALOG_TABLE_S3_FULL_PATH}/database_name={database}/full_table_name={db_sch_tbl_name}""",
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
    LOGGER.info(f"""{db_sch_tbl_name} validation report written to -> {CATALOG_TABLE_S3_FULL_PATH}/""")

# ===================================================================================================


if __name__ == "__main__":

    LOGGER.info(f"""Given database(s): {args.get("rds_sqlserver_db", None)}""")
    rds_sqlserver_db_str = check_if_rds_db_exists(args.get("rds_sqlserver_db", None))
    LOGGER.info(f"""Using database(s): {rds_sqlserver_db_str}""")
    
    given_rds_sqlserver_db_schema = args["rds_sqlserver_db_schema"]
    LOGGER.info(f"""Given rds_sqlserver_db_schema = {given_rds_sqlserver_db_schema}""")

    rds_sqlserver_db_tbl_list = get_rds_db_tbl_list(rds_sqlserver_db_str)
    LOGGER.info(f"""Total List of tables existing: {rds_sqlserver_db_str}.{given_rds_sqlserver_db_schema}\n{rds_sqlserver_db_tbl_list}""")

    # -------------------------------------------------------
    if args.get("rds_sqlserver_db_table", None) is None:
        LOGGER.error(f"""'rds_sqlserver_db_table' runtime input is missing! Exiting ...""")
        sys.exit(1)

    given_rds_sqlserver_table = args["rds_sqlserver_db_table"]
    db_sch_tbl = f"""{rds_sqlserver_db_str}_{given_rds_sqlserver_db_schema}_{given_rds_sqlserver_table}"""
    if not rds_sqlserver_db_tbl_list:
        LOGGER.error(f"""rds_sqlserver_db_tbl_list - is empty! Exiting ...""")
        sys.exit(1)
    elif db_sch_tbl not in rds_sqlserver_db_tbl_list:
        LOGGER.error(f"""'{db_sch_tbl}' - is not an existing table! Exiting ...""")
        sys.exit(1)
    # -------------------------------------------------------

    LOGGER.info(f"""Given RDS-database table: {given_rds_sqlserver_table}, {type(given_rds_sqlserver_table)}""")

    total_files, total_size = get_s3_folder_info(PRQ_FILES_SRC_S3_BUCKET_NAME, 
                                                 f"{rds_sqlserver_db_str}/{given_rds_sqlserver_db_schema}/{given_rds_sqlserver_table}")
    total_size_mb = total_size/1024/1024

    # -------------------------------------------------------
    LOGGER.warn(f""">> '{db_sch_tbl}' Size: {total_size_mb} MB <<""")
    # -------------------------------------------------------

    input_repartition_factor = int(args["repartition_factor"])

    df_dv_output = process_dv_for_table(rds_sqlserver_db_str, 
                                        db_sch_tbl, 
                                        total_files, 
                                        total_size_mb, 
                                        input_repartition_factor)

    write_parquet_to_s3(df_dv_output, rds_sqlserver_db_str, f"'{db_sch_tbl}'")

    job.commit()
