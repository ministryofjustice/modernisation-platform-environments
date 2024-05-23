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
db_sem_name = f"{DB_NAME}_semantic_layer"


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
        wr.catalog.delete_database(name=db_sem_name)
        logger.info(f"Delete database {db_sem_name}")
    # Handle case where database doesn't exist
    except s3.exceptions.from_code("EntityNotFoundException"):
        logger.info(f"Database '{db_sem_name}' does not exist")
    wr.catalog.create_database(name=db_sem_name, exist_ok=True)
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


def handler(event, context):
    conn = get_rds_connection()
    engine = create_engine("mssql+pyodbc://", creator=lambda: conn)
    sqlc = SQLAlchemyConverter(engine)
    metadata_list = sqlc.generate_to_meta_list(schema="dbo")

    created_tables = []
    for meta in metadata_list:
        meta.file_format = "csv"
        boto_dict = create_glue_database(meta)
        created_tables.append(boto_dict["TableInput"]["Name"])

    result = {
        "status": "success",
        "message": f"Created {len(created_tables)} tables in Glue",
        "created_tables": created_tables,
    }

    logger.info(result)
    return result
