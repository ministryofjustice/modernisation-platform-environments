"""
connects to rds for a given database and uses mojap metadata to convert
mojap metadata type and writes out the list of metadata for all tables in the database
"""

import awswrangler as wr
from mojap_metadata.converters.sqlalchemy_converter import SQLAlchemyConverter
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
DB_NAME = os.environ.get("DB_NAME")
METDATA_STORE_BUCKET = os.environ.get("METDATA_STORE_BUCKET")


db_sem_name = f"{DB_NAME}_semantic_layer"


def get_rds_connection():
    con_sqlserver = wr.sqlserver.connect(
        secret_id=SECRET_NAME, odbc_driver_version=17, dbname=DB_NAME
    )
    logger.info("Successfully connected to RDS database")
    return con_sqlserver


def create_glue_database():
    # Try to delete the database
    try:
        # Delete database
        wr.catalog.delete_database(name=db_sem_name)
        logger.info(f"Delete database {db_sem_name}")
    # Handle case where database doesn't exist
    except s3.exceptions.from_code("EntityNotFoundException"):
        logger.info(f"Database '{db_sem_name}' does not exist")
    wr.catalog.create_database(name=db_sem_name, exist_ok=True)


def write_meta_to_s3(meta):
    table_name = meta.name
    meta.to_json(
        f"s3://{METDATA_STORE_BUCKET}/database={DB_NAME}/table_name={table_name}/metadata.json"
    )


def add_db_to_meta(meta):
    """
    Database is currently down as dbo -
    reassign to actual DB Name
    """
    meta.database = DB_NAME
    return meta


def handler(event, context):
    conn = get_rds_connection()
    engine = create_engine("mssql+pyodbc://", creator=lambda: conn)
    sqlc = SQLAlchemyConverter(engine)
    metadata_list = sqlc.generate_to_meta_list(schema="dbo")
    metadata_list = [add_db_to_meta(meta) for meta in metadata_list]
    for meta in metadata_list:
        write_meta_to_s3(meta)
    dict_metadata_list = [meta.to_dict() for meta in metadata_list]
    create_glue_database()
    result = {
        "status": "success",
        "message": f"Found {len(metadata_list)} tables",
        "metadata_list": dict_metadata_list,
    }
    logger.info(result)
    return result
