
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

from pyspark.sql import DataFrame
import pyspark.sql.functions as F

# ===============================================================================

sc = SparkSession.sc
sc._jsc.hadoopConfiguration().set("spark.memory.offHeap.enabled", "true")
sc._jsc.hadoopConfiguration().set("spark.memory.offHeap.size", "2g")
sc._jsc.hadoopConfiguration().set("spark.dynamicAllocation.enabled", "true")

glueContext = SparkSession.glueContext
spark = SparkSession.spark

LOGGER = SparkSession.LOGGER

# ===============================================================================

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
    "skip_columns_comparison",
    "parquet_tbl_folder_if_different"
]

AVAILABLE_ARGS_LIST = CustomPysparkMethods.resolve_args(DEFAULT_INPUTS_LIST+OPTIONAL_INPUTS)

args = getResolvedOptions(sys.argv, AVAILABLE_ARGS_LIST)

# ------------------------------

job = Job(glueContext)
job.init(args["JOB_NAME"], args)

# ------------------------------

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

# ===============================================================================


def process_dv_for_table(rds_jdbc_conn_obj,
                         rds_tbl_name,
                         total_files, 
                         total_size_mb) -> DataFrame:

    rds_db_name = rds_jdbc_conn_obj.rds_db_name
    db_sch_tbl = f"{rds_db_name}_{rds_jdbc_conn_obj.rds_db_schema_name}_{rds_tbl_name}"
    
    int_read_partition_size_mb = int(args['read_partition_size_mb'])
    if int_read_partition_size_mb%64 != 0 \
        or int_read_partition_size_mb == 0:
        value_error_msg = f"""
        The input 'read_partition_size_mb'-{int_read_partition_size_mb} must be multiple of 64 !
        """.strip()
        raise ValueError(value_error_msg)
    
    read_partitions = int(total_size_mb/int_read_partition_size_mb)
    
    num_of_repartitions = int(args['num_of_repartitions'])

    df_dv_output = CustomPysparkMethods.declare_empty_df_dv_output_v1()

    parquet_tbl_folder_if_different = args.get('parquet_tbl_folder_if_different', '')
    if parquet_tbl_folder_if_different != '':
        tbl_prq_s3_folder_path = CustomPysparkMethods.get_s3_table_folder_path(
                                                        rds_jdbc_conn_obj, 
                                                        PRQ_FILES_SRC_S3_BUCKET_NAME,
                                                        parquet_tbl_folder_if_different
                                    )
        LOGGER.info(f"""Using a different parquet folder: {parquet_tbl_folder_if_different}""")
    else:
        tbl_prq_s3_folder_path = CustomPysparkMethods.get_s3_table_folder_path(
                                                        rds_jdbc_conn_obj, 
                                                        PRQ_FILES_SRC_S3_BUCKET_NAME,
                                                        rds_tbl_name
                                    )
    # -------------------------------------------------------

    pkey_partion_read_used = False
    if tbl_prq_s3_folder_path is not None:
        
        LOGGER.info(f"""tbl_prq_s3_folder_path: {tbl_prq_s3_folder_path}""")

        # READ RDS-SQLSERVER-DB --> DATAFRAME
        if args.get('rds_db_tbl_pkeys_col_list', None) is None:
            if RECORDED_PKEYS_LIST.get(rds_tbl_name, None) is None:
                LOGGER.warn(f"""No READ-partition columns given !""")
                df_rds_temp = rds_jdbc_conn_obj.get_rds_dataframe_v1(rds_tbl_name)

            else:
                if isinstance(RECORDED_PKEYS_LIST[rds_tbl_name], list) \
                    and len(RECORDED_PKEYS_LIST[rds_tbl_name]) == 1:

                    jdbc_partition_column = rds_jdbc_conn_obj.get_jdbc_partition_column(
                                                    rds_tbl_name,
                                                    RECORDED_PKEYS_LIST[rds_tbl_name]
                                            )
                    if jdbc_partition_column is not None:
                        LOGGER.info(f"""RECORDED_PKEYS_LIST[{rds_tbl_name}] = {jdbc_partition_column}""")
                    else:
                        LOGGER.error(f"""{RECORDED_PKEYS_LIST[rds_tbl_name]}: >> not an INT Datatype column <<""")
                        sys.exit(1)

                    df_rds_temp = rds_jdbc_conn_obj.get_rds_df_jdbc_read_parallel(
                                                        rds_tbl_name, 
                                                        RECORDED_PKEYS_LIST[rds_tbl_name],
                                                        jdbc_partition_column,
                                                        read_partitions,
                                                        total_files
                                    )
                    pkey_partion_read_used = True
                else:
                    LOGGER.error(f"""RECORDED_PKEYS_LIST[f"{rds_tbl_name}"] = {RECORDED_PKEYS_LIST[{rds_tbl_name}]}""")
                    LOGGER.error(f"""RECORDED_PKEYS_LIST[f"{rds_tbl_name}"] - value is not a list
                                 OR
                                 Morethan one primary-key column(s) specified.
                                 """)
                    sys.exit(1)
                # -------------------------------------------------------

            # -------------------------------------------------------
            
        else:
            rds_db_tbl_pkeys_col_list = [f"""{column.strip().strip("'").strip('"')}""" 
                                         for column in args['rds_db_tbl_pkeys_col_list'].split(",")]

            jdbc_partition_column = rds_jdbc_conn_obj.get_jdbc_partition_column(
                                                        rds_tbl_name,
                                                        rds_db_tbl_pkeys_col_list
                                    )
            LOGGER.info(f"""jdbc_partition_column = {jdbc_partition_column}""")

            df_rds_temp = rds_jdbc_conn_obj.get_rds_df_jdbc_read_parallel(
                                                rds_tbl_name, 
                                                rds_db_tbl_pkeys_col_list,
                                                jdbc_partition_column,
                                                read_partitions,
                                                total_files
                            )
            pkey_partion_read_used = True
        # -------------------------------------------------------

        LOGGER.info(f"""df_rds_temp-{rds_tbl_name}: READ PARTITIONS = {df_rds_temp.rdd.getNumPartitions()}""")
        
        # READ PARQUET --> DATAFRAME
        LOGGER.info(f"""S3-Folder-Parquet-Read: Total Size >> {total_size_mb}MB""")
        df_prq_temp = CustomPysparkMethods.get_s3_parquet_df_v2(tbl_prq_s3_folder_path, 
                                                                df_rds_temp.schema)
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


        select_compare_columns = None
        skip_columns_msg = ""
        skip_columns_comparison = args.get("skip_columns_comparison", None)
        if skip_columns_comparison is not None:
            given_skip_columns_comparison_str = args["skip_columns_comparison"]
            given_skip_columns_comparison_list = [f"""{col.strip().strip("'").strip('"')}"""
                                                    for col in given_skip_columns_comparison_str.split(",")]
            LOGGER.warn(f""">> given_skip_columns_comparison_list = {given_skip_columns_comparison_list}<<""")

            select_compare_columns = [col for col in df_rds_temp.columns 
                                        if col not in given_skip_columns_comparison_list]
            LOGGER.warn(f""">> Only the below selected columns are compared \n{select_compare_columns}<<""")
            skip_columns_msg = f"""; columns_skipped = {given_skip_columns_comparison_list}"""

        final_select_columns = df_rds_temp.columns if select_compare_columns is None \
                                                    else select_compare_columns
        
        df_rds_temp = df_rds_temp.select(*final_select_columns)
        df_rds_temp_t1 = df_rds_temp.selectExpr(
                                        *CustomPysparkMethods.get_nvl_select_list(
                                                                df_rds_temp, 
                                                                rds_jdbc_conn_obj, 
                                                                rds_tbl_name
                                        )
                        )


        trim_str_msg = ""
        t2_rds_str_col_trimmed = False
        if args.get("rds_df_trim_str_columns", "false") == "true":
            LOGGER.info(f"""Given -> rds_df_trim_str_columns = 'true'""")
            LOGGER.warn(f""">> Stripping string column spaces <<""")

            df_rds_temp_t2 = df_rds_temp_t1.transform(CustomPysparkMethods.rds_df_trim_str_columns)

            trim_str_msg = "; [str column(s) - extra spaces trimmed]"
            t2_rds_str_col_trimmed = True
        # -------------------------------------------------------
        
        if t2_rds_str_col_trimmed:
            df_rds_temp_t4 = df_rds_temp_t2
        else:
            df_rds_temp_t4 = df_rds_temp_t1
        # -------------------------------------------------------

        df_rds_temp_t5 = df_rds_temp_t4.cache()

        df_prq_temp = df_prq_temp.select(*final_select_columns)
        df_prq_temp_t1 = df_prq_temp.selectExpr(
                                        *CustomPysparkMethods.get_nvl_select_list(
                                                df_rds_temp, 
                                                rds_jdbc_conn_obj, 
                                                rds_tbl_name
                                        )
                            ).cache()

        df_rds_temp_count = df_rds_temp_t5.count()
        df_prq_temp_count = df_prq_temp_t1.count()
        # -------------------------------------------------------

        validated_msg = f"""{rds_tbl_name} - Validated.\n{skip_columns_msg}\n{trim_str_msg}"""
        if df_rds_temp_count == df_prq_temp_count:

            df_rds_prq_subtract_t1 = df_rds_temp_t5.subtract(df_prq_temp_t1)
            df_rds_prq_subtract_row_count = df_rds_prq_subtract_t1.count()

            if df_rds_prq_subtract_row_count == 0:
                df_temp = df_dv_output.selectExpr(
                                        "current_timestamp as run_datetime",
                                        "'' as json_row",
                                        f""""{validated_msg}" as validation_msg""",
                                        f"""'{rds_db_name}' as database_name""",
                                        f"""'{db_sch_tbl}' as full_table_name""",
                                        """'False' as table_to_ap"""
                            )
                LOGGER.info(f"Validation Successful - 1")
                df_dv_output = df_dv_output.union(df_temp)
            else:
                df_subtract_temp = (df_rds_prq_subtract_t1
                           .withColumn('json_row', 
                                       F.to_json(
                                           F.struct(*[F.col(c) 
                                                      for c in df_rds_temp.columns])))
                           .selectExpr("json_row")
                           .limit(100))

                subtract_validation_msg = f"""'{rds_tbl_name}' - {df_rds_prq_subtract_row_count}"""
                df_subtract_temp = df_subtract_temp.selectExpr(
                                        "current_timestamp as run_datetime",
                                        "json_row",
                                        f""""{subtract_validation_msg}: - Rows not matched!" as validation_msg""",
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

    if S3Methods.check_s3_folder_path_if_exists(
                                PARQUET_OUTPUT_S3_BUCKET_NAME,
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

    if args.get("rds_select_db_tbls", None) is None:
        # -------------------------------------------------------
        
        if args.get("rds_exclude_db_tbls", None) is None:
            exclude_rds_db_tbls_list = list()
        else:
            table_name_prefix = f"""{rds_sqlserver_db}_{rds_sqlserver_db_schema}"""
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
            rds_db_name, rds_tbl_name = db_sch_tbl.split(f"_{rds_sqlserver_db_schema}_")[0], \
                                        db_sch_tbl.split(f"_{rds_sqlserver_db_schema}_")[1]

            total_files, total_size = S3Methods.get_s3_folder_info(
                                        PRQ_FILES_SRC_S3_BUCKET_NAME, 
                                        f"{rds_db_name}/{rds_sqlserver_db_schema}/{rds_tbl_name}")
            total_size_mb = total_size/1024/1024

            dv_ctlg_tbl_partition_path = f'''
                {GLUE_CATALOG_DB_NAME}/{GLUE_CATALOG_TBL_NAME}/database_name={rds_db_name}/full_table_name={db_sch_tbl}/'''.strip()
            # -------------------------------------------------------

            if S3Methods.check_s3_folder_path_if_exists(PARQUET_OUTPUT_S3_BUCKET_NAME, 
                                                             dv_ctlg_tbl_partition_path):
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

            df_dv_output = process_dv_for_table(rds_jdbc_conn_obj, 
                                                rds_tbl_name, 
                                                total_files, 
                                                total_size_mb)

            write_parquet_to_s3(df_dv_output, rds_db_name, db_sch_tbl)

    else:
        given_rds_sqlserver_tbls_str = args["rds_select_db_tbls"]

        # LOGGER.info(f"""Given specific tables: {given_rds_sqlserver_tbls_str}, {type(given_rds_sqlserver_tbls_str)}""")

        table_name_prefix = f"""{args['rds_sqlserver_db']}_{rds_sqlserver_db_schema}"""
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
            rds_db_name, rds_tbl_name = db_sch_tbl.split(f"_{rds_sqlserver_db_schema}_")[0], \
                                        db_sch_tbl.split(f"_{rds_sqlserver_db_schema}_")[1]

            total_files, total_size = S3Methods.get_s3_folder_info(
                                        PRQ_FILES_SRC_S3_BUCKET_NAME, 
                                        f"{rds_db_name}/{rds_sqlserver_db_schema}/{rds_tbl_name}/")
            total_size_mb = total_size/1024/1024
            # -------------------------------------------------------

            if total_size_mb > int(args["max_table_size_mb"]):
                LOGGER.warn(f""">> Size greaterthan {args["max_table_size_mb"]}MB ({total_size_mb}MB) <<""")
            # -------------------------------------------------------

            df_dv_output = process_dv_for_table(rds_jdbc_conn_obj, 
                                                rds_tbl_name, 
                                                total_files, 
                                                total_size_mb)

            write_parquet_to_s3(df_dv_output, rds_db_name, db_sch_tbl)
    # -------------------------------------------------------

    job.commit()
