
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

# NOTES-1:> If non-integer datatype or more than one value provided to 'rds_db_tbl_pkeys_col_list', the job fails.
# NOTES-2:> 'parallel_jdbc_conn_num' value to be given is to be aligned with number of workers & executors.
# NOTES-3:> 'rds_upperbound_factor' used to evaluate the number of rows to be processed for each rds-batch-read iteration.
# NOTES-4:> PARQUET-READ-DATAFRAME partitions controlloed by the setting >> 'spark.sql.files.maxPartitionBytes=1g'
# NOTES-5:> RDS-DB-READ-DATAFRAME partitions controlloed by the input >> 'parallel_jdbc_conn_num'
# MANDATORY INPUTS: 'rds_db_tbl_pkeys_col_list', 'parquet_df_repartition_num'
# DEFAULT INPUTS: {'rds_df_repartition_num': 0}, {'parallel_jdbc_conn_num': 4}

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
                       "parquet_df_repartition_num",
                       "parallel_jdbc_conn_num",
                       "rds_sqlserver_db",
                       "rds_sqlserver_db_schema",
                       "rds_sqlserver_db_table",
                       "rds_db_tbl_pkeys_col_list",
                       "rds_upperbound_factor",
                       "rds_df_repartition_num",
                       "rds_df_trim_str_columns"
                       ]

