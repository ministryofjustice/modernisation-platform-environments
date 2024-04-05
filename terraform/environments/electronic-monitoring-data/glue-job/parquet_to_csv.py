import sys
from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from awsglue.context import GlueContext
from awsglue.job import Job

# Set up Glue context and job
args = getResolvedOptions(sys.argv, ["JOB_NAME"])
sc = SparkContext()
glueContext = GlueContext(sc)
spark = glueContext.spark_session
job = Job(glueContext)
job.init(args["JOB_NAME"], args)

# Source and destination buckets
source_bucket = "source-bucket-name"
destination_bucket = "destination-bucket-name"
source_path = "s3://{}/".format(source_bucket)
destination_path = "s3://{}/".format(destination_bucket)

# Get list of databases in the source bucket
databases = glueContext.list_databases()

# Iterate over each database
for database in databases:
    database_name = database["Name"]

    # Get list of tables in the current database
    tables = glueContext.get_tables(database_name)

    # Iterate over each table in the current database
    for table in tables:
        table_name = table.name

        # Construct source and destination paths for the current table
        source_table_path = "{}/{}".format(source_path, table_name)
        destination_table_path = "{}/{}/{}".format(
            destination_path, database_name, table_name
        )

        # Read Parquet files from the current table in the source bucket
        datasource = glueContext.create_dynamic_frame.from_catalog(
            database=database_name,
            table_name=table_name,
            transformation_ctx="datasource",
        )

        # Convert Parquet to DataFrame
        dataframe = datasource.toDF()

        # Write DataFrame to CSV format in the destination bucket
        dataframe.write.option("header", "true").csv(
            destination_table_path, mode="overwrite"
        )

job.commit()
