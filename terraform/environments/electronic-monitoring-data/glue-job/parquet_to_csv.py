import sys
from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from awsglue.context import GlueContext
from awsglue.job import Job
import boto3

# Set up Glue context and job
args = getResolvedOptions(sys.argv, ["JOB_NAME"])
sc = SparkContext()
glueContext = GlueContext(sc)
spark = glueContext.spark_session
job = Job(glueContext)
job.init(args["JOB_NAME"], args)
s3 = boto3.client("s3")

# Source and destination buckets
source_bucket = args["source_bucket"]
destination_bucket = args["destination_bucket"]
source_path = "s3://{}/".format(source_bucket)
destination_path = "s3://{}/".format(destination_bucket)


def get_tables_from_s3_path(s3_client, bucket_name="dms-em-rds-output"):
    # Pagination
    paginator = s3_client.get_paginator("list_objects_v2")
    response_iterator = paginator.paginate(Bucket=bucket_name)

    for page in response_iterator:
        keys = [obj["Key"] for obj in page.get("Contents", [])]

    database_table_pairs = list(
        set([(key.split("/")[0], key.split("/")[2]) for key in keys])
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

    return result


databases = get_tables_from_s3_path(s3)
# Iterate over each database
for database in databases:
    database_name = database

    # Get list of tables in the current database
    tables = databases[database]

    # Iterate over each table in the current database
    for table in tables:
        table_name = table

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
        dataframe.write.option("header", "true").option(
            "maxPartitionBytes", 5 * 1024 * 1024
        ).csv(destination_path, mode="overwrite")

job.commit()
