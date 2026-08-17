
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

sort_order_command = f"""ALTER TABLE {args['catalog']}.{args['database']}.{args['table']} WRITE ORDERED BY ({args['order_col']} {args['order']});"""
z_sort_command = f"""ALTER TABLE {args['catalog']}.{args['database']}.{args['table']} WRITE ORDERED BY {args['order_cols']};"""
remove_sort_order_command = f"""ALTER TABLE {args['catalog']}.{args['database']}.{args['table']} WRITE UNORDERED;"""

try:
    logger.info("Attempting to apply sort order...")

    if args['remove_sort_order'] == "true":
        spark.sql(remove_sort_order_command)
        logger.info("Sort order removed.")

    elif args['order_col'] != "false":
        spark.sql(sort_order_command)
        logger.info("Sort order set.")

    elif args['order_cols'] != "false":
        spark.sql(z_sort_command)
        logger.info("Z-Sort order applied.")

    else:
        msg = "either `remove_sort_order`, `order_col`, or `order_cols` must be set."
        raise ValueError(msg)

except Exception as e:
    logger.error("Failed.")
    raise e

