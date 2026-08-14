
"""Apply a sort_order to an Iceberg table to allow sort compaction."""
import sys
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from awsglue.context import GlueContext


args = getResolvedOptions(sys.argv, ["JOB_NAME",
                                     "catalog",
                                     "database",
                                     "table",
                                     "order_col",
                                     "order",
                                     "order_cols",
                                     ])


sc = SparkContext.getOrCreate()
glue_context = GlueContext(sc)
logger = glue_context.get_logger()

spark = glue_context.spark_session


sort_order_command = f"ALTER TABLE {args["catalog"]}.{args["database"]}.{args["table"]} WRITE ORDERED BY ({args["order_col"]} {args["order"]});"
# z_sort_command = f"ALTER TABLE {args["catalog"]}.{args["database"]}.{args["table"]} WRITE ORDERED BY {args["order_cols"]};"

try:
    spark.sql(sort_order_command)
    logger.info("Sort order applied.")
except Exception as e:
    logger.error("Failed.")
    raise e
