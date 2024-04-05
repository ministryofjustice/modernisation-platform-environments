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
source_bucket = args["source_bucket"]
destination_bucket = args["destination_bucket"]
source_path = "s3://{}/".format(source_bucket)
destination_path = "s3://{}/".format(destination_bucket)

# Maximum size for each CSV file (in bytes)
max_csv_size = 5 * 1024 * 1024 * 1024  # 5GB


# Function to write DataFrame to CSV with size check and splitting
def write_dataframe_to_csv(dataframe, destination_path):
    # Check the size of the DataFrame
    dataframe_size = dataframe.rdd.map(lambda x: len(str(x))).reduce(lambda x, y: x + y)

    # If the size exceeds the maximum CSV size, split it into smaller chunks
    if dataframe_size > max_csv_size:
        # Split the DataFrame into smaller chunks
        num_chunks = dataframe.rdd.getNumPartitions()
        smaller_dataframes = dataframe.randomSplit([1.0 / num_chunks] * num_chunks)

        # Write each smaller DataFrame to CSV
        for idx, df_chunk in enumerate(smaller_dataframes):
            df_chunk.write.option("header", "true").csv(
                "{}/part_{}".format(destination_path, idx), mode="overwrite"
            )
    else:
        # Write the entire DataFrame to a single CSV file
        dataframe.write.option("header", "true").csv(destination_path, mode="overwrite")


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

        # Write DataFrame to CSV format with size check and splitting
        write_dataframe_to_csv(dataframe, destination_table_path)

job.commit()
