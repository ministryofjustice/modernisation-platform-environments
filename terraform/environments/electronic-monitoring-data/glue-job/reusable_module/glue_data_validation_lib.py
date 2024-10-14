import time

from pyspark.context import SparkContext
from awsglue.context import GlueContext
from pyspark.sql import DataFrame
import pyspark.sql.functions as F

from awsglue.utils import getResolvedOptions


class RDSConn_Constants:
    RDS_DB_PORT = 1433
    RDS_DB_INSTANCE_USER = "admin"
    RDS_DB_INSTANCE_DRIVER = "com.microsoft.sqlserver.jdbc.SQLServerDriver"


class Logical_Constants:
    NVL_DTYPE_DICT = {
    'tinyint': 0, 'smallint': 0, 'int': 0, 'bigint': 0,
    'double': 0, 'float': 0, 'string': "''", 'boolean': False,
    'timestamp': "to_timestamp('1900-01-01', 'yyyy-MM-dd')",
    'date': "to_date('1900-01-01', 'yyyy-MM-dd')"}

    INT_DATATYPES_LIST = ['tinyint', 'smallint', 'int', 'bigint']

    RECORDED_PKEYS_LIST = {
        'F_History': ['HistorySID'],
        'GPSPosition': ['GPSPositionID']
    }


class SparkSession:
    sc = SparkContext()
    sc._jsc.hadoopConfiguration().set("spark.dynamicAllocation.enabled", "true")

    glueContext = GlueContext(sc)
    spark = glueContext.spark_session

    LOGGER = glueContext.get_logger()


def resolve_args(args_list):
    SparkSession.LOGGER.info(f">> Resolving Argument Variables: START")
    available_args_list = list()
    for item in args_list:
        try:
            args = getResolvedOptions(sys.argv, [f'{item}'])
            available_args_list.append(item)
        except Exception as e:
            SparkSession.LOGGER.warn(f"WARNING: Missing argument, {e}")
    SparkSession.LOGGER.info(f"AVAILABLE arguments: {available_args_list}")
    SparkSession.LOGGER.info(">> Resolving Argument Variables: COMPLETE")
    return available_args_list


