"""Apply a sort_order to an Iceberg table to allow sort compaction."""
import sys
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from awsglue.context import GlueContext


args = getResolvedOptions(sys.argv, ["JOB_NAME",
                                     "catalog",
                                     "database",
                                     "table",
                                     "remove_sort_order",
                                     "order", 
                                     "order_col",
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
# iceberg_version = spark._jvm.org.apache.iceberg.Version.getVersion()
# logger.info(f"ICEBERG VERSION: {iceberg_version}")
logger.info(f"SPARK CONTEXT CONFIG: {spark.sparkContext.getConf().getAll()}")
logger.info(f'SPARK SQL EXTENSIONS: {spark.conf.get("spark.sql.extensions", "NOT SET")}')

sort_order = f"""ALTER TABLE `{args['catalog']}`.{args['database']}.{args['table']} WRITE ORDERED BY {args['order_col']} {args['order']}"""
z_sort = f"""ALTER TABLE `{args['catalog']}`.{args['database']}.{args['table']} WRITE ORDERED BY {args['order_cols']}"""
remove_sort_order = f"""ALTER TABLE `{args['catalog']}`.{args['database']}.{args['table']} WRITE UNORDERED"""

# spark.sql(f"""
# EXPLAIN EXTENDED
# ALTER TABLE {args['database']}.{args['table']}
# WRITE ORDERED BY {args['order_col']} ASC
# """).show(truncate=False)

try:
    logger.info("Attempting to apply sort order...")

    if args['remove_sort_order'] == "true":
        spark.sql(remove_sort_order)
        logger.info("Sort order removed.")

    elif args['order_col'] != "false":
        logger.info(f"command: >>>>>> {sort_order}")
        spark.sql(sort_order)
        logger.info("Sort order set.")

    elif args['order_cols'] != "false":
        spark.sql(z_sort)
        logger.info("Z-Sort order applied.")

    else:
        msg = "either `remove_sort_order`, `order_col`, or `order_cols` must be set."
        raise ValueError(msg)

except Exception as e:
    logger.error("Failed.")
    raise e