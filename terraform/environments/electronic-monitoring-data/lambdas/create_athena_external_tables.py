import awswrangler as wr
from mojap_metadata.converters.sqlalchemy_converter import SQLAlchemyConverter
from sqlalchemy import create_engine
import os

SECRET_NAME = os.environ("SECRET_NAME")
DB_NAME = os.environ("DB_NAME")


def get_rds_connection():
    con_sqlserver = wr.sqlserver.connect(
        secret_id=SECRET_NAME, odbc_driver_version=17, dbname=DB_NAME
    )
    return con_sqlserver


def handler(event, context):
    conn = get_rds_connection()
    engine = create_engine("mssql+pyodbc://", creator=lambda: conn)
    sqlc = SQLAlchemyConverter(engine)
    metadata = sqlc.generate_to_meta_list(schema="dbo")
    print(metadata)
    return "done"
