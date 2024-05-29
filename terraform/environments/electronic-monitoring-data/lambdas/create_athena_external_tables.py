import awswrangler as wr
from mojap_metadata.converters.sqlalchemy_converter import SQLAlchemyConverter
from sqlalchemy import create_engine
import os
import logging
import boto3
import json

s3 = boto3.client("s3")
glue_client = boto3.client("glue")
lambda_client = boto3.client("lambda")

logger = logging.getLogger(__name__)
logger.setLevel(logging.INFO)

SECRET_NAME = os.environ.get("SECRET_NAME")
DB_NAME = os.environ.get("DB_NAME")
S3_BUCKET_NAME = os.environ.get("S3_BUCKET_NAME")
LAMBDA_FUNCTION_ARN = os.environ.get("LAMBDA_FUNCTION_ARN")

db_path = f"{S3_BUCKET_NAME}/{DB_NAME}/dbo"
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
    create_glue_database()
    created_tables = []
    for meta in metadata_list:
        meta.file_format = "csv"
        meta_dict = json.dumps(meta.to_dict())
        logger.info(f"Table name: {meta.name}")
        try:
            response = lambda_client.invoke(
                FunctionName=LAMBDA_FUNCTION_ARN,
                InvocationType="Event",
                Payload=meta_dict,
            )
            logger.info("Logged create_athena_external_table function.")
            if response["StatusCode"] == 202:
                created_tables.append(meta.name)
            else:
                logger.error(f"Invocation failed for table: {meta.name}")
        except Exception as e:
            logger.error(f"Error invoking Lambda for table {meta.name}: {e}")
    result = {
        "status": "success",
        "message": f"Triggered {len(created_tables)} tables for creation in lambda",
        "created_tables": created_tables,
    }
    logger.info(result)
    return result
