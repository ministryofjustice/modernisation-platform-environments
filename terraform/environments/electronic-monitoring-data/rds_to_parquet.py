import sys
from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from awsglue.context import GlueContext

# Get Glue context
args = getResolvedOptions(sys.argv, ["JOB_NAME"])
sc = SparkContext()
glueContext = GlueContext(sc)
spark = glueContext.spark_session

# Define source and target paths
source_database = "db_name"
s3_output_path = f"s3://rds_to_parquet-xzytxuzytuzyt/{source_database}"

# Get list of tables in the database
table_list = glueContext.get_tables(database=source_database)

for table in table_list:
    # Read data from the table
    dynamic_frame = glueContext.create_dynamic_frame.from_catalog(
        database=table.database_name, table_name=table.name
    )

    # Convert DynamicFrame to DataFrame
    data_frame = dynamic_frame.toDF()

    # Write DataFrame to Parquet in S3
    output_table_path = f"{s3_output_path}/{table.name}/"
    data_frame.write.parquet(output_table_path)

    print(f"Table {table.name} processed and saved to {output_table_path}")

# Job completion message
print("Job completed successfully!")
