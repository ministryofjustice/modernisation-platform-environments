"""
connects to rds for a given database and uses mojap metadata to convert
mojap metadata type and writes out the list of metadata for all tables in the database
"""

import awswrangler as wr
from mojap_metadata.converters.sqlalchemy_converter import (
    SQLAlchemyConverter,
    SQLAlchemyConverterOptions,
)
from botocore.exceptions import NoCredentialsError, PartialCredentialsError
from sqlalchemy import create_engine
import os
import logging
import boto3

s3 = boto3.client("s3")
glue_client = boto3.client("glue")
lambda_client = boto3.client("lambda")

logger = logging.getLogger(__name__)
logger.setLevel(logging.INFO)

SECRET_NAME = os.environ.get("SECRET_NAME")
METADATA_STORE_BUCKET = os.environ.get("METADATA_STORE_BUCKET")


def get_rds_connection(db_name):
    con_sqlserver = wr.sqlserver.connect(
        secret_id=SECRET_NAME, odbc_driver_version=17, dbname=db_name
    )
    logger.info("Successfully connected to RDS database")
    return con_sqlserver


def create_glue_database(db_name):
    # Try to delete the database
    try:
        # Delete database
        wr.catalog.delete_database(name=db_name)
        logger.info(f"Delete database {db_name}")
    # Handle case where database doesn't exist
    except s3.exceptions.from_code("EntityNotFoundException"):
        logger.info(f"Database '{db_name}' does not exist")
    wr.catalog.create_database(name=db_name, exist_ok=True)


def upload_to_s3(local_filepath: str, s3_filepath: str) -> None:
    bucket_name, key = s3_filepath[5:].split("/", 1)

    try:
        s3.upload_file(local_filepath, bucket_name, key)
        logger.info(f"Successfully uploaded {local_filepath} to {s3_filepath}")
    except (NoCredentialsError, PartialCredentialsError) as e:
        logger.info(f"Error uploading to S3: {e}")


def write_meta_to_s3(meta):
    db_name = meta.database_name
    table_name = meta.name
    temp_path = "/tmp/temp.json"
    s3_path = f"s3://{METADATA_STORE_BUCKET}/database={db_name}/table_name={table_name}/metadata.json"
    meta.to_json(temp_path)
    upload_to_s3(temp_path, s3_path)


def add_db_to_meta(meta, db_name):
    """
    Database is currently down as dbo -
    reassign to actual DB Name
    """
    meta.file_format = "parquet"
    meta.database_name = db_name
    return meta


def remove_comments_from_meta(meta):
    for col in meta["columns"]:
        col["description"] = ""
    return meta


def reassign_binary_cols(meta):
    for col in meta["columns"]:
        if col["type"] == "binary":
            if col["name"] == "row_v":
                col["type"] == "string"
    return meta


def handler(event, context):
    db_name = event.get("db_name")
    conn = get_rds_connection(db_name)
    engine = create_engine("mssql+pyodbc://", creator=lambda: conn)
    opt = SQLAlchemyConverterOptions(convert_to_snake=True)
    sqlc = SQLAlchemyConverter(engine, opt)
    metadata_list = sqlc.generate_to_meta_list(schema="dbo")
    metadata_list = [add_db_to_meta(meta, db_name) for meta in metadata_list]
    for meta in metadata_list:
        write_meta_to_s3(meta)
    dict_metadata_list = [meta.to_dict() for meta in metadata_list]
    dict_metadata_list = [
        remove_comments_from_meta(meta) for meta in dict_metadata_list
    ]
    dict_metadata_list = [reassign_binary_cols(meta) for meta in dict_metadata_list]

    create_glue_database(db_name)
    result = {
        "status": "success",
        "message": f"Found {len(metadata_list)} tables",
        "metadata_list": dict_metadata_list,
    }
    logger.info(result)
    return result
