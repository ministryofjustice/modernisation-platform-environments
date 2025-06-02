from collections import defaultdict
import json
import logging
import os
import re
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

def _get_glue_client():
    """
    Return a glue client with an appropriate role
    """
    glue_client_kwargs = {
        "region_name": "eu-west-1"
    }
    glue_role_arn = os.getenv("GLUE_CATALOG_ROLE_ARN")
    use_glue_catalog = os.getenv("USE_GLUE_CATALOG", "true").lower() == "true"
    if use_glue_catalog and glue_role_arn:
        sts_connection = boto3.client('sts')
        acct_b = sts_connection.assume_role(
            RoleArn=glue_role_arn,
            RoleSessionName="cross_acct_lambda"
        )
        glue_client_kwargs.update({
            'aws_access_key_id': acct_b['Credentials']['AccessKeyId'],
            'aws_secret_access_key': acct_b['Credentials']['SecretAccessKey'],
            'aws_session_token': acct_b['Credentials']['SessionToken'],
        })
    else:
        logger.info(f"Not assuming role, as GLUE_CATALOG_ROLE_ARN={glue_role_arn}")
    return boto3.client(
        'glue',
        **glue_client_kwargs
    )

logger = logging.getLogger()
log_level = os.getenv("LOG_LEVEL", "INFO")
logger.setLevel(log_level)

