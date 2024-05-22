import awswrangler as wr
from mojap_metadata.converters.sqlalchemy_converter import SQLAlchemyConverter
from mojap_metadata.converters.glue_converter import GlueConverter, GlueConverterOptions
from sqlalchemy import create_engine
import os
from logging import getLogger
import boto3

s3 = boto3.client("s3")
glue_client = boto3.client("glue")

logger = getLogger(__name__)

SECRET_NAME = os.environ.get("SECRET_NAME")
DB_NAME = os.environ.get("DB_NAME")
S3_BUCKET_NAME = os.environ.get("S3_BUCKET_NAME")

db_path = f"{S3_BUCKET_NAME}/{DB_NAME}/dbo"


def get_rds_connection():
    con_sqlserver = wr.sqlserver.connect(
        secret_id=SECRET_NAME, odbc_driver_version=17, dbname=DB_NAME
    )
    logger.info("Successfully connected to RDS database")
    return con_sqlserver


def create_glue_database(metadata):
    # Try to delete the database
    try:
        # Delete database
        wr.catalog.delete_database(name=DB_NAME)
        logger.info(f"Delete database {DB_NAME}")
    # Handle case where database doesn't exist
    except s3.exceptions.from_code("EntityNotFoundException"):
        logger.info(f"Database '{DB_NAME}' does not exist")
    wr.catalog.create_database(name=DB_NAME, exist_ok=True)
    table_name = metadata.name
    logger.info(f"Table Name: {table_name}")
    options = GlueConverterOptions()
    options.csv.skip_header = True
    gc = GlueConverter(options)
    boto_dict = gc.generate_from_meta(
        metadata, database_name=DB_NAME, table_location=f"s3://{db_path}/{table_name}"
    )
    glue_client.create_table(**boto_dict)
    return boto_dict


def handler(event, context):
    conn = get_rds_connection()
    engine = create_engine("mssql+pyodbc://", creator=lambda: conn)
    sqlc = SQLAlchemyConverter(engine)
    metadata_list = sqlc.generate_to_meta_list(schema="dbo")
    for meta in metadata_list:
        meta.file_format = "csv"
        create_glue_database(meta)
    return "done"
