import awswrangler as wr
from mojap_metadata.converters.glue_converter import GlueConverter, GlueConverterOptions
from mojap_metadata import Metadata
from aws_lambda_powertools import Logger
from aws_lambda_powertools.utilities.typing import LambdaContext

import os
import boto3

s3 = boto3.client("s3")
glue_client = boto3.client("glue")
lambda_client = boto3.client("lambda")

logger = Logger()

DB_NAME = os.environ.get("DB_NAME")
S3_BUCKET_NAME = os.environ.get("S3_BUCKET_NAME")

db_path = f"{S3_BUCKET_NAME}/{DB_NAME}/dbo"
db_sem_name = f"{DB_NAME}_semantic_layer"


def create_glue_table(metadata):
    table_name = metadata.name
    logger.info(f"Table Name: {table_name}")
    try:
        # Delete table
        wr.catalog.delete_table_if_exists(database=db_sem_name, table=table_name)
        logger.info(f"Delete table {table_name} in database {db_sem_name}")
    except s3.exceptions.from_code("EntityNotFoundException"):
        logger.info(f"Database '{db_sem_name}' table '{table_name}' does not exist")
    options = GlueConverterOptions()
    options.csv.skip_header = True
    gc = GlueConverter(options)
    boto_dict = gc.generate_from_meta(
        metadata,
        database_name=db_sem_name,
        table_location=f"s3://{db_path}/{table_name}",
    )
    glue_client.create_table(**boto_dict)
    return boto_dict


@logger.inject_lambda_context
def handler(event: dict, context: LambdaContext) -> str:
    logger.info(event)
    meta_dict = event["message"]
    meta = Metadata.from_dict(meta_dict)
    boto_dict = create_glue_table(meta)
    table_name = boto_dict["TableInput"]["Name"]
    result = {
        "status": "success",
        "message": f"Created table {table_name} for in glue",
        "created_tables": boto_dict["TableInput"],
    }

    logger.info(result)
    return result
