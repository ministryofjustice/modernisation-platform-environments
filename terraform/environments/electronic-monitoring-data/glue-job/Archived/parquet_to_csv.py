import sys
from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from awsglue.context import GlueContext
from awsglue.job import Job
import boto3
from logging import getLogger

logger = getLogger(__name__)

# Set up Glue context and job
args = getResolvedOptions(sys.argv, ["JOB_NAME", "source_bucket", "destination_bucket"])
sc = SparkContext()
glueContext = GlueContext(sc)
spark = glueContext.spark_session
job = Job(glueContext)
job.init(args["JOB_NAME"], args)
s3 = boto3.client("s3")

# Source and destination buckets
source_bucket = args["source_bucket"]
destination_bucket = args["destination_bucket"]
source_path = f"s3://{source_bucket}/"
destination_path = f"s3://{destination_bucket}/"

logger.info(f"Reading from {source_bucket}, writing to {destination_bucket}.")


def get_tables_from_s3_path(s3_client, bucket_name=source_bucket):
    # Pagination
    paginator = s3_client.get_paginator("list_objects_v2")
    response_iterator = paginator.paginate(Bucket=bucket_name)

    for page in response_iterator:
        keys = [obj["Key"] for obj in page.get("Contents", [])]
    filered_keys = [key for key in keys if ".parquet" in key]

    database_table_pairs = list(
        set([(key.split("/")[0], key.split("/")[2]) for key in filered_keys])
    )

    result = {}

    for key, value in database_table_pairs:
        if key in result:
            result[key].append(value)
        else:
            result[key] = [value]

    # Convert the lists to sets to remove duplicate table names
    for key in result:
        result[key] = list(set(result[key]))
    print_result = "".join(f"{key}.{value}" for key, value in result.items())
    logger.info(f"Tables to download: {print_result}")
    return result


databases = get_tables_from_s3_path(s3)

# Iterate over each database
for database in databases:
    database_name = database
    logger.info(f"Reading database: {database_name}.")

    # Get list of tables in the current database
    tables = databases[database]

    # Iterate over each table in the current database
    for table in tables:
        table_name = table
        logger.info(f"Reading table: {table_name} in database: {database_name}.")

        # Construct source and destination paths for the current table
        source_table_path = f"{source_path}/{database_name}/dbo/{table_name}"
        destination_table_path = f"{destination_path}/{database_name}/{table_name}"

        # Convert Parquet to DataFrame
        dataframe = spark.read.parquet(source_table_path)

        # Write DataFrame to CSV format with size check and splitting
        (
            dataframe.write.option("header", "true")
            .option("maxPartitionBytes", 5 * 1024 * 1024 * 1024)
            .csv(destination_table_path, mode="overwrite")
        )
        logger.info(f"Written {table_name} in {database_name} to {destination_path}.")

job.commit()
