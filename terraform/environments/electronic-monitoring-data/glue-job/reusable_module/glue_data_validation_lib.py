import time
import sys
import boto3

# import typing as RT

from pyspark.context import SparkContext
from awsglue.context import GlueContext
from pyspark.sql import DataFrame
import pyspark.sql.functions as F
import pyspark.sql.types as T

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


# ---------------------------------------------------------------------
# PYTHON CLASS 'RDS_JDBC_CONNECTION' - END
# ---------------------------------------------------------------------
class RDS_JDBC_CONNECTION():

    RDS_DB_PORT = RDSConn_Constants.RDS_DB_PORT
    RDS_DB_INSTANCE_USER = RDSConn_Constants.RDS_DB_INSTANCE_USER
    RDS_DB_INSTANCE_DRIVER = RDSConn_Constants.RDS_DB_INSTANCE_DRIVER

    spark = SparkSession.spark
    LOGGER = SparkSession.LOGGER

    # Note:> All of 'partitionColumn', 'lowerBound', 'upperBound', and 'numPartitions' must be specified if one is specified.
    # The partition column (specified in the 'partitionColumn' parameter) “must be a numeric, date, or timestamp column”.
    # stride (the number of rows read per partition) => (upper bound - lower bound) / number of partitions

    def __init__(self,
                 RDS_DB_HOST_ENDPOINT,
                 RDS_DB_INSTANCE_PWD,
                 rds_sqlserver_db,
                 rds_sqlserver_db_schema):
        self.RDS_DB_HOST_ENDPOINT = RDS_DB_HOST_ENDPOINT
        self.RDS_DB_INSTANCE_PWD = RDS_DB_INSTANCE_PWD
        self.rds_db_name = rds_sqlserver_db
        self.rds_db_schema_name = rds_sqlserver_db_schema
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

    def get_rds_dataframe_v1(self, rds_db_table_name) -> DataFrame:
        return self.spark.read.jdbc(url=self.rds_jdbc_url_v2,
                                    table=f"""{self.rds_db_schema_name }.[{rds_db_table_name}]""",
                                    properties={"user": self.RDS_DB_INSTANCE_USER,
                                                "password": self.RDS_DB_INSTANCE_PWD,
                                                "driver": self.RDS_DB_INSTANCE_DRIVER})

    def get_rds_db_table_row_count(self,
                                   in_table_name,
                                   in_pkeys_columns) -> DataFrame:
        if isinstance(in_pkeys_columns, list):
            query_str = f"""
            SELECT count({', '.join(in_pkeys_columns)}) as row_count
            FROM {self.rds_db_schema_name}.[{in_table_name}]
            """.strip()
        else:
            query_str = f"""
            SELECT count({in_pkeys_columns}) as row_count
            FROM {self.rds_db_schema_name}.[{in_table_name}]
            """.strip()            

        return (self.spark.read.format("jdbc")
                .option("url", self.rds_jdbc_url_v2)
                .option("driver", self.RDS_DB_INSTANCE_DRIVER)
                .option("user", self.RDS_DB_INSTANCE_USER)
                .option("password", self.RDS_DB_INSTANCE_PWD)
                .option("query", f"""{query_str}""")
                .load()).collect()[0].row_count

    def get_rds_df_read_tbl_pkey_parallel(self,
                                          in_table_name,
                                          jdbc_partition_column,
                                          jdbc_partition_col_upperbound,
                                          jdbc_read_partitions_num
                                          ) -> DataFrame:

        numPartitions = jdbc_read_partitions_num
        # Note: numPartitions is normally equal to number of executors defined.
        # The maximum number of partitions that can be used for parallelism in table reading and writing.
        # This also determines the maximum number of concurrent JDBC connections.

        # fetchSize = jdbc_rows_fetch_size
        # The JDBC fetch size, which determines how many rows to fetch per round trip.
        # This can help performance on JDBC drivers which default to low fetch size (e.g. Oracle with 10 rows).
        # Too Small: => frequent round trips to database
        # Too Large: => Consume a lot of memory

        query_str = f"""
        SELECT *
        FROM {self.rds_db_schema_name}.[{in_table_name}]
        """.strip()

        return (self.spark.read.format("jdbc")
                    .option("url", self.rds_jdbc_url_v2)
                    .option("driver", self.RDS_DB_INSTANCE_DRIVER)
                    .option("user", self.RDS_DB_INSTANCE_USER)
                    .option("password", self.RDS_DB_INSTANCE_PWD)
                    .option("dbtable", f"""({query_str}) as t""")
                    .option("partitionColumn", jdbc_partition_column)
                    .option("lowerBound", "0")
                    .option("upperBound", jdbc_partition_col_upperbound)
                    .option("numPartitions", numPartitions)
                    .load())

    def get_rds_df_read_query_pkey_parallel(self,
                                          in_db_query,
                                          jdbc_partition_column,
                                          jdbc_partition_col_lowerbound,
                                          jdbc_partition_col_upperbound,
                                          jdbc_read_partitions_num=1
                                          ) -> DataFrame:

        numPartitions = jdbc_read_partitions_num
        # Note: numPartitions is normally equal to number of executors defined.
        # The maximum number of partitions that can be used for parallelism in table reading and writing.
        # This also determines the maximum number of concurrent JDBC connections.

        # fetchSize = jdbc_rows_fetch_size
        # The JDBC fetch size, which determines how many rows to fetch per round trip.
        # This can help performance on JDBC drivers which default to low fetch size (e.g. Oracle with 10 rows).
        # Too Small: => frequent round trips to database
        # Too Large: => Consume a lot of memory

        return (self.spark.read.format("jdbc")
                    .option("url", self.rds_jdbc_url_v2)
                    .option("driver", self.RDS_DB_INSTANCE_DRIVER)
                    .option("user", self.RDS_DB_INSTANCE_USER)
                    .option("password", self.RDS_DB_INSTANCE_PWD)
                    .option("dbtable", f"""({in_db_query}) as t""")
                    .option("partitionColumn", jdbc_partition_column)
                    .option("lowerBound", jdbc_partition_col_lowerbound)
                    .option("upperBound", jdbc_partition_col_upperbound)
                    .option("numPartitions", numPartitions)
                    .load())

    def get_rds_df_read_query(self, in_db_query) -> DataFrame:

        return (self.spark.read.format("jdbc")
                    .option("url", self.rds_jdbc_url_v2)
                    .option("driver", self.RDS_DB_INSTANCE_DRIVER)
                    .option("user", self.RDS_DB_INSTANCE_USER)
                    .option("password", self.RDS_DB_INSTANCE_PWD)
                    .option("dbtable", f"""({in_db_query}) as t""")
                    .load())


    def get_rds_df_query_min_max_count(self, 
                                       rds_table_name,
                                       table_pkey_column) -> DataFrame:

        query_str = f"""
        SELECT min({table_pkey_column}) as min_value,
               max({table_pkey_column}) as max_value,
               count({table_pkey_column}) as count_value
        FROM {self.rds_db_schema_name}.[{rds_table_name}]
        """.strip()

        return (self.spark.read.format("jdbc")
                    .option("url", self.rds_jdbc_url_v2)
                    .option("driver", self.RDS_DB_INSTANCE_DRIVER)
                    .option("user", self.RDS_DB_INSTANCE_USER)
                    .option("password", self.RDS_DB_INSTANCE_PWD)
                    .option("dbtable", f"""({query_str}) as t""")
                    .load())


    def get_min_max_count_groupby_yyyy_mm(self,
                                          rds_db_table,
                                          date_partition_col,
                                          pkey_column,
                                          filter_where_clause=None) -> DataFrame:

        agg_query_str = f"""
        SELECT YEAR({date_partition_col}) AS year, 
               MONTH({date_partition_col}) AS month, 
               MIN({pkey_column}) AS min_{pkey_column}, 
               MAX({pkey_column}) AS max_{pkey_column},
               COUNT({pkey_column}) AS count_{pkey_column}
          FROM {self.rds_db_schema_name}.[{rds_db_table}]
        """.strip()

        if filter_where_clause is not None:
            agg_query_str = agg_query_str + \
                f""" WHERE {filter_where_clause.rstrip()}"""

        agg_query_str = agg_query_str + \
            f""" GROUP BY YEAR({date_partition_col}), MONTH({date_partition_col})"""

        self.LOGGER.info(f"""query_str-(Aggregate):> \n{agg_query_str}""")

        df_agg = (self.spark.read.format("jdbc")
                .option("url", self.rds_jdbc_url_v2)
                .option("driver", self.RDS_DB_INSTANCE_DRIVER)
                .option("user", self.RDS_DB_INSTANCE_USER)
                .option("password", self.RDS_DB_INSTANCE_PWD)
                .option("query", f"""{agg_query_str}""")
                .load())
        
        df_agg = df_agg.orderBy(['year', 'month'], ascending=True)

        return df_agg


    def get_rds_df_jdbc_read_parallel(self,
                                      rds_tbl_name,
                                      rds_tbl_pkeys_list,
                                      jdbc_partition_column,
                                      read_partitions,
                                      total_files) -> DataFrame:

        jdbc_read_partitions_num = read_partitions \
            if read_partitions > total_files else total_files

        df_rds_count = self.get_rds_db_table_row_count(
            rds_tbl_name, rds_tbl_pkeys_list)

        jdbc_partition_col_upperbound = int(
            df_rds_count/jdbc_read_partitions_num)

        df_rds_temp = self.get_rds_df_read_tbl_pkey_parallel(rds_tbl_name,
                                                             jdbc_partition_column,
                                                             jdbc_partition_col_upperbound,
                                                             jdbc_read_partitions_num)
        return df_rds_temp

    def get_rds_df_read_pkey_min_max_range(self,
                                           rds_db_table_name,
                                           jdbc_partition_column,
                                           pkey_min,
                                           pkey_max,
                                           jdbc_read_partitions_num=None) -> DataFrame:
        self.LOGGER.info(
            f"""jdbc_partition_col_lowerbound = {pkey_min}""")
        self.LOGGER.info(
            f"""jdbc_partition_col_upperbound = {pkey_max}""")

        query_str = f"""
        SELECT *
          FROM {self.rds_db_schema_name}.[{rds_db_table_name}]
         WHERE {jdbc_partition_column} between {pkey_min} and {pkey_max}
        """.strip()

        if jdbc_read_partitions_num is None:
            self.LOGGER.info(f"""query_str-(SingleJDBCConn):> \n{query_str}""")

            return (self.spark.read.format("jdbc")
                    .option("url", self.rds_jdbc_url_v2)
                    .option("driver", self.RDS_DB_INSTANCE_DRIVER)
                    .option("user", self.RDS_DB_INSTANCE_USER)
                    .option("password", self.RDS_DB_INSTANCE_PWD)
                    .option("dbtable", f"""({query_str}) as t""")
                    .load())
        else:
            numPartitions = jdbc_read_partitions_num
            # Note: numPartitions is normally equal to number of executors defined.
            # This also determines the maximum number of 'partitions' / concurrent JDBC connections.

            self.LOGGER.info(
                f"""query_str-(ParallelJDBCConn):> \n{query_str}""")

            return (self.spark.read.format("jdbc")
                    .option("url", self.rds_jdbc_url_v2)
                    .option("driver", self.RDS_DB_INSTANCE_DRIVER)
                    .option("user", self.RDS_DB_INSTANCE_USER)
                    .option("password", self.RDS_DB_INSTANCE_PWD)
                    .option("dbtable", f"""({query_str}) as t""")
                    .option("partitionColumn", jdbc_partition_column)
                    .option("lowerBound", pkey_min)
                    .option("upperBound", pkey_max)
                    .option("numPartitions", numPartitions)
                    .load())

    def get_df_read_rds_db_tbl_pkey_between(self,
                                            in_table_name,
                                            jdbc_partition_column,
                                            jdbc_partition_col_lowerbound,
                                            jdbc_partition_col_upperbound,
                                            parallel_jdbc_conn_num
                                            ) -> DataFrame:

        numPartitions = parallel_jdbc_conn_num
        # Note: numPartitions is normally equal to number of executors defined.
        # The maximum number of partitions that can be used for parallelism in table reading and writing.
        # This also determines the maximum number of concurrent JDBC connections.

        query_str = f"""
        SELECT *
        FROM {self.rds_db_schema_name}.[{in_table_name}]
        WHERE {jdbc_partition_column} BETWEEN {jdbc_partition_col_lowerbound} AND {jdbc_partition_col_upperbound}
        """.strip()

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
                    .load())

    def get_rds_tbl_col_attributes(self, rds_db_table_name) -> DataFrame:

        sql_statement = f"""
        SELECT column_name, data_type, is_nullable 
          FROM information_schema.columns
         WHERE table_schema = '{self.rds_db_schema_name}'
           AND table_name = '{rds_db_table_name}'
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

    def get_rds_db_table_empty_df(self, rds_db_table_name) -> DataFrame:

        query_str = f"""
        SELECT *
          FROM {self.rds_db_schema_name}.[{rds_db_table_name}]
         WHERE 1 = 2
        """.strip()

        return (self.spark.read.format("jdbc")
                .option("url", self.rds_jdbc_url_v2)
                .option("driver", self.RDS_DB_INSTANCE_DRIVER)
                .option("user", self.RDS_DB_INSTANCE_USER)
                .option("password", self.RDS_DB_INSTANCE_PWD)
                .option("query", f"""{query_str}""")
                .load())

    def get_rds_db_query_df(self, rds_db_query) -> DataFrame:

        return (self.spark.read.format("jdbc")
                .option("url", self.rds_jdbc_url_v2)
                .option("driver", self.RDS_DB_INSTANCE_DRIVER)
                .option("user", self.RDS_DB_INSTANCE_USER)
                .option("password", self.RDS_DB_INSTANCE_PWD)
                .option("query", f"""{rds_db_query}""")
                .load())

    def get_jdbc_partition_column(self,
                                  rds_db_table_name,
                                  rds_tbl_pkeys_list):

        rds_db_table_empty_df = self.get_rds_db_table_empty_df(
            rds_db_table_name)
        df_rds_dtype_dict = CustomPysparkMethods.get_dtypes_dict(
            rds_db_table_empty_df)
        int_dtypes_colname_list = [colname for colname, dtype in df_rds_dtype_dict.items()
                                   if dtype in Logical_Constants.INT_DATATYPES_LIST]

        if rds_tbl_pkeys_list[0] in int_dtypes_colname_list:
            return rds_tbl_pkeys_list[0]
        else:
            return None

    def get_rds_db_tbl_pkey_col_max_value(self,
                                          in_table_name,
                                          in_pkey_col_name) -> DataFrame:

        query_str = f"""
        SELECT max({in_pkey_col_name}) as max_value
        FROM {self.rds_db_schema_name}.[{in_table_name}]
        """.strip()

        return (self.spark.read.format("jdbc")
                .option("url", self.rds_jdbc_url_v2)
                .option("driver", self.RDS_DB_INSTANCE_DRIVER)
                .option("user", self.RDS_DB_INSTANCE_USER)
                .option("password", self.RDS_DB_INSTANCE_PWD)
                .option("query", f"""{query_str}""")
                .load()).collect()[0].max_value

    def get_rds_df_between_pkey_ids(self,
                                    in_table_name,
                                    jdbc_partition_column,
                                    jdbc_partition_col_lowerbound,
                                    jdbc_partition_col_upperbound):

        query_str = f"""
        SELECT *
        FROM {self.rds_db_schema_name}.[{in_table_name}]
        WHERE {jdbc_partition_column} BETWEEN {jdbc_partition_col_lowerbound} AND {jdbc_partition_col_upperbound}
        """.strip()

        return (self.spark.read.format("jdbc")
                    .option("url", self.rds_jdbc_url_v2)
                    .option("driver", self.RDS_DB_INSTANCE_DRIVER)
                    .option("user", self.RDS_DB_INSTANCE_USER)
                    .option("password", self.RDS_DB_INSTANCE_PWD)
                    .option("dbtable", f"""({query_str}) as t""")
                    .load())

    def get_min_max_groupby_month(self,
                                  rds_db_table_name,
                                  date_partition_col,
                                  pkey_col_name,
                                  rds_query_where_clause):

        query_str = f"""
        SELECT YEAR({date_partition_col}) AS year, 
               MONTH({date_partition_col}) AS month, 
               MIN({pkey_col_name}) AS min_pkey_value, 
               MAX({pkey_col_name}) AS max_pkey_value
          FROM {self.rds_db_schema_name}.[{rds_db_table_name}]
        """.strip()

        if rds_query_where_clause is not None:
            query_str = query_str + \
                f""" WHERE {rds_query_where_clause.strip()}"""

        query_str = query_str + \
            f""" GROUP BY YEAR({date_partition_col}), MONTH({date_partition_col})"""

        self.LOGGER.info(f"""query_str-(Aggregate):> \n{query_str}""")

        df_agg = (self.spark.read.format("jdbc")
                .option("url", self.rds_jdbc_url_v2)
                .option("driver", self.RDS_DB_INSTANCE_DRIVER)
                .option("user", self.RDS_DB_INSTANCE_USER)
                .option("password", self.RDS_DB_INSTANCE_PWD)
                .option("query", f"""{query_str}""")
                .load())
        
        df_agg = df_agg.orderBy(['year', 'month'], ascending=True)

        return df_agg.collect()

    def get_min_max_pkey_filter(self,
                                rds_db_table_name,
                                pkey_col_name,
                                rds_query_where_clause=None):

        query_str = f"""
        SELECT min({pkey_col_name}) as min_value, max({pkey_col_name}) as max_value
          FROM {self.rds_db_schema_name}.[{rds_db_table_name}]
        """.strip()

        if rds_query_where_clause is not None:
            query_str = query_str + \
                f""" WHERE {rds_query_where_clause.strip()}"""

        self.LOGGER.info(
            f"""query_str-(Optional-Where clause):> \n{query_str}""")

        return (self.spark.read.format("jdbc")
                .option("url", self.rds_jdbc_url_v2)
                .option("driver", self.RDS_DB_INSTANCE_DRIVER)
                .option("user", self.RDS_DB_INSTANCE_USER)
                .option("password", self.RDS_DB_INSTANCE_PWD)
                .option("query", f"""{query_str}""")
                .load()).collect()[0]

# ---------------------------------------------------------------------
# PYTHON CLASS 'RDS_JDBC_CONNECTION' - END
# ---------------------------------------------------------------------


class AthenaMethods:

    ATHENA_CLIENT = boto3.client("athena",
                                 region_name='eu-west-2')

    def __init__(self, ATHENA_RUN_OUTPUT_LOCATION):
        self.ATHENA_RUN_OUTPUT_LOCATION = ATHENA_RUN_OUTPUT_LOCATION

    def run_athena_query(self, sql_statement_str):
        response = AthenaMethods.ATHENA_CLIENT.start_query_execution(
            QueryString=sql_statement_str,
            ResultConfiguration={
                "OutputLocation": self.ATHENA_RUN_OUTPUT_LOCATION}
        )
        return response["QueryExecutionId"]

    def has_query_succeeded(self, execution_id):
        state = "RUNNING"
        max_execution = 5

        while max_execution > 0 and state in ["RUNNING", "QUEUED"]:
            max_execution -= 1
            response = AthenaMethods.ATHENA_CLIENT.get_query_execution(
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

    S3_CLIENT = boto3.client("s3")

    @classmethod
    def get_s3_folder_info(cls, bucket_name, prefix):
        paginator = cls.S3_CLIENT.get_paginator('list_objects_v2')

        total_size = 0
        total_files = 0

        for page in paginator.paginate(Bucket=bucket_name, Prefix=prefix):
            for obj in page.get('Contents', []):
                total_files += 1
                total_size += obj['Size']

        return total_files, total_size

    @classmethod
    def check_s3_folder_path_if_exists(cls, in_bucket_name, in_folder_path):
        result = cls.S3_CLIENT.list_objects(
            Bucket=in_bucket_name, Prefix=in_folder_path)
        exists = False
        if 'Contents' in result:
            exists = True
        return exists

    @classmethod
    def get_list_of_db_tbl_prq_file_paths(cls, in_bucket_name, in_db_sch_tbl_path):
        temp_list = list()
        response = cls.S3_CLIENT.list_objects_v2(
            Bucket=in_bucket_name,
            Prefix=in_db_sch_tbl_path)

        for content in response.get('Contents', []):
            temp_list.append(content['Key'])

        return temp_list


class CustomPysparkMethods:

    @staticmethod
    def get_pyspark_empty_df(in_empty_df_schema) -> DataFrame:
        return SparkSession.spark.createDataFrame(
            SparkSession.sc.emptyRDD(),
            schema=in_empty_df_schema
        )

    @staticmethod
    def get_s3_table_folder_path(rds_jdbc_conn_obj,
                                 in_parquet_files_bucket_name,
                                 target_table_folder):

        dir_path_str = f"{rds_jdbc_conn_obj.rds_db_name}/{rds_jdbc_conn_obj.rds_db_schema_name}/{target_table_folder}"

        tbl_full_dir_path_str = f"s3://{in_parquet_files_bucket_name}/{dir_path_str}/"

        if S3Methods.check_s3_folder_path_if_exists(in_parquet_files_bucket_name, dir_path_str):
            return tbl_full_dir_path_str
        else:
            SparkSession.LOGGER.info(
                f"{tbl_full_dir_path_str} -- Table-Folder-S3-Path Not Found !")
            return None

    @staticmethod
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

    @staticmethod
    def get_dtypes_dict(in_rds_df: DataFrame):
        return {name: dtype for name, dtype in in_rds_df.dtypes}

    @staticmethod
    def declare_empty_df_dv_output_v1():
        sql_select_str = f"""
        select cast(null as timestamp) as run_datetime,
        cast(null as string) as json_row,
        cast(null as string) as validation_msg,
        cast(null as string) as database_name,
        cast(null as string) as full_table_name,
        cast(null as string) as table_to_ap
        """.strip()

        return SparkSession.spark.sql(sql_select_str).repartition(2)

    @staticmethod
    def get_s3_parquet_df_v1(in_s3_parquet_folder_path, in_rds_df_schema) -> DataFrame:
        return SparkSession.spark.createDataFrame(
            SparkSession.spark.read.parquet(in_s3_parquet_folder_path).rdd, in_rds_df_schema)

    @staticmethod
    def get_s3_parquet_df_v2(in_s3_parquet_folder_path,
                             in_rds_df_schema) -> DataFrame:
        return SparkSession.spark.read.schema(in_rds_df_schema).parquet(in_s3_parquet_folder_path)

    @staticmethod
    def get_s3_parquet_df_v3(in_s3_parquet_folder_path, in_rds_df_schema) -> DataFrame:
        return SparkSession.spark.read.format("parquet").load(in_s3_parquet_folder_path,
                                                              schema=in_rds_df_schema)

    @staticmethod
    def rds_df_trim_str_columns(in_rds_df: DataFrame) -> DataFrame:
        return (in_rds_df.select(
                *[F.trim(F.col(c[0])).alias(c[0]) if c[1] == 'string' else F.col(c[0])
                  for c in in_rds_df.dtypes])
                )

    @staticmethod
    def rds_df_trim_str_columns_v2(in_rds_df: DataFrame,
                                   in_rds_df_trim_str_col_list) -> DataFrame:
        string_dtype_columns = [c[0] for c in in_rds_df.dtypes
                                if c[1] == 'string']
        count = 0
        for trim_colmn in in_rds_df_trim_str_col_list:
            if trim_colmn in string_dtype_columns:
                if count == 0:
                    rds_df = in_rds_df.withColumn(
                        trim_colmn, F.trim(F.col(trim_colmn)))
                    count += 1
                else:
                    rds_df = rds_df.withColumn(
                        trim_colmn, F.trim(F.col(trim_colmn)))
            else:
                SparkSession.LOGGER.warn(
                    f"""rds_df_trim_str_columns: {trim_colmn} is not a string dtype column.""")
        return rds_df

    @staticmethod
    def rds_df_trim_microseconds_timestamp(in_rds_df: DataFrame,
                                           in_col_list) -> DataFrame:
        return (in_rds_df.select(
                *[F.date_format(F.col(c[0]), 'yyyy-MM-dd HH:mm:ss.SSS').alias(c[0]).cast('timestamp')
                  if c[1] == 'timestamp' and c[0] in in_col_list else F.col(c[0])
                  for c in in_rds_df.dtypes])
                )

    @staticmethod
    def get_rds_tbl_col_attr_dict(df_col_stats: DataFrame) -> DataFrame:
        key_col = 'column_name'
        value_col = 'is_nullable'
        return (df_col_stats.select(key_col, value_col)
                .rdd.map(lambda row: (row[key_col], row[value_col])).collectAsMap())

    @staticmethod
    def get_nvl_select_list(in_rds_df: DataFrame,
                            rds_jdbc_conn_obj,
                            in_rds_tbl_name):
        df_col_attr = rds_jdbc_conn_obj.get_rds_tbl_col_attributes(in_rds_tbl_name)
        df_col_attr_dict = CustomPysparkMethods.get_rds_tbl_col_attr_dict(df_col_attr)
        df_col_dtype_dict = CustomPysparkMethods.get_dtypes_dict(in_rds_df)

        temp_select_list = list()
        for colmn in in_rds_df.columns:
            if df_col_attr_dict[colmn] == 'YES' and \
                (not df_col_dtype_dict[colmn].startswith("decimal")) and \
                    (not df_col_dtype_dict[colmn].startswith("binary")):

                temp_select_list.append(
                    f"""nvl({colmn}, {Logical_Constants.NVL_DTYPE_DICT[df_col_dtype_dict[colmn]]}) as {colmn}""")
            else:
                temp_select_list.append(colmn)
        return temp_select_list

    @staticmethod
    def rds_df_strip_tbl_col_chars(in_rds_df: DataFrame,
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

    @staticmethod
    def get_reordered_columns_schema_object(in_df_rds: DataFrame,
                                            in_transformed_column_list):
        altered_schema_object = T.StructType([])
        rds_df_column_list = in_df_rds.schema.fields

        for colmn in in_transformed_column_list:
            if colmn not in rds_df_column_list:
                SparkSession.LOGGER.error(f"""
                Given transformed column '{colmn}' is not an existing RDS-DB-Table-Column! Exiting ...
                """.strip())
                sys.exit(1)

        for field_obj in in_df_rds.schema.fields:
            if field_obj.name not in in_transformed_column_list:
                altered_schema_object.add(field_obj)
        else:
            for field_obj in in_df_rds.schema.fields:
                if field_obj.name in in_transformed_column_list:
                    altered_schema_object.add(field_obj)
        return altered_schema_object

    @staticmethod
    def get_rds_db_tbl_customized_cols_schema_object(in_df_rds: DataFrame,
                                                     in_customized_column_list):
        altered_schema_object = T.StructType([])
        rds_df_column_list = in_df_rds.columns

        for colmn in in_customized_column_list:
            if colmn not in rds_df_column_list:
                SparkSession.LOGGER.error(f"""
                Given primary-key column '{colmn}' is not an existing RDS-DB-Table-Column!
                rds_df_column_list = {rds_df_column_list}
                """.strip())
                SparkSession.LOGGER.warn("Exiting ...")
                sys.exit(1)

        for field_obj in in_df_rds.schema.fields:
            if field_obj.name in in_customized_column_list:
                altered_schema_object.add(field_obj)

        return altered_schema_object

    @staticmethod
    def get_pyspark_hashed_table_schema(in_pkey_column, sf_list=None):
        if sf_list is None:
            return T.StructType([
                T.StructField(f"{in_pkey_column}", T.LongType(), False),
                T.StructField("RowHash", T.StringType(), False)]
                )
        else:
            schema = T.StructType([
                T.StructField(f"{in_pkey_column}", T.LongType(), False)]
                )
            
            for sf in sf_list:
                schema = schema.add(sf)
            
            schema = schema.add(T.StructField("RowHash", T.StringType(), False))

            return schema

    @staticmethod
    def get_year_month_min_max_count_schema(in_pkey_column_str):

        agg_schema = T.StructType([
                T.StructField("year", T.IntegerType(), False),
                T.StructField("month", T.IntegerType(), False),
                T.StructField(f"min_{in_pkey_column_str}", T.LongType(), False),
                T.StructField(f"max_{in_pkey_column_str}", T.LongType(), False),
                T.StructField(f"count_{in_pkey_column_str}", T.LongType(), False)]
                )
        return agg_schema

    @staticmethod
    def update_df1_with_df2(df1: DataFrame, df2: DataFrame, 
                            all_remaining_columns_list,
                            join_columns_list = ['year', 'month']):
        #agg_schema = __class__.get_year_month_min_max_count_schema()

        # Step 1: Find unmatched rows from df1 / df_parquet
        df_unmatched_rows = df1.join(df2, join_columns_list, "left_anti")

        # Step 2: Update matched rows between df2 / df_JDBC AND df1 / df_parquet
        update_columns_select = [df2[c].alias(c) for c in all_remaining_columns_list]
        key_columns_select = [df1[c] for c in join_columns_list]
        df_updated_rows = df1.join(df2, join_columns_list, "inner") \
            .select(
                *key_columns_select,
                *update_columns_select
            )

        # Step 3: Include new rows from df2 / df_JDBC not in df1 / df_parquet
        df_new_rows = df2.join(df1, join_columns_list, "left_anti")

        # Step 4: Combine all type of rows in dataframes
        final_df = df_unmatched_rows.union(df_updated_rows).union(df_new_rows)

        final_df = final_df.orderBy(join_columns_list)

        return final_df
