import json
import logging
import os
import sys
from datetime import datetime

import boto3
import oracledb
from aws_xray_sdk.core import patch_all, xray_recorder
from dotenv import load_dotenv
from mojap_metadata import Metadata
from mojap_metadata.converters.etl_manager_converter import EtlManagerConverter
from mojap_metadata.converters.glue_converter import GlueConverter
from mojap_metadata.converters.sqlalchemy_converter import SQLAlchemyConverter
from sqlalchemy import create_engine

patch_all()

logger = logging.getLogger()
log_level = os.getenv("LOG_LEVEL", "INFO")
logger.setLevel(log_level)

secretsmanager = boto3.client("secretsmanager")
s3 = boto3.client("s3")
glue = boto3.client("glue")
oracledb.version = "8.3.0"
sys.modules["cx_Oracle"] = oracledb
load_dotenv()

extraction_columns = [
    {
        "name": "scn",
        "type": "string",
        "description": "Oracle system change number",
        "nullable": True,
    },
    {
        "name": "extraction_timestamp",
        "type": "string",
        "description": "DMS extraction timestamp",
        "nullable": False,
    },
    {
        "name": "op",
        "type": "string",
        "description": "Type of change, for rows added by ongoing replication.",
        "nullable": True,
        "enum": ["I", "U", "D"],
    },
]

curation_columns = [
    {
        "name": "mojap_current_record",
        "type": "bool",
        "description": "If the record is current",
        "nullable": False,
    },
    {
        "name": "mojap_start_datetime",
        "type": "timestamp(s)",
        "description": "When the record became current",
        "nullable": False,
    },
    {
        "name": "mojap_end_datetime",
        "type": "timestamp(s)",
        "description": "When the record ceased to be current",
        "nullable": False,
    },
]


class MetadataExtractor:
    """_Extracts table metadata for a specified database schema
    and writes the metadata to a list of json files

    Replaces the now deprecated [Data_Engineering_extract_metadata]
    (https://github.com/moj-analytical-services/data-engineering-extract-metadata).
    It does the following things:
    + connects to a specified database using SQLAlchemy
    + extract the table metadata using mojap-metadata's SQLAlchemyConverter
    + convert the table metadata so it is compatible with etl_manager
    + convert int columns to decimals due to how oracle stores integers as NUMERIC under the hood
    + remove _mv suffix from materialised views

    It does not:
    + extract table partitions_
    """

    def __init__(self, db_options, engine):
        self.source_database = db_options["database"]
        self.database_identifier = db_options["identifier"]
        self.schema_name = db_options["schema"].lower()
        self.dialect = db_options["dialect"]
        self.tables = db_options["objects"]
        self.deleted_tables = db_options.get("deleted_tables", [])

        self.emc = EtlManagerConverter()
        self.sqlc = SQLAlchemyConverter(engine)
        self.blobs = []
        self.upper_case_dialects = ["oracle"]

    def _manage_blob_columns(self, metadata: Metadata) -> Metadata:
        for column_name in metadata.column_names:
            if metadata.get_column(column_name)["type"] in ["binary"]:
                metadata.remove_column(column_name)
                if self.dialect in self.upper_case_dialects:
                    self.blobs.append(
                        {
                            "object_name": metadata.name.upper(),
                            "column_name": column_name.upper(),
                        }
                    )
                else:
                    self.blobs.append(
                        {
                            "object_name": metadata.name,
                            "column_name": column_name,
                        }
                    )
        return metadata

    def _convert_int_columns(self, metadata: Metadata) -> Metadata:
        for column_name in metadata.column_names:
            if metadata.get_column(column_name)["type"].startswith("int"):
                column_int = metadata.get_column(column_name)
                column_int["type"] = "decimal128(38,0)"
                metadata.update_column(column_int)
        return metadata

    def _rename_materialised_view(self, metadata: Metadata) -> Metadata:
        if metadata.name.lower().endswith("_mv"):
            metadata.name = metadata.name[:-3]
        return metadata

    def _add_reference_columns(self, metadata: Metadata) -> Metadata:
        for column in extraction_columns:
            metadata.update_column(column, append=False)
        for column in curation_columns:
            metadata.update_column(column)
        return metadata

    def convert_metadata(self, metadata: Metadata):
        metadata.file_format = "parquet"
        etlmeta = self.emc.generate_from_meta(metadata=metadata)
        if self.dialect in self.upper_case_dialects:
            etlmeta.location = etlmeta.location.upper()
        etl_dict = etlmeta.to_dict()
        etl_dict["partitions"] = None
        return json.dumps(etl_dict)

    def get_table_metadata(self, table) -> Metadata:
        table_meta = self.sqlc.generate_to_meta(table.lower(), self.schema_name)
        table_meta = self._manage_blob_columns(table_meta)
        table_meta = self._convert_int_columns(table_meta)
        table_meta = self._rename_materialised_view(table_meta)
        table_meta = self._add_reference_columns(table_meta)
        # table_meta = self._convert_metadata(table_meta)
        table_meta.file_format = "parquet"
        return table_meta

    def _write_database_objects(self, bucket):
        database_objects = {
            "objects_from": self.database_identifier,
            "extraction_date": datetime.now().isoformat(),
            "objects": sorted(self.tables),
            "blobs": self.blobs,
            "deleted_tables": sorted(self.deleted_tables),
        }
        s3.put_object(
            Body=json.dumps(database_objects),
            Bucket=bucket,
            Key="objects.json",
        )

    def get_database_metadata(self, output_bucket):
        tables = [self.get_table_metadata(table) for table in self.tables]
        self._write_database_objects(output_bucket)
        return tables


