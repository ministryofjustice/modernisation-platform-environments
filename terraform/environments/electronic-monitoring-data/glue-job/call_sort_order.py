
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
                                     "order_col",
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

command = f"""CALL glue_catalog.system.rewrite_data_files(table => {args['database']}.{args['table']}, strategy => 'sort', sort_order => '{args['order_col']} {args['order']}', options => map('rewrite-all', 'true'))"""

try:
    logger.info("Attempting to apply sort order...")
    spark.sql(command)
    logger.info("Sort called.")

except Exception as e:
    logger.error("Failed.")
    raise e