secretsmanager = boto3.client("secretsmanager")
s3 = boto3.client("s3")
glue = _get_glue_client()
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
        self.objects = db_options["objects"]
        self.deleted_tables = db_options.get("deleted_tables", [])
        lambda_bucket_name = os.getenv("LAMBDA_BUCKET")
        path_to_dms_mapping_rules = db_options.get("path_to_dms_mapping_rules", "")
        if path_to_dms_mapping_rules:
            logger.info("Loading columns to exclude from %s", path_to_dms_mapping_rules)
            response = s3.get_object(
                Bucket=lambda_bucket_name,
                Key=path_to_dms_mapping_rules
            )
            self.dms_mapping_rules = json.loads(b"".join(response['Body'].readlines()).decode("utf-8"))
        self.excluded_columns_by_object = defaultdict(set)
        for object_column in self.dms_mapping_rules.get("columns_to_exclude", []):
            self.excluded_columns_by_object[object_column["object_name"].upper()].add(object_column["column_name"].upper())

        logger.info("Excluded columns loaded as %s", self.excluded_columns_by_object)
        self.emc = EtlManagerConverter()
        self.sqlc = SQLAlchemyConverter(engine)
        self.blobs = []
        self.upper_case_dialects = ["oracle"]

    def _manage_blob_columns(self, metadata: Metadata) -> Metadata:
        logger.info("Managing blob columns for metadata: %s", metadata.to_dict())
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
        logger.info("Converting int columns for metadata: %s", metadata.to_dict())
        for column_name in metadata.column_names:
            if metadata.get_column(column_name)["type"].startswith("int"):
                column_int = metadata.get_column(column_name)
                column_int["type"] = "decimal128(38,0)"
                metadata.update_column(column_int)
        return metadata

    def _rename_materialised_view(self, metadata: Metadata) -> Metadata:
        logger.info("Renaming materialised view for metadata: %s", metadata.to_dict())
        if metadata.name.lower().endswith("_mv"):
            metadata.name = metadata.name[:-3]
        return metadata

    def _add_reference_columns(self, metadata: Metadata) -> Metadata:
        logger.info("Adding reference columns to metadata: %s", metadata.to_dict())
        for column in extraction_columns:
            metadata.update_column(column, append=False)
        for column in curation_columns:
            metadata.update_column(column)
        return metadata

    def _process_exclusions(self, metadata: Metadata, schema: str, table: str) -> Metadata:
        """
        Remove relevant entries from column exclusion list from metadata

        :param metadata: collection of metadata about table
        :type metadata: Metadata
        :param schema: Name of schema table is contained within
        :type schema: str
        :param table: Name of table metadata pertains to
        :type table: str
        :rtype: Metadata
        """
        exclusion_key = ""
        logger.info("Looking for excluded columns for keys %s.%s and %s", schema, table, table)
        if f"{schema}.{table}".upper() in self.excluded_columns_by_object:
            exclusion_key = f"{schema}.{table}".upper()
        elif table.upper() in self.excluded_columns_by_object:
            exclusion_key = table.upper()
        else:
            return metadata

        for column_name in set(metadata.column_names).intersection(map(str.lower, self.excluded_columns_by_object[exclusion_key])):
            logger.info("Removing column %s from table %s in schema %s in metadata", column_name, table, schema)
            metadata.remove_column(column_name)
            if column_name in metadata._data["primary_key"]:
                logger.info("Unsetting primary key of %s on %s.%s so as not to break metadata.validate()", column_name, schema, table)
                metadata._data["primary_key"].remove(column_name)

        return metadata

    def convert_metadata(self, metadata: Metadata):
        logger.info("Converting metadata: %s", metadata)
        metadata.file_format = "parquet"
        etlmeta = self.emc.generate_from_meta(metadata=metadata)
        if self.dialect in self.upper_case_dialects:
            etlmeta.location = etlmeta.location.upper()
        etl_dict = etlmeta.to_dict()
        etl_dict["partitions"] = None
        return json.dumps(etl_dict)

    def get_table_metadata(self, schema, table) -> Metadata:
        logger.info("Getting table metadata for table %s in schema %s", table, schema)
        table_meta = self.sqlc.generate_to_meta(table.lower(), schema)
        logger.info("Primary key of %s.%s is %s", schema, table, table_meta.primary_key)
        if self.dialect == "oracle":
            table_meta = self._manage_blob_columns(table_meta)
        table_meta = self._convert_int_columns(table_meta)
        table_meta = self._rename_materialised_view(table_meta)
        table_meta = self._add_reference_columns(table_meta)
        table_meta = self._process_exclusions(table_meta, schema, table)
        # table_meta = self._convert_metadata(table_meta)
        table_meta.database_name = schema
        table_meta.file_format = "parquet"
        return table_meta

    def _write_database_objects(self, bucket):
        database_objects = {
            "objects_from": self.database_identifier,
            "extraction_date": datetime.now().isoformat(),
            "objects": sorted(self.objects),
            "blobs": self.blobs,
            "deleted_tables": sorted(self.deleted_tables),
            "dms_mapping_rules": self.dms_mapping_rules
        }
        s3.put_object(
            Body=json.dumps(database_objects),
            Bucket=bucket,
            Key="objects.json",
        )

    def get_schema_and_table_from_object(self, obj_str: str) -> 'tuple[str, str]':
        """get_table_specific_schema.

        :param object: database object string in format `table` or `schema.table`
        :type object: str
        :rtype: dict(str, str)
        :return: Tuple of (schema_name , table_name)
        """
        logger.info("Extracting schema (if exists) and table from %s", obj_str)
        object_list = obj_str.split(".")
        if len(object_list) == 2:
            return tuple(object_list)
        elif len(object_list) == 1:
            return self.schema_name, object_list[0]
        else:
            raise ValueError(f"Expected object to be of format `table` or `schema.table` but got {obj_str}")

    def get_database_metadata(self, output_bucket):
        tables = [self.get_table_metadata (*self.get_schema_and_table_from_object(obj)) for obj in self.objects]
        self._write_database_objects(output_bucket)
        return tables