OPTIONAL_INPUTS = [
    "rds_df_trim_micro_sec_ts_col_list"
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

PRQ_FILES_SRC_S3_BUCKET_NAME = args["parquet_src_bucket_name"]

PARQUET_OUTPUT_S3_BUCKET_NAME = args["parquet_output_bucket_name"]

GLUE_CATALOG_DB_NAME = args["glue_catalog_db_name"]
GLUE_CATALOG_TBL_NAME = args["glue_catalog_tbl_name"]

CATALOG_DB_TABLE_PATH = f"""{GLUE_CATALOG_DB_NAME}/{GLUE_CATALOG_TBL_NAME}"""
CATALOG_TABLE_S3_FULL_PATH = f'''s3://{PARQUET_OUTPUT_S3_BUCKET_NAME}/{CATALOG_DB_TABLE_PATH}'''

NVL_DTYPE_DICT = Logical_Constants.NVL_DTYPE_DICT

INT_DATATYPES_LIST = Logical_Constants.INT_DATATYPES_LIST

RECORDED_PKEYS_LIST = Logical_Constants.RECORDED_PKEYS_LIST

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

# ===============================================================================

def exclude_rds_matched_rows_from_parquet_df(df_prq_read_t2: DataFrame, 
                                             df_rds_temp_t4: DataFrame
                                             ) -> DataFrame:
    return df_prq_read_t2.alias("L").join(
                                        df_rds_temp_t4.alias("R"), 
                                        on=df_rds_temp_t4.columns, 
                                        how='leftanti'
                                    )


def apply_rds_transforms(df_rds_temp: DataFrame,
                         rds_jdbc_conn_obj, 
                         rds_tbl_name) -> DataFrame:
    trim_str_msg = ""

    t1_rds_str_col_trimmed = False
    if args.get("rds_df_trim_str_columns", "false") == "true":

        LOGGER.info(f"""Given -> rds_df_trim_str_columns = 'true'""")
        LOGGER.warn(f""">> Stripping string column spaces <<""")

        df_rds_temp_t1 = df_rds_temp.transform(CustomPysparkMethods.rds_df_trim_str_columns)

        trim_str_msg = f""" [str column(s) - extra spaces trimmed]"""
        t1_rds_str_col_trimmed = True
    # -------------------------------------------------------

    trim_ts_ms_msg = ""

    t2_rds_ts_col_msec_trimmed = False
    if args.get('rds_df_trim_micro_sec_ts_col_list', None) is not None:

        given_rds_df_trim_ms_ts_cols_str = args['rds_df_trim_micro_sec_ts_col_list']
        given_rds_df_trim_ms_ts_cols_list = [f"""{col.strip().strip("'").strip('"')}"""
                                            for col in given_rds_df_trim_ms_ts_cols_str.split(",")]

        trim_msg_prefix = f"""Given -> rds_df_trim_micro_sec_ts_col_list = {given_rds_df_trim_ms_ts_cols_list}"""
        LOGGER.warn(f"""{trim_msg_prefix}, {type(given_rds_df_trim_ms_ts_cols_list)}""")
        trim_ts_ms_msg = f"""; [timestamp column(s) - micro-seconds trimmed]"""

        if t1_rds_str_col_trimmed is True:
            df_rds_temp_t2 = df_rds_temp_t1.transform(
                                CustomPysparkMethods.rds_df_trim_microseconds_timestamp, 
                                given_rds_df_trim_ms_ts_cols_list)
        else:
            df_rds_temp_t2 = df_rds_temp.transform(
                                CustomPysparkMethods.rds_df_trim_microseconds_timestamp, 
                                given_rds_df_trim_ms_ts_cols_list)
        # -------------------------------------------------------

        t2_rds_ts_col_msec_trimmed = True
    # -------------------------------------------------------

    if t2_rds_ts_col_msec_trimmed:
        df_rds_temp_t3 = df_rds_temp_t2.selectExpr(
                            *CustomPysparkMethods.get_nvl_select_list(df_rds_temp, 
                                                                      rds_jdbc_conn_obj, 
                                                                      rds_tbl_name)
                        )
    elif t1_rds_str_col_trimmed:
        df_rds_temp_t3 = df_rds_temp_t1.selectExpr(
                            *CustomPysparkMethods.get_nvl_select_list(df_rds_temp, 
                                                                      rds_jdbc_conn_obj, 
                                                                      rds_tbl_name)
                        )
    else:
        df_rds_temp_t3 = df_rds_temp.selectExpr(
                            *CustomPysparkMethods.get_nvl_select_list(df_rds_temp, 
                                                                      rds_jdbc_conn_obj, 
                                                                      rds_tbl_name))
    # -------------------------------------------------------

    return df_rds_temp_t3, trim_str_msg, trim_ts_ms_msg


def process_dv_for_table(rds_jdbc_conn_obj, 
                         db_sch_tbl) -> DataFrame:
    given_rds_sqlserver_db_schema = args['rds_sqlserver_db_schema']

    rds_tbl_name = db_sch_tbl.split(f"_{given_rds_sqlserver_db_schema}_")[1]
    qualified_tbl_name = f"""{rds_db_name}.{given_rds_sqlserver_db_schema}.{rds_tbl_name}"""
    final_validation_msg = f"""{qualified_tbl_name} -- Validation Completed."""

    df_dv_output_schema = T.StructType(
        [T.StructField("run_datetime", T.TimestampType(), True),
         T.StructField("json_row", T.StringType(), True),
         T.StructField("validation_msg", T.StringType(), True),
         T.StructField("database_name", T.StringType(), True),
         T.StructField("full_table_name", T.StringType(), True),
         T.StructField("table_to_ap", T.StringType(), True)])
    
    df_dv_output = CustomPysparkMethods.get_pyspark_empty_df(df_dv_output_schema)

    tbl_prq_s3_folder_path = CustomPysparkMethods.get_s3_table_folder_path(
                                rds_jdbc_conn_obj, 
                                PRQ_FILES_SRC_S3_BUCKET_NAME,
                                rds_tbl_name
                            )
    LOGGER.info(f"""tbl_prq_s3_folder_path = {tbl_prq_s3_folder_path}""")
    # -------------------------------------------------------

    # VERIFY IF DMS-PARQUET-OUTPUT IS AVAILABLE. 
    if tbl_prq_s3_folder_path is not None:
        # -------------------------------------------------------
        # VERIFY IF SOURCE-TABLE-PRIMARY-KEY IS GIVEN.
        # IF NOT, TRY PULLING THE SAME INFO FROM THE PRE-DEFINED PYTHON DICT.
        if args.get('rds_db_tbl_pkeys_col_list', None) is None:
            try:
                rds_db_tbl_pkeys_col_list = [column.strip() 
                                             for column in RECORDED_PKEYS_LIST[rds_tbl_name]]
            except Exception as e:
                LOGGER.error(f"""Runtime Parameter 'rds_db_tbl_pkeys_col_list' - value(s) not given!""")
                LOGGER.error(f"""Global Dictionary - 'RECORDED_PKEYS_LIST' has no key '{rds_tbl_name}'!""")
                sys.exit(1)
        else:
            rds_db_tbl_pkeys_col_list = [f"""{column.strip().strip("'").strip('"')}""" 
                                         for column in args['rds_db_tbl_pkeys_col_list'].split(",")]
            LOGGER.info(f"""rds_db_tbl_pkeys_col_list = {rds_db_tbl_pkeys_col_list}""")
        # -------------------------------------------------------

        rds_db_table_empty_df = rds_jdbc_conn_obj.get_rds_db_table_empty_df(rds_tbl_name)
        # df_rds_columns_list = rds_db_table_empty_df.columns
        
        df_rds_dtype_dict = CustomPysparkMethods.get_dtypes_dict(rds_db_table_empty_df)
        int_dtypes_colname_list = [colname for colname, dtype in df_rds_dtype_dict.items() 
                                   if dtype in INT_DATATYPES_LIST]

        if len(rds_db_tbl_pkeys_col_list) == 1 and \
            (rds_db_tbl_pkeys_col_list[0] in int_dtypes_colname_list):

            jdbc_partition_column = rds_db_tbl_pkeys_col_list[0]
            pkey_max_value = rds_jdbc_conn_obj.get_rds_db_tbl_pkey_col_max_value(
                                rds_tbl_name, 
                                jdbc_partition_column
                            )
            LOGGER.info(f"""pkey_max_value = {pkey_max_value}""")
        else:
            LOGGER.error(f"""int_dtypes_colname_list = {int_dtypes_colname_list}""")
            LOGGER.error(f"""PrimaryKey column(s) are more than one (OR) not an integer datatype column!""")
            sys.exit(1)
        # -------------------------------------------------------

        # EVALUATE RDS-DATAFRAME ROW-COUNT
        df_rds_count = rds_jdbc_conn_obj.get_rds_db_table_row_count(
                                            rds_tbl_name, 
                                            rds_db_tbl_pkeys_col_list
                        )
        
        # BUILD DATAFRAME-SCHEMA-OBJECT EXCLUDING NON-PRIMARY-KEY FIELDS
        prq_pk_schema = CustomPysparkMethods.get_rds_db_tbl_customized_cols_schema_object(
                            rds_db_table_empty_df, 
                            rds_db_tbl_pkeys_col_list
                        )
        
        # EVALUATE PARQUET-DATAFRAME ROW-COUNT
        df_prq_count = CustomPysparkMethods.get_s3_parquet_df_v2(
                            tbl_prq_s3_folder_path, 
                            prq_pk_schema).count()

        # IF ROW-COUNT MATCHING BETWEEN THE RDS AND PARQUET SOURCES THEN CONTINUE
        # ELSE EXIT THE PROGRAM GRACEFULLY WITH RELEVANT MESSAGE LOGGED INTO OUTPUT DATAFRAME.
        if not (df_rds_count == df_prq_count):
            mismatch_validation_msg_1 = "MISMATCHED Dataframe(s) Row Count!"
            mismatch_validation_msg_2 = f"""'{rds_tbl_name} - {df_rds_count}:{df_prq_count} {mismatch_validation_msg_1}'"""
            LOGGER.warn(f"df_rds_row_count={df_rds_count} ; df_prq_row_count={df_prq_count} ; {mismatch_validation_msg_1}")
            df_temp_row = spark.sql(f"""select
                                        current_timestamp as run_datetime,
                                        '' as json_row,
                                        '{mismatch_validation_msg_2}' as validation_msg,
                                        '{rds_db_name}' as database_name,
                                        '{db_sch_tbl}' as full_table_name,
                                        'False' as table_to_ap
                                    """.strip())
            
            df_dv_output = df_dv_output.union(df_temp_row)

            LOGGER.warn(f"{rds_tbl_name}: Validation Failed - 3")
            LOGGER.info(final_validation_msg)
            return df_dv_output
        else:
            LOGGER.info(f"""df_rds_count = df_prq_count = {df_rds_count}""")
        # -------------------------------------------------------

        # CREATE PARQUET-DATAFRAME USING RDS-DATAFRAME-SCHEMA.
        df_prq_full_read = CustomPysparkMethods.get_s3_parquet_df_v2(
                                tbl_prq_s3_folder_path, 
                                rds_db_table_empty_df.schema
                            )
        msg_prefix = f"""
        df_prq_full_read-{rds_tbl_name}: READ PARTITIONS = {df_prq_full_read.rdd.getNumPartitions()}
        """.strip()
        LOGGER.info(msg_prefix)

        # APPLY TRANSFORMATIONS-1 ON PARQUET-DATAFRAME TO HANDLE NULL VALUES
        df_prq_read_t1 = df_prq_full_read.selectExpr(
                            *CustomPysparkMethods.get_nvl_select_list(
                                rds_db_table_empty_df, 
                                rds_jdbc_conn_obj, 
                                rds_tbl_name)
                        )

        # APPLY REPARTITIONING ON PARQUET-DATAFRAME TO UNIFORMLY DISTRIBUTE DATA
        parquet_df_repartition_num = int(args['parquet_df_repartition_num'])

        msg_prefix = f"""df_prq_read_t1-{rds_tbl_name}"""
        LOGGER.info(f"""{msg_prefix}: >> RE-PARTITIONING on {jdbc_partition_column} <<""")
        df_prq_read_t2 = df_prq_read_t1.repartition(parquet_df_repartition_num, 
                                                    jdbc_partition_column)
        
        msg_prefix = f"""df_prq_read_t2-{rds_tbl_name}"""
        LOGGER.info(f"""{msg_prefix}: PARQUET-DF-Partitions = {df_prq_read_t2.rdd.getNumPartitions()}""")
        
        # CACHE PARQUET-DATAFRAME TO RETAIN THE DAG STATE
        df_prq_read_t2 = df_prq_read_t2.cache()
        LOGGER.info(f"""{msg_prefix} Dataframe Cached into memory.""")

        # -------------------------------------------------------

        # EVALUATE THE ROW-COUNT FOR EACH BATCH OF RDS-JDBC-READ ITERATION
        rds_rows_per_batch = int(df_rds_count/int(args['rds_upperbound_factor']))
        LOGGER.info(f"""rds_rows_per_batch = {rds_rows_per_batch}""")

        # -------------------------------------------------------

        # PREPARE LOGICAL VARIABLE(S) DECLARATION IN THE FOLLOWING WHILE-LOOP
        rds_df_repartition_num = int(args['rds_df_repartition_num'])

        rds_rows_read_count = 0
        total_rds_rows_fetched = 0
        cumulative_matched_rows = 0
        jdbc_partition_col_upperbound = 0
        additional_msg = ''

        # WHILE-LOOP TO READ & TRANSFORM RDS-DATAFRAME AND
        # EVALUATE REQUIRED STATS FROM COMPARING WITH THE CACHED PARQUET-DATAFRAME
        loop_count = 0
        while (jdbc_partition_col_upperbound+rds_rows_per_batch) <= pkey_max_value:
            loop_count += 1

            # EVALUATE LOWER & UPPER BOUND VALUES OF PARTITION / PRIMARY KEY COLUMN
            jdbc_partition_col_lowerbound = 0 if jdbc_partition_col_upperbound == 0 \
                                                else jdbc_partition_col_upperbound+1
            msg_prefix = f"""jdbc_partition_col_lowerbound = {jdbc_partition_col_lowerbound}"""
            LOGGER.info(f"""{loop_count}-{msg_prefix}""")

            jdbc_partition_col_upperbound = jdbc_partition_col_lowerbound + rds_rows_per_batch
            msg_prefix = f"""jdbc_partition_col_upperbound = {jdbc_partition_col_upperbound}"""
            LOGGER.info(f"""{loop_count}-{msg_prefix}""")
            

            # READ RDS-DATAFRAME (PARALLEL JDBC CONNECTIONS)
            df_rds_temp = rds_jdbc_conn_obj.get_df_read_rds_db_tbl_pkey_between(
                                                rds_tbl_name, 
                                                jdbc_partition_column,
                                                jdbc_partition_col_lowerbound,
                                                jdbc_partition_col_upperbound,
                                                int(args['parallel_jdbc_conn_num'])
                            )
            msg_prefix = f"""READ PARTITIONS = {df_rds_temp.rdd.getNumPartitions()}"""
            LOGGER.info(f"""{loop_count}-df_rds_temp-{db_sch_tbl}: {msg_prefix}""")

            # REPARTITION RDS-DATAFRAME IF ENABLED
            if rds_df_repartition_num != 0:
                df_rds_temp = df_rds_temp.repartition(rds_df_repartition_num, jdbc_partition_column)


            # TRANSFORM & CACHE - RDS - BATCH ROWS: START
            df_rds_temp_t3, trim_str_msg, trim_ts_ms_msg = apply_rds_transforms(df_rds_temp, 
                                                                                rds_jdbc_conn_obj, 
                                                                                rds_tbl_name)
            additional_msg = trim_str_msg+trim_ts_ms_msg \
                                if trim_str_msg+trim_ts_ms_msg != '' else additional_msg

            df_rds_temp_t4 = df_rds_temp_t3.cache()
            # TRANSFORM & CACHE - RDS - BATCH ROWS: END


            # REMOVE MATCHING RDS BATCH ROWS FROM CACHED PARQUET DATAFRAME - START
            df_prq_read_t2_filtered = exclude_rds_matched_rows_from_parquet_df(
                                            df_prq_read_t2,
                                            df_rds_temp_t4
                                        )
            # --------------------------------------------

            # df_prq_read_t2.unpersist() #>> This may not be required to update a cached dataframe <<

            # ---------------------------
            # sc._jsc.getPersistentRDDs() #>> which shows a list of cached RDDs/dataframes, and
            # spark.catalog.clearCache() #>> which clears all cached RDDs/dataframes.
            # ---------------------------

            df_prq_read_t2 = df_prq_read_t2_filtered.repartition(
                                                        parquet_df_repartition_num, 
                                                        jdbc_partition_column)
            
            # REMOVE MATCHING RDS BATCH ROWS FROM CACHED PARQUET DATAFRAME - END

            # ACTION
            rds_rows_read_count = df_rds_temp_t4.count()
            LOGGER.info(f"""{loop_count}-RDS rows fetched = {rds_rows_read_count}""")
            total_rds_rows_fetched += rds_rows_read_count

            # ACTION
            df_prq_read_t2_count = df_prq_read_t2.count()
            LOGGER.info(f"""{loop_count}-df_prq_read_t2_count = {df_prq_read_t2_count}""")
            cumulative_matched_rows = df_rds_count - df_prq_read_t2_count
            LOGGER.info(f"""{loop_count}-cumulative_matched_rows = {cumulative_matched_rows}""")

            df_rds_temp_t4.unpersist(True)
        
        # WHILE-ELSE - final leftover rows processed in this block.
        else:

            if jdbc_partition_col_upperbound < pkey_max_value:
                loop_count += 1

                # EVALUATE LOWER & UPPER BOUND VALUES OF PARTITION / PRIMARY KEY COLUMN
                jdbc_partition_col_lowerbound = jdbc_partition_col_upperbound+1
                msg_prefix = f"""jdbc_partition_col_lowerbound = {jdbc_partition_col_lowerbound}"""
                LOGGER.info(f"""{loop_count}-{msg_prefix}""")

                jdbc_partition_col_upperbound = pkey_max_value
                msg_prefix = f"""jdbc_partition_col_upperbound = {jdbc_partition_col_upperbound}"""
                LOGGER.info(f"""{loop_count}-{msg_prefix}""")

                # READ - RDS - BATCH ROWS: START
                df_rds_temp = rds_jdbc_conn_obj.get_df_read_rds_db_tbl_pkey_between(
                                                    rds_tbl_name, 
                                                    jdbc_partition_column,
                                                    jdbc_partition_col_lowerbound,
                                                    jdbc_partition_col_upperbound,
                                                    int(args['parallel_jdbc_conn_num'])
                                )
                
                msg_prefix = f"""READ PARTITIONS = {df_rds_temp.rdd.getNumPartitions()}"""
                LOGGER.info(f"""{loop_count}-df_rds_temp-{db_sch_tbl}: {msg_prefix}""")
                # READ - RDS - BATCH ROWS: END

                if rds_df_repartition_num != 0:
                    df_rds_temp = df_rds_temp.repartition(rds_df_repartition_num, jdbc_partition_column)
                # -------------------------------------------

                # TRANSFORM & CACHE - RDS - BATCH ROWS: START
                df_rds_temp_t3, trim_str_msg, trim_ts_ms_msg = apply_rds_transforms(df_rds_temp, 
                                                                                    rds_jdbc_conn_obj, 
                                                                                    rds_tbl_name)
                additional_msg = trim_str_msg+trim_ts_ms_msg \
                                    if trim_str_msg+trim_ts_ms_msg != '' else additional_msg

                df_rds_temp_t4 = df_rds_temp_t3.cache()
                # TRANSFORM & CACHE - RDS - BATCH ROWS: END

                # REMOVE MATCHING RDS BATCH ROWS FROM CACHED PARQUET DATAFRAME - START
                df_prq_read_t2_filtered = exclude_rds_matched_rows_from_parquet_df(
                                                df_prq_read_t2,
                                                df_rds_temp_t4
                                            )

                # df_prq_read_t2.unpersist() #>> This may not be required to update a cached dataframe <<

                df_prq_read_t2 = df_prq_read_t2_filtered.repartition(
                                                            int(parquet_df_repartition_num/2), 
                                                            jdbc_partition_column)
                
                # REMOVE MATCHING RDS BATCH ROWS FROM CACHED PARQUET DATAFRAME - START

                # ACTION
                rds_rows_read_count = df_rds_temp_t4.count()
                LOGGER.info(f"""{loop_count}-RDS rows fetched = {rds_rows_read_count}""")
                total_rds_rows_fetched += rds_rows_read_count

                # ACTION
                df_prq_read_t2_count = df_prq_read_t2.count()
                LOGGER.info(f"""{loop_count}-df_prq_read_t2_count = {df_prq_read_t2_count}""")
                cumulative_matched_rows = df_rds_count - df_prq_read_t2_count
                LOGGER.info(f"""{loop_count}-cumulative_matched_rows = {cumulative_matched_rows}""")
            # --------------------------------------------

            df_rds_temp_t4.unpersist(True)

        LOGGER.info(f"""RDS-SQLServer-JDBC READ {rds_tbl_name}: Total batch iterations = {loop_count}""")

        # ACTION
        total_row_differences = df_prq_read_t2_count

        if total_row_differences == 0 and (total_rds_rows_fetched == cumulative_matched_rows):
            df_temp_row = spark.sql(f"""select 
                                        current_timestamp() as run_datetime, 
                                        '' as json_row,
                                        "{rds_tbl_name} - Validated.{additional_msg}" as validation_msg,
                                        '{rds_db_name}' as database_name,
                                        '{db_sch_tbl}' as full_table_name,
                                        'False' as table_to_ap
                                    """.strip())
                
            LOGGER.info(f"{rds_tbl_name}: Validation Successful - 1")
            df_dv_output = df_dv_output.union(df_temp_row)
        else:

            LOGGER.warn(f"""Parquet-RDS Subtract Report: ({total_row_differences}): Row differences found!""")

            df_subtract_temp = (df_prq_read_t2
                                    .withColumn('json_row', F.to_json(F.struct(*[F.col(c) for c in df_rds_temp_t4.columns])))
                                    .selectExpr("json_row")
                                    .limit(100))

            subtract_validation_msg = f"""'{rds_tbl_name}' - {total_row_differences}"""
            df_subtract_temp = df_subtract_temp.selectExpr(
                                    "current_timestamp as run_datetime",
                                    "json_row",
                                    f""""{subtract_validation_msg} - Dataframe(s)-Subtract Non-Zero Row Count!" as validation_msg""",
                                    f"""'{rds_db_name}' as database_name""",
                                    f"""'{db_sch_tbl}' as full_table_name""",
                                    """'False' as table_to_ap"""
                                )
            LOGGER.warn(f"{rds_tbl_name}: Validation Failed - 2")
            df_dv_output = df_dv_output.union(df_subtract_temp)
        # -----------------------------------------------------

        df_prq_read_t2.unpersist(True)

    else:

        df_temp_row = spark.sql(f"""select
                                    current_timestamp as run_datetime,
                                    '' as json_row,
                                    '{db_sch_tbl} - S3-Parquet folder path does not exist !' as validation_msg,
                                    '{rds_db_name}' as database_name,
                                    '{db_sch_tbl}' as full_table_name,
                                    'False' as table_to_ap
                                """.strip())
        LOGGER.warn(f"{rds_tbl_name}: Validation not applicable - 4")
        df_dv_output = df_dv_output.union(df_temp_row)
    # -------------------------------------------------------

    LOGGER.info(final_validation_msg)

    return df_dv_output


def write_parquet_to_s3(df_dv_output: DataFrame, database, db_sch_tbl_name):

    df_dv_output = df_dv_output.repartition(1)

    if S3Methods.check_s3_folder_path_if_exists(PARQUET_OUTPUT_S3_BUCKET_NAME,
                                      f'''{CATALOG_DB_TABLE_PATH}/database_name={database}/full_table_name={db_sch_tbl_name}'''
                                      ):
        LOGGER.info(f"""Purging S3-path: {CATALOG_TABLE_S3_FULL_PATH}/database_name={database}/full_table_name={db_sch_tbl_name}""")

        glueContext.purge_s3_path(f"""{CATALOG_TABLE_S3_FULL_PATH}/database_name={database}/full_table_name={db_sch_tbl_name}""",
                                  options={"retentionPeriod": 0}
                                  )
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

    total_files, total_size = S3Methods.get_s3_folder_info(
                                PRQ_FILES_SRC_S3_BUCKET_NAME, 
                                f"{rds_db_name}/{rds_sqlserver_db_schema}/{rds_sqlserver_db_table}/")
    total_size_mb = total_size/1024/1024
    LOGGER.warn(f""">> '{db_sch_tbl}' Size: {total_size_mb} MB <<""")

    df_dv_output = process_dv_for_table(rds_jdbc_conn_obj, 
                                        db_sch_tbl)

    write_parquet_to_s3(df_dv_output, rds_db_name, db_sch_tbl)

    job.commit()
