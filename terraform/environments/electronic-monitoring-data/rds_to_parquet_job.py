import sys
from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from awsglue.context import GlueContext
from pyspark.sql.function import unix_timestamp

# Get Glue context
args = getResolvedOptions(sys.argv, ["JOB_NAME", "database_name", "table_name"])
sc = SparkContext()
glueContext = GlueContext(sc)
spark = glueContext.spark_session

# Define source and target paths
source_database = args["database_name"]
source_table = args["table_name"]
s3_output_path = f"s3://rds_to_parquet-xzytxuzytuzyt/{source_database}/{source_table}/"


# Read data from the table
dynamic_frame = glueContext.create_dynamic_frame.from_catalog(
    database=source_database, table_name=source_table
)

# Convert DynamicFrame to DataFrame
data_frame = dynamic_frame.toDF()
current_time = unix_timestamp()
# Write DataFrame to Parquet in S3
output_table_path = f"{s3_output_path}/{current_time}/"
data_frame.write.parquet(output_table_path)

print(
    f"Table {source_table} in {source_database} processed and saved to {output_table_path}"
)

# Job completion message
print("Job completed successfully!")