def handler(event, context):  # pylint: disable=unused-argument
    metadata_bucket = os.getenv("METADATA_BUCKET")
    db_secret_arn = os.getenv("DB_SECRET_ARN")
    db_secret_response = secretsmanager.get_secret_value(SecretId=db_secret_arn)
    db_secret = json.loads(db_secret_response["SecretString"])
    db_identifier = db_secret.get("dbInstanceIdentifier", os.getenv("GLUE_CATALOG_DATABASE_NAME")) # identifies database in glue catalog
    use_glue_catalog = os.getenv("USE_GLUE_CATALOG", "true").lower() == "true"
    glue_catalog_account_id = os.getenv("GLUE_CATALOG_ACCOUNT_ID", "")
    retry_failed_after_recreate_metadata = os.getenv("RETRY_FAILED_AFTER_RECREATE_METADATA", "true").lower() == "true"
    username = db_secret["username"]
    password = db_secret["password"]
    engine = db_secret.get("engine", os.getenv("ENGINE"))
    host = db_secret["host"]
    db_name = db_secret.get("dbname", os.getenv("DATABASE_NAME"))
    raw_history_bucket = os.getenv("RAW_HISTORY_BUCKET")
    destination_bucket = os.getenv("GLUE_DESTINATION_BUCKET", raw_history_bucket)
    destination_prefix = os.getenv("GLUE_DESTINATION_PREFIX", "")

    port = db_secret["port"]
    if engine == "oracle":
        dsn = f"{host}:{port}/?service_name={db_name}"
    elif engine == "mssql+pymssql":
        dsn = f"{host}:{port}/{db_name}?charset=utf8"
    else:
        raise ValueError(f"Supported engines: oracle, mssql+pymssql Got: {engine}")

    db_string = f"{engine}://{username}:{password}@{dsn}"
    engine = create_engine(db_string)

    db_objects = [obj.lower() for obj in json.loads(os.getenv("DB_OBJECTS", "[]"))]
    schema_name = os.getenv("DB_SCHEMA_NAME").lower() # May be empty string if schema specified on per-table basis
    path_to_dms_mapping_rules = os.environ.get("PATH_TO_DMS_MAPPING_RULES", "")

    db_options = {
        "database": db_name,
        "identifier": db_identifier,
        "schema": schema_name,
        "objects": db_objects,
        "include_derived_columns": True,
        "dialect": engine,
        "path_to_dms_mapping_rules": path_to_dms_mapping_rules
    }

    if use_glue_catalog:
        # Get the glue database to check if it exists. handle EntityNotFoundException
        glue_kwargs = {}
        if glue_catalog_account_id:
            glue_kwargs["CatalogId"] = glue_catalog_account_id
        try:
            glue.get_database(Name=db_identifier, **glue_kwargs)
            logger.info(f"Database {db_identifier} already exists in Glue Catalog")
        except glue.exceptions.EntityNotFoundException:
            # Create the database if it does not exist. Fails is it cannot be created
            logger.info(f"Database {db_identifier} does not exist in Glue Catalog. Creating it now")
            response = glue.create_database(
                DatabaseInput={
                    "Name": db_identifier,
                    "Description": f"{db_identifier} - DMS Pipeline",
                },
                **glue_kwargs
            )
    else:
        logger.info(f"Not contacting glue catalog, as db_identifier defined as {db_identifier}")

    metadata = MetadataExtractor(db_options, engine)
    db_metadata = metadata.get_database_metadata(metadata_bucket)

    # Used to create glue tables based on Metadata objects
    gc = GlueConverter()
    glue_table_definitions = []
    for table in db_metadata:
        if destination_prefix != "":
            table_location = f"s3://{destination_bucket}/{destination_prefix}/{table.database_name}/{table.name}"
        else:
            table_location = f"s3://{destination_bucket}/{table.database_name}/{table.name}"

        logger.info("Generating glue metadata for %s.%s located at %s", table.database_name, table.name, table_location)
        glue_table_definition = gc.generate_from_meta(
            table,
            db_identifier,
            table_location,
        )

        glue_table_definitions.append(glue_table_definition)

    if use_glue_catalog:
        for table in glue_table_definitions:
            try:
                glue.get_table(DatabaseName=db_identifier, Name=table["TableInput"]["Name"], **glue_kwargs)
                logger.info(f"Table {table['TableInput']['Name']} already exists")
                # Update the table if it exists
                logger.info(f"Updating table {table['TableInput']['Name']}")
                glue.update_table(
                    DatabaseName=db_identifier, TableInput=table["TableInput"], **glue_kwargs
                )
            except glue.exceptions.EntityNotFoundException:
                try:
                    logger.info(
                        f"Table {table['TableInput']['Name']} does not exist. Creating it now"
                    )
                    response = glue.create_table(**table | glue_kwargs)
                    logger.debug(response)
                except Exception as e:
                    logger.exception("Create table failed: %s", table)
                    raise e
    else:
        logger.info(f"Not contacting glue catalog, as use_glue_catalog is {use_glue_catalog}")

    # Output json metadata to S3
    for table in db_metadata:
        s3.put_object(
            Body=metadata.convert_metadata(table),
            Bucket=metadata_bucket,
            Key=f"{table.name}.json",
        )
    if retry_failed_after_recreate_metadata:
        reprocess_failed_records()


def reprocess_failed_records():
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
