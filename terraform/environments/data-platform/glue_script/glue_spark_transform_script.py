import logging
import os
import re
import sys

import boto3
from botocore.exceptions import ClientError
from pathlib import Path
from awsglue.context import GlueContext
from awsglue.dynamicframe import DynamicFrame
from awsglue.job import Job
from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from pyspark.sql import SparkSession
from pyspark.sql import functions as F
from pyspark.sql.functions import lit
from transform import generate_report, get_tables


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
    m = re.match("^(raw_data)\/(.*)\/(.*)\/(extraction_timestamp=[0-9]{1,14})\/(.*)$", raw_key)
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
            "Table partition extraction_timestamp is not in the expected format"
        )


def get_curated_path(db_name, table_name) -> str:
    """
    creates path for curated data product
    """
    out_path = os.path.join(
        "s3://",
        bucket,
        "curated_data",
        f"database_name={db_name}",
        f"table_name={table_name}"
    )
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


def does_database_exist(client, database_name) -> bool:
    """Determine if this database exists in the Data Catalog
    The Glue client will raise an exception if it does not exist.
    """
    try:
        client.get_database(Name=database_name)
        return True
    except client.exceptions.EntityNotFoundException:
        return False


def create_table_if_curated_data_exists(
    database_name, table_name, glue_client
) -> None:
    """
    creates a glue catalog table using boto3 for when curated data
    already exists but table does not.
    """
    table_path = get_curated_path(database_name, table_name)

    # get dynamic frame from s3 and get schema
    ddf = glue_context.create_dynamic_frame_from_options(
        "s3",
        {"paths": [table_path]},
        format="parquet")

    schema = ddf.schema()

    # types are ok for glue catalog unless long, which needs converting
    column_list = [
        {"Name": col["name"], "Type": col["container"]["dataType"]}
        if not col["container"]["dataType"] == "long"
        else {"Name": col["name"], "Type": "bigint"}
        for col in schema.jsonValue()["fields"]
    ]

    glue_client.create_table(
        DatabaseName=database_name,
        TableInput={
            'Name': table_name,
            'StorageDescriptor': {
                'Columns': column_list,
                'Location': table_path,
                "InputFormat": "org.apache.hadoop.hive.ql.io.parquet.MapredParquetInputFormat",
                "OutputFormat": "org.apache.hadoop.hive.ql.io.parquet.MapredParquetOutputFormat",
                "SerdeInfo": {
                "SerializationLibrary": "org.apache.hadoop.hive.ql.io.parquet.serde.ParquetHiveSerDe",
                "Parameters": {}
                }
            },
            'PartitionKeys': [
                {
                    'Name': 'extraction_timestamp',
                    'Type': 'string',
                },
            ],
            "TableType": "EXTERNAL_TABLE"
        }
    )
    sts_client = boto3.client("sts")
    account_id = sts_client.get_caller_identity()["Account"]
    athena_client = boto3.client("athena")

    # need to refresh partitions
    athena_client.start_query_execution(
        QueryString=f"MSCK REPAIR TABLE {database_name}.{table_name}",
        ResultConfiguration={
            'OutputLocation': f"athena-data-product-query-results-{account_id}"
        }
    )


database_name = get_database_name()
# get table names produced for this source data
source_data = Path(raw_key).parts[2]
table_names = get_tables(bucket, raw_key, source_data)[database_name]

logging.info(f"table names: {table_names}")

timestamp = get_extraction_timestamp()
create_curated_data = {}
for table_name in table_names:
    logging.info(
        "checking if partition already exists for "
        f"{database_name}.{table_name} where extraction_timestamp={timestamp}"
    )

    if does_extraction_timestamp_exist(database_name, table_name, timestamp):
        create_curated_data[table_name] = False
    else:
        create_curated_data[table_name] = True
        # load transformed data to pandas dataframe and get db and table name

database_dict = generate_report(bucket, raw_key)

tables_to_process = [
    (database_name, table)
    for database_name in database_dict.keys()
    for table in database_dict[database_name].keys()
    if create_curated_data[table_name]
]

tables_to_check_exist = [
    (database_name, table)
    for database_name in database_dict.keys()
    for table in database_dict[database_name].keys()
    if not create_curated_data[table_name]
]

glue_client = boto3.client("glue")

for database_name, table_name in tables_to_check_exist:
    try:
        glue_client.get_table(
            DatabaseName=database_name,
            Name=table_name
        )
    except ClientError as e:
        if e.response['Error']['Code'] == 'EntityNotFoundException':
            if e.response['Message'].startswith('Database'):
                glue_client.create_database(
                    DatabaseInput={
                        "Name": database_name,
                        "Description": "just a test for now"
                    }
                )
                create_table_if_curated_data_exists(
                    database_name, table_name, glue_client
                )
                logging.info(f"database and table {database_name}.{table_name} didn't exist where curated did and have been created")
            elif e.response['Message'].startswith('Table'):
                create_table_if_curated_data_exists(
                    database_name, table_name, glue_client
                )
                logging.info(f"table {database_name}.{table_name} didn't exist where curated did and has been created")

for database_name, table_name in tables_to_process:
    # convert dataframe into pyspark create_dynamic_frame.
    pd_df = database_dict[database_name][table_name]
    spark_df = spark.createDataFrame(pd_df)

    # replace spaces and brackets with underscores in column names
    exprs = [
        F.col(column).alias(replace_space_in_string(column))
        for column in spark_df.columns
    ]
    renamed_df = spark_df.select(*exprs)

    renamed_df = renamed_df.withColumn("extraction_timestamp", lit(timestamp))

    dynamic_frame = DynamicFrame.fromDF(renamed_df, glue_context, "dynamic_frame")

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
    # but we want to make sure the table does exists even if we don't
    # make curated version of the data table
