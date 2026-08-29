"""Apply a sort_order to an Iceberg table to allow sort compaction."""
import sys
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from awsglue.context import GlueContext


args = getResolvedOptions(sys.argv, ["JOB_NAME",
                                     "catalog",
                                     "database",
                                     "table",
                                     "order", 
                                     "order_cols",
                                     ])


# set spark session
sc = SparkContext.getOrCreate()
glue_context = GlueContext(sc)
logger = glue_context.get_logger()

spark = glue_context.spark_session
spark.sparkContext.setLogLevel("DEBUG")

# debugging
logger.info(f"SPARK VERSION: {spark.version}")
logger.info(f"SPARK CONTEXT CONFIG: {spark.sparkContext.getConf().getAll()}")
logger.info(f'SPARK SQL EXTENSIONS: {spark.conf.get("spark.sql.extensions", "NOT SET")}')

replace = f"""REPLACE TABLE {args['database']}.{args['table']} AS SELECT * FROM {args['database']}.{args['table']}"""
alter = f"""ALTER TABLE {args['database']}.{args['table']} WRITE ORDERED BY {args['order_cols']}"""
insert = f"""INSERT TABLE {args['database']}.{args['table']} SELECT * FROM {args['database']}.{args['table']};"""

try:
    logger.info("Attempting to apply sort order...")
    spark.sql(replace)
    logger.info("Replace run.")
    spark.sql(alter)
    logger.info("Alter run.")
    spark.sql(insert)
    logger.info("Insert run.")

except Exception as e:
    logger.error("Failed.")
    raise e