# ---------------------------------------------------------------------
# PYTHON CLASS 'RDS_JDBC_CONNECTION' - END
# ---------------------------------------------------------------------
class RDS_JDBC_CONNECTION():

    RDS_DB_PORT = RDSConn_Constants.RDS_DB_PORT
    RDS_DB_INSTANCE_USER = RDSConn_Constants.RDS_DB_INSTANCE_USER
    RDS_DB_INSTANCE_DRIVER = RDSConn_Constants.RDS_DB_INSTANCE_DRIVER

    spark = SparkSession.spark
    LOGGER = SparkSession.LOGGER

    def __init__(self,
                 RDS_DB_HOST_ENDPOINT,
                 RDS_DB_INSTANCE_PWD,
                 rds_sqlserver_db,
                 rds_sqlserver_db_schema,
                 rds_sqlserver_db_table):
        self.RDS_DB_HOST_ENDPOINT = RDS_DB_HOST_ENDPOINT
        self.RDS_DB_INSTANCE_PWD = RDS_DB_INSTANCE_PWD
        self.rds_db_name = rds_sqlserver_db
        self.rds_db_schema_name = rds_sqlserver_db_schema
        self.rds_db_table_name = rds_sqlserver_db_table
        self.rds_jdbc_url_v1 = f"""jdbc:sqlserver://{RDS_DB_HOST_ENDPOINT}:{self.RDS_DB_PORT};"""
        self.rds_jdbc_url_v2 = f"""{self.rds_jdbc_url_v1}database={self.rds_db_name}"""

    def check_if_rds_db_exists(self):
        sql_sys_databases = f"""
        SELECT name FROM sys.databases
         WHERE name IN ('{self.rds_db_name}')
        """.strip()

        self.LOGGER.info(f"""Using SQL Statement >>>\n{sql_sys_databases}""")
        df_rds_sys = (self.spark.read.format("jdbc")
                                .option("url", self.rds_jdbc_url_v1)
                                .option("query", sql_sys_databases)
                                .option("user", self.RDS_DB_INSTANCE_USER)
                                .option("password", self.RDS_DB_INSTANCE_PWD)
                                .option("driver", self.RDS_DB_INSTANCE_DRIVER)
                                .load()
                      )
        return [row[0] for row in df_rds_sys.collect()]

    def get_all_the_existing_tables_as_df(self) -> DataFrame:
        sql_information_schema = f"""
        SELECT table_catalog, table_schema, table_name
          FROM information_schema.tables
         WHERE table_type = 'BASE TABLE'
           AND table_schema = '{self.rds_db_schema_name}'
        """.strip()

        self.LOGGER.info(f"using the SQL Statement:\n{sql_information_schema}")

        return (self.spark.read.format("jdbc")
                .option("url", self.rds_jdbc_url_v2)
                .option("query", sql_information_schema)
                .option("user", self.RDS_DB_INSTANCE_USER)
                .option("password", self.RDS_DB_INSTANCE_PWD)
                .option("driver", self.RDS_DB_INSTANCE_DRIVER)
                .load()
                )

    def get_rds_db_tbl_list(self):
        rds_db_tbl_temp_list = list()

        df_rds_sqlserver_db_tbls = self.get_all_the_existing_tables_as_df()

        df_rds_sqlserver_db_tbls = (df_rds_sqlserver_db_tbls.select(
            F.concat(df_rds_sqlserver_db_tbls.table_catalog,
                     F.lit('_'), df_rds_sqlserver_db_tbls.table_schema,
                     F.lit('_'), df_rds_sqlserver_db_tbls.table_name).alias("full_table_name"))
        )

        rds_db_tbl_temp_list = rds_db_tbl_temp_list + \
            [row[0] for row in df_rds_sqlserver_db_tbls.collect()]

        return rds_db_tbl_temp_list

    def get_rds_dataframe_v1(self) -> DataFrame:
        return self.spark.read.jdbc(url=self.rds_jdbc_url_v2,
                            table=f"""{self.rds_db_schema_name }.[{self.rds_db_table_name}]""",
                            properties={"user": self.RDS_DB_INSTANCE_USER,
                                        "password": self.RDS_DB_INSTANCE_PWD,
                                        "driver": self.RDS_DB_INSTANCE_DRIVER})

    def get_rds_dataframe_v2(self, jdbc_partition_column, pkey_min, pkey_max) -> DataFrame:

        query_str = f"""
        SELECT *
          FROM {self.rds_db_schema_name}.[{self.rds_db_table_name}]
         WHERE {jdbc_partition_column} between {pkey_min} and {pkey_max}
        """.strip()

        self.LOGGER.info(f"""query_str-(SingleJDBCConn):> \n{query_str}""")

        return (self.spark.read.format("jdbc")
                .option("url", self.rds_jdbc_url_v2)
                .option("driver", self.RDS_DB_INSTANCE_DRIVER)
                .option("user", self.RDS_DB_INSTANCE_USER)
                .option("password", self.RDS_DB_INSTANCE_PWD)
                .option("dbtable", f"""({query_str}) as t""")
                .load())

    def get_rds_df_parallel_jdbc(self,
                                 jdbc_partition_column,
                                 jdbc_partition_col_upperbound,
                                 jdbc_read_partitions_num,
                                 jdbc_partition_col_lowerbound=0,
                                 ) -> DataFrame:

        numPartitions = jdbc_read_partitions_num
        # Note: numPartitions is normally equal to number of executors defined.
        # The maximum number of partitions that can be used for parallelism in table reading and writing.
        # This also determines the maximum number of concurrent JDBC connections.

        self.LOGGER.info(
            f"""jdbc_partition_col_lowerbound = {jdbc_partition_col_lowerbound}""")
        self.LOGGER.info(
            f"""jdbc_partition_col_upperbound = {jdbc_partition_col_upperbound}""")

        fetchSize = int((jdbc_partition_col_upperbound -
                        jdbc_partition_col_lowerbound)/jdbc_read_partitions_num)
        self.LOGGER.info(f"""fetchSize = {fetchSize}""")

        query_str = f"""
        SELECT *
          FROM {self.rds_db_schema_name}.[{self.rds_db_table_name}]
         WHERE {jdbc_partition_column} between {jdbc_partition_col_lowerbound} and {jdbc_partition_col_upperbound}
        """.strip()

        self.LOGGER.info(f"""query_str-(ParallelJDBCConn):> \n{query_str}""")

        return (self.spark.read.format("jdbc")
                .option("url", self.rds_jdbc_url_v2)
                .option("driver", self.RDS_DB_INSTANCE_DRIVER)
                .option("user", self.RDS_DB_INSTANCE_USER)
                .option("password", self.RDS_DB_INSTANCE_PWD)
                .option("dbtable", f"""({query_str}) as t""")
                .option("partitionColumn", jdbc_partition_column)
                .option("lowerBound", jdbc_partition_col_lowerbound)
                .option("upperBound", jdbc_partition_col_upperbound)
                .option("numPartitions", numPartitions)
                .option("fetchSize", fetchSize)
                .load())

    def get_rds_tbl_col_attributes(self) -> DataFrame:

        sql_statement = f"""
        SELECT column_name, data_type, is_nullable 
          FROM information_schema.columns
         WHERE table_schema = '{self.rds_db_schema_name}'
           AND table_name = '{self.rds_db_table_name}'
        """.strip()
        # ORDER BY ordinal_position

        return (self.spark.read.format("jdbc")
                .option("url", self.rds_jdbc_url_v2)
                .option("query", sql_statement)
                .option("user", self.RDS_DB_INSTANCE_USER)
                .option("password", self.RDS_DB_INSTANCE_PWD)
                .option("driver", self.RDS_DB_INSTANCE_DRIVER)
                .load()
                )

    def get_rds_db_table_empty_df(self) -> DataFrame:

        query_str = f"""
        SELECT *
          FROM {self.rds_db_schema_name}.[{self.rds_db_table_name}]
         WHERE 1 = 2
        """.strip()

        return (self.spark.read.format("jdbc")
                .option("url", self.rds_jdbc_url_v2)
                .option("driver", self.RDS_DB_INSTANCE_DRIVER)
                .option("user", self.RDS_DB_INSTANCE_USER)
                .option("password", self.RDS_DB_INSTANCE_PWD)
                .option("query", f"""{query_str}""")
                .load())

    def get_jdbc_partition_column(self, rds_tbl_pkeys_list):

        rds_db_table_empty_df = self.get_rds_db_table_empty_df()
        df_rds_dtype_dict = CustomPysparkMethods.get_dtypes_dict(rds_db_table_empty_df)
        int_dtypes_colname_list = [colname for colname, dtype in df_rds_dtype_dict.items() 
                                    if dtype in Logical_Constants.INT_DATATYPES_LIST]

        if rds_tbl_pkeys_list[0] in int_dtypes_colname_list:
            return rds_tbl_pkeys_list[0]
        else:
            return None

    def get_min_max_groupby_month(self,
                                  date_partition_col,
                                  pkey_col_name,
                                  rds_query_where_clause):

        query_str = f"""
        SELECT YEAR({date_partition_col}) AS year, 
               MONTH({date_partition_col}) AS month, 
               MIN({pkey_col_name}) AS min_pkey_value, 
               MAX({pkey_col_name}) AS max_pkey_value
          FROM {self.rds_db_schema_name}.[{self.rds_db_table_name}]
        """.strip()

        if rds_query_where_clause != '' or rds_query_where_clause is not None:
            query_str = query_str + \
                f""" WHERE {rds_query_where_clause.strip()}"""

        query_str = query_str + f""" GROUP BY YEAR({date_partition_col}), MONTH({date_partition_col})"""

        self.LOGGER.info(f"""query_str-(Aggregate):> \n{query_str}""")

        return (self.spark.read.format("jdbc")
                .option("url", self.rds_jdbc_url_v2)
                .option("driver", self.RDS_DB_INSTANCE_DRIVER)
                .option("user", self.RDS_DB_INSTANCE_USER)
                .option("password", self.RDS_DB_INSTANCE_PWD)
                .option("query", f"""{query_str}""")
                .load()).collect()