def handler(event, context):  # pylint: disable=unused-argument
    # TODO: PASS IN AS ENV VARS
    os.environ["RAW_HISTORY_BUCKET"] = "dms-test-raw-history-20250221145111054600000001"

    metadata_bucket = os.getenv("METADATA_BUCKET")
    db_secret_arn = os.getenv("DB_SECRET_ARN")
    db_secret_response = secretsmanager.get_secret_value(SecretId=db_secret_arn)
    db_secret = json.loads(db_secret_response["SecretString"])
    db_identifier = db_secret["dbInstanceIdentifier"]
    username = db_secret["username"]
    password = db_secret["password"]
    engine = db_secret["engine"]
    host = db_secret["host"]
    db_name = db_secret["dbname"]
    raw_history_bucket = os.getenv("RAW_HISTORY_BUCKET")

    # TODO: Works for oracle databases. Need to add support for other databases
    port = "1521"
    dsn = f"{host}:{port}/?service_name={db_name}"

    db_string = f"{engine}://{username}:{password}@{dsn}"
    engine = create_engine(db_string)

    db_objects = [obj.lower() for obj in json.loads(os.getenv("DB_OBJECTS", "[]"))]
    schema_name = os.getenv("DB_SCHEMA_NAME").lower()

    db_options = {
        "database": db_name,
        "identifier": db_identifier,
        "schema": schema_name,
        "objects": db_objects,
        "include_derived_columns": True,
        "dialect": engine,
    }

    # Get the glue database to check if it exists. handle EntityNotFoundException
    try:
        glue.get_database(Name=db_identifier)
        logger.info(f"Database {db_identifier} already exists")
    except glue.exceptions.EntityNotFoundException:
        # Create the database if it does not exist. Fails is it cannot be created
        logger.info(f"Database {db_identifier} does not exist. Creating it now")
        response = glue.create_database(
            DatabaseInput={
                "Name": db_identifier,
                "Description": f"{db_identifier} - DMS Pipeline",
            }
        )

    metadata = MetadataExtractor(db_options, engine)
    db_metadata = metadata.get_database_metadata(metadata_bucket)

    # Used to create glue tables based on Metadata objects
    gc = GlueConverter()
    glue_table_definitions = [
        gc.generate_from_meta(
            table,
            db_identifier.replace("_", "-"),
            f"s3://{raw_history_bucket}/{schema_name}/{table.name}",
        )
        for table in db_metadata
    ]

    for table in glue_table_definitions:
        try:
            glue.get_table(DatabaseName=db_identifier, Name=table["TableInput"]["Name"])
            logger.info(f"Table {table['TableInput']['Name']} already exists")
            # Update the table if it exists
            logger.info(f"Updating table {table['TableInput']['Name']}")
            glue.update_table(
                DatabaseName=db_identifier, TableInput=table["TableInput"]
            )
        except glue.exceptions.EntityNotFoundException:
            logger.info(
                f"Table {table['TableInput']['Name']} does not exist. Creating it now"
            )
            response = glue.create_table(**table)
            logger.debug(response)

    # Output json metadata to S3
    for table in db_metadata:
        s3.put_object(
            Body=metadata.convert_metadata(table),
            Bucket=metadata_bucket,
            Key=f"{table.name}.json",
        )

    logger.info("Reprocessing failed records")
    # Reprocess failed records
    invalid_bucket_name = os.getenv("INVALID_BUCKET")
    landing_bucket_name = os.getenv("LANDING_BUCKET")
    list_invalid_bucket = s3.list_objects_v2(Bucket=invalid_bucket_name)
    logger.info(f"Invalid bucket: {list_invalid_bucket}")
    if "Contents" not in list_invalid_bucket:
        logger.info("No invalid keys found")
        return

    invalid_keys = [item["Key"] for item in list_invalid_bucket["Contents"]]

    # Move these keys to the landing bucket
    for key in invalid_keys:
        # Extract X-Ray trace ID
        trace_id = xray_recorder.current_segment().trace_id

        # Get original object metadata (if exists)
        original_metadata = s3.head_object(Bucket=invalid_bucket_name, Key=key).get(
            "Metadata", {}
        )

        # Preserve existing metadata and add X-Ray trace ID
        updated_metadata = original_metadata.copy()
        updated_metadata["X-Amzn-Trace-Id"] = trace_id

        # Add object metadata to state that it has been reprocessed
        updated_metadata["reprocessed"] = "true"

        # Copy object with new metadata
        s3.copy_object(
            CopySource=f"{invalid_bucket_name}/{key}",
            Bucket=landing_bucket_name,
            Key=key,
            Metadata=updated_metadata,
            MetadataDirective="REPLACE",  # Ensures metadata is replaced with the new one
        )

        # Delete original object
        s3.delete_object(Bucket=invalid_bucket_name, Key=key)

    logger.info("Done reprocessing failed records")
