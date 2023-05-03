import logging
import os
import re
import sys

import boto3
from awsglue.context import GlueContext
from awsglue.dynamicframe import DynamicFrame
from awsglue.job import Job
from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from pyspark.sql import SparkSession
from pyspark.sql import functions as F
from pyspark.sql.functions import lit
from transform import generate_report, report_name


logging.getLogger().setLevel(logging.INFO)

args = getResolvedOptions(sys.argv, ["JOB_NAME", "bucketName", "key"])

logging.info(f"args: {args}")

# set arguments
bucket = args["bucketName"]
raw_key = args["key"]

# setup spark
sc = SparkContext()
glue_context = GlueContext(sc)
spark = glue_context.spark_session
job = Job(glue_context)
job.init(args["JOB_NAME"], args)


def get_database_name() -> str:
    """
    returns database name from the key of the raw data product
    """
    # database name is the data product name pulled from the key
    m = re.match("^(raw_data)\/(.*)\/(extraction_timestamp=[0-9]{1,14})\/(.*)$", raw_key)
    if m:
        return m.group(2)
    else:
        ValueError("Key not in expected format")


def get_extraction_timestamp() -> str:
    """
    uses regex pattern to pull and return extraction_timestamp from filepath
    """
    pattern = "^(.*)\/(extraction_timestamp=)([0-9]{1,14})\/(.*)$"
    m = re.match(pattern, raw_key)
    if m:
        return m.group(3)
    else:
        raise ValueError(
            "Table partition extratction_timestamp is not in the expected format"
        )


def get_curated_path(db_name, table_name) -> str:
    """
    creates path for curated data product
    """
    key_list = os.path.join(
        "s3://", bucket, raw_key.replace("raw_data", "curated_data")
    ).split("/")
    out_path = "/".join(key_list[:-2])
    out_path = out_path.replace(db_name, f"database_name={db_name}")
    out_path = os.path.join(out_path, f"table_name={table_name}")
    return out_path


def does_extraction_timestamp_exist(db_name, table_name, timestamp) -> bool:
    """
    returns bool indicating whether the extraction timestamp for
    a data product already exists
    """

    db_path = f"database_name={db_name}"
    table_path = f"table_name={table_name}"
    client = boto3.client("s3")
    paginator = client.get_paginator("list_objects_v2")
    page_iterator = paginator.paginate(
        Bucket=bucket,
        Prefix=os.path.join("curated_data", db_path, table_path)
    )
    response = []
    try:
        for page in page_iterator:
            response += page["Contents"]
    except KeyError as e:
        logging.error(
            f"No {e} key found at data product curated path – the database"
            " doesn't exist and will be created"
        )
    ts_exists = any(f"extraction_timestamp={timestamp}" in i["Key"] for i in response)
    return ts_exists


def replace_space_in_string(name: str) -> str:
    """
    If a string contains space inbetween, then replace by underscore.
    If it contains brackets then remove them.
    """
    replaced_name = name.strip().replace(" ", "_").replace("(", "").replace(")", "")
    return replaced_name


def does_database_exist(client, database_name):
    """Determine if this database exists in the Data Catalog
    The Glue client will raise an exception if it does not exist.
    """
    try:
        client.get_database(Name=database_name)
        return True
    except client.exceptions.EntityNotFoundException:
        return False


database_name = get_database_name()
table_name = report_name
timestamp = get_extraction_timestamp()


logging.info(
    "checking if partition already exists for "
    f"{database_name}.{table_name} where extraction_timestamp={timestamp}"
)

if not does_extraction_timestamp_exist(database_name, table_name, timestamp):
    # load transformed data to pandas dataframe and get db and table name
    pd_df = generate_report(bucket, raw_key)

    # convert dataframe into pyspark create_dynamic_frame.
    spark_df = spark.createDataFrame(pd_df)

    # replace spaces and brackets with underscores in column names
    exprs = [
        F.col(column).alias(replace_space_in_string(column))
        for column in spark_df.columns
    ]
    renamed_df = spark_df.select(*exprs)

    renamed_df = renamed_df.withColumn("extraction_timestamp", lit(timestamp))

    dynamic_frame = DynamicFrame.fromDF(renamed_df, glue_context, "dynamic_frame")

    glue_client = boto3.client("glue")

    if not does_database_exist(glue_client, database_name):
        logging.info("creating database")
        glue_client.create_database(
            DatabaseInput={
                "Name": database_name,
                "Description": "just a test for now"
            }
        )

    output_path = get_curated_path(database_name, table_name)
    logging.info("Attempting to register to Glue Catalogue")

    try:
        sink = glue_context.getSink(
            connection_type="s3",
            path=output_path,
            enableUpdateCatalog=True,
            updateBehavior="UPDATE_IN_DATABASE",
            partitionKeys=["extraction_timestamp"],
        )

        sink.setFormat("glueparquet")
        sink.setCatalogInfo(catalogDatabase=database_name, catalogTableName=table_name)
        sink.writeFrame(dynamic_frame)
        logging.info(f"Write out of file succeeded to {output_path}")
    except Exception as e:
        logging.error(f"Could not convert {raw_key} to glue table, due to an error!")
        logging.error(e)
else:
    logging.info("Partition for timestamp already exists")