# ---------------------------------------------------------------------
# PYTHON CLASS 'RDS_JDBC_CONNECTION' - END
# ---------------------------------------------------------------------


class AthenaMethods:

    def __init__(self,
                 ATHENA_CLIENT,
                 ATHENA_RUN_OUTPUT_LOCATION):
        self.ATHENA_CLIENT = ATHENA_CLIENT
        self.ATHENA_RUN_OUTPUT_LOCATION = ATHENA_RUN_OUTPUT_LOCATION

    def run_athena_query(self, sql_statement_str):
        response = self.ATHENA_CLIENT.start_query_execution(
            QueryString=sql_statement_str,
            ResultConfiguration={"OutputLocation": self.ATHENA_RUN_OUTPUT_LOCATION}
        )
        return response["QueryExecutionId"]

    def has_query_succeeded(self, execution_id):
        state = "RUNNING"
        max_execution = 5

        while max_execution > 0 and state in ["RUNNING", "QUEUED"]:
            max_execution -= 1
            response = self.ATHENA_CLIENT.get_query_execution(
                QueryExecutionId=execution_id)
            if (
                "QueryExecution" in response
                and "Status" in response["QueryExecution"]
                and "State" in response["QueryExecution"]["Status"]
            ):
                state = response["QueryExecution"]["Status"]["State"]
                if state == "SUCCEEDED":
                    return True

            time.sleep(30)

        return False


