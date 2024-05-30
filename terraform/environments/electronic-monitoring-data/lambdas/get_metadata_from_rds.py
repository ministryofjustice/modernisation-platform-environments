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


def handler(event, context):
    conn = get_rds_connection()
    engine = create_engine("mssql+pyodbc://", creator=lambda: conn)
    sqlc = SQLAlchemyConverter(engine)
    metadata_list = sqlc.generate_to_meta_list(schema="dbo")
    metadata_list = [meta.to_dict() for meta in metadata_list]
    create_glue_database()
    result = {
        "status": "success",
        "message": f"Found {len(metadata_list)} tables",
        "metadata_list": metadata_list,
    }
    logger.info(result)
    return result