class S3Methods:
    
    def __init__(self,
                 S3_CLIENT):
        self.S3_CLIENT = S3_CLIENT

    def get_s3_folder_info(self, bucket_name, prefix):
        paginator = self.S3_CLIENT.get_paginator('list_objects_v2')

        total_size = 0
        total_files = 0

        for page in paginator.paginate(Bucket=bucket_name, Prefix=prefix):
            for obj in page.get('Contents', []):
                total_files += 1
                total_size += obj['Size']

        return total_files, total_size

    def check_s3_folder_path_if_exists(self, in_bucket_name, in_folder_path):
        result = self.S3_CLIENT.list_objects(
            Bucket=in_bucket_name, Prefix=in_folder_path)
        exists = False
        if 'Contents' in result:
            exists = True
        return exists

    @classmethod
    def get_s3_table_folder_path(cls,
                                 rds_jdbc_conn_obj,
                                 in_parquet_files_bucket_name,
                                 rename_target_table_folder=None):
        
        if rename_target_table_folder is not None:
            dir_path_str = f"{rds_jdbc_conn_obj.rds_db_name}/{rds_jdbc_conn_obj.rds_db_schema_name}/{rename_target_table_folder}"
        else:
            dir_path_str = f"{rds_jdbc_conn_obj.rds_db_name}/{rds_jdbc_conn_obj.rds_db_schema_name}/{rds_jdbc_conn_obj.rds_db_table_name}"
        
        tbl_full_dir_path_str = f"s3://{in_parquet_files_bucket_name}/{dir_path_str}/"

        if cls.check_s3_folder_path_if_exists(in_parquet_files_bucket_name, dir_path_str):
            return tbl_full_dir_path_str
        else:
            SparkSession.LOGGER.info(f"{tbl_full_dir_path_str} -- Table-Folder-S3-Path Not Found !")
            return None


class CustomPysparkMethods:

    @staticmethod
    def get_dtypes_dict(in_rds_df: DataFrame):
        return {name: dtype for name, dtype in in_rds_df.dtypes}
