import json
import logging
import os
import re
from datetime import datetime
from pprint import pformat
from typing import Optional
from urllib.parse import unquote_plus

import boto3
import s3fs
from aws_xray_sdk.core import patch_all
from pyarrow import ArrowInvalid
from pyarrow.parquet import ParquetFile
from urllib3 import PoolManager

patch_all()

logger = logging.getLogger()
log_level = os.getenv("LOG_LEVEL", "INFO")
logger.setLevel(log_level)

client = boto3.client("s3")
fs = s3fs.S3FileSystem()
http = PoolManager()

type_lookup = {
    "string": "character",
    "boolean": "boolean",
    "timestamp": "datetime",
    "decimal": "decimal",
    "int": "decimal",
    "binary": "binary",
}


def move_object(bucket_to: str, bucket_from: str, key: str, mutable: bool=False):
    """The function will copy the object in S3 to the "bucket_to" bucket,
    while adding a timestamp to the filename. It will then
    delete the original object from "bucket_from".
    Parameters
    ----------
    bucket_to : str
        The bucket where the S3 object will be copied to.
    bucket_from : str
        The bucket where the S3 object is.
    key : str
        The object S3 key.
    mutable: bool
        If False, insert datetime infix into destination path
    """
    client = boto3.client("s3")
    # Provides timestamp like '20210217_121400'
    event_time = datetime.utcnow().strftime("%Y%m%d_%H%M%S")
    if "LOAD" in key and not mutable:
        # This will return a key of the form 'Load000000001_[DATE]_[TIME].parquet'
        new_key = key.split(".")[0] + "_" + event_time + ".parquet"
    else:
        new_key = key

    # Get object metadata
    head_response = client.head_object(Bucket=bucket_from, Key=key)
    current_metadata = head_response.get("Metadata", {})

    copy_params = {
        "Bucket": bucket_to,
        "CopySource": {"Bucket": bucket_from, "Key": key},
        "Key": new_key.lower(),
        "ServerSideEncryption": "AES256",
        "ACL": "bucket-owner-full-control",
    }

    if current_metadata:
        copy_params["Metadata"] = current_metadata
        copy_params["MetadataDirective"] = "REPLACE"

    logger.info("COPY PARAMS:", copy_params)

    client.copy_object(**copy_params)
    client.delete_object(Bucket=bucket_from, Key=key)


def strip_data_type(data_type: str) -> str:
    """Some data types define units within brackets that are asociated with the
    properties of that data type. This function will strip brackets and units
    from the given data type.
    Parameters
    ----------
    data_type : str
        The data type to strip of brackets and units.
    Returns
    -------
    data_type : str
        The bare data type.
    """
    data_type = re.split(r"\[|\(|\d", data_type)[0].lower()

    if data_type in type_lookup or data_type in type_lookup.values():
        return data_type

    raise MetadataTypeMismatchException(
        f"'{data_type}' is not valid or is not a supported data type."
    )


def return_agnostic_type(data_type: str, column_name: Optional[str] = None) -> str:
    """Returns the agnostic type for the given non-agnostic data type, based on the
    mapping in the type_lookup dictionary.
    Parameters
    ----------
    data_type : str
        A non-agnostic data type to convert.
    column_name : str
        The column name for the given data type.
    Returns
    -------
    agnostic_type : str
        The corresponding agnostic_type.
    Raises
    ------
    MetadataTypeMismatchException
        If data type does not have a corresponding agnostic type.
    """

    data_type = strip_data_type(data_type=data_type)

    if data_type in type_lookup.keys():
        agnostic_type = type_lookup[data_type]
        return agnostic_type

    raise MetadataTypeMismatchException(
        f"The column type '{data_type}' "
        f"{'for column ' + column_name if column_name else ''} is already an "
        "agnostic type."
    )


class MetadataTypeMismatchException(Exception):
    pass


class FileValidator:
    """
    A class to validate data extracted in Parquet format by AWS DMS which is stored in
    AWS S3. The file and the properties of the data go through several validation
    checks before being moved to a pass or fail bucket. Any errors are aggregated into
    a single payload and sent to Slack.
    Attributes
    ----------
    key : str
        The AWS S3 key of the file being validated.
    pass_bucket : str
        The name of the bucket for files that pass validation.
    fail_bucket : str
        The name of the bucket for files that fail validation.
    bucket_from : str
        The name of the bucket that contains the file being validated.
    parquet_table_name : str
        The table name corresponding to the given Parquet file.
    metadata_s3_keys : dict
        Dictionary containing the table names as keys and their corresponding AWS S3
        keys as values.
    metadata_bucket : str
        The name of the bucket where the metadata is located.
    """

    def __init__(  # pylint: disable=too-many-positional-arguments,too-many-arguments
        self,
        key: str,
        pass_bucket: str,
        fail_bucket: str,
        bucket_from: str,
        parquet_table_name: str,
        metadata_s3_keys: dict,
        metadata_bucket: str,
        valid_files_mutable: bool=False
    ):
        """
        Parameters
        ----------
        key : str
            The AWS S3 key of the file being validated.
        pass_bucket : str
            The name of the bucket for files that pass validation.
        fail_bucket : str
            The name of the bucket for files that fail validation.
        bucket_from : str
            The name of the bucket that contains the file being validated.
        parquet_table_name : str
            The table name corresponding to the given Parquet file.
        metadata_s3_keys : dict
            Dictionary containing the table names as keys and their corresponding AWS S3
            keys as values.
        metadata_bucket : str
            The name of the bucket where the metadata is located.
        valid_files_mutable: bool
            If false, copy valid files to their destination bucket with a datetime infix
        """
        self.key = key
        self.fail_bucket = fail_bucket
        self.bucket_from = bucket_from
        self.bucket_to = pass_bucket
        self.parquet_table_name = parquet_table_name
        self.metadata_s3_keys = metadata_s3_keys
        self.metadata_bucket = metadata_bucket
        self.errors: list[str] = []
        self.valid_files_mutable = valid_files_mutable

    def _add_error(self, error: str):
        """Collects and aggregates error messages into a list.
        Parameters
        ----------
        error : str
            An error message
        """
        if error not in self.errors:
            self.errors.append(error)

    def execute(self):
        """Combines FileValidator methods to validate the file extracted by AWS DMS and
        populates the payload with error messages (if any) before sending to Slack.
        Moves the validated file to to the pass or fail bucket depending on the result
        of the validation.
        """
        # client = boto3.client("secretsmanager")
        # secrets = client.get_secret_value(SecretId=os.getenv("SLACK_SECRET_KEY"))
        # secrets = json.loads(secrets.get("SecretString"))
        # url = secrets.get("webhook_url")
        # channel = secrets.get("channel")

        self._validate_file(path=f"{self.bucket_from}/{self.key}")
        if self.errors:
            # TODO: Implement the slack notifications - commented out for now
            # event_time = datetime.utcnow().isoformat(sep=" ", timespec="milliseconds")
            # location = (
            #    f"https://s3.console.aws.amazon.com/s3/buckets/"
            #    f"{self.fail_bucket}/{self.key}"
            # )
            # payload = {
            #    "channel": channel,
            #    "text": "",
            #    "username": "AWS Lambda",
            #    "icon_emoji": ":lambda:",
            #    "blocks": [
            #        {
            #            "type": "header",
            #            "text": {
            #                "type": "plain_text",
            #                "text": "Failure – A file has failed validation",
            #                "emoji": True,
            #            },
            #        },
            #        {
            #            "type": "section",
            #            "text": {
            #                "type": "mrkdwn",
            #                "text": (
            #                    f"*Event Time:* {event_time}\n"
            #                    f"*File Moved To:* {location}"
            #                ),
            #            },
            #        },
            #    ],
            # }

            logger.error(f"{self.key} failed validation with errors: {pformat(self.errors, indent=2)}")
            self.bucket_to = self.fail_bucket
            move_object(self.bucket_to, self.bucket_from, self.key)

            # More slack notification code
            # for error in self.errors:
            #    logger.info(
            #        f"VALIDATION ERROR\n"
            #        f"File {self.key} failed validation\r"
            #        f"File moved to {location}\r"
            #        f"Reason for failure: {error}"
            #    )
            #    payload["blocks"][1]["text"]["text"] += f"\n*Failure Reason:* {error}"

            # encoded_payload = json.dumps(payload).encode("utf-8")
            # http.request(
            #    method="POST", url=url, body=encoded_payload
            # )
        else:
            move_object(self.bucket_to, self.bucket_from, self.key, self.valid_files_mutable)

    def _validate_file(self, path, fs=fs, validate_column_attributes: bool = True):
        """
        Parameters
        ----------
        path : [type]
            The file path to the Parquet file to be validated.
        fs : [type], optional
            The file system to use (either local or s3fs).
        validate_column_attributes : bool, optional
            Set to false so that validate_column_attributes is not called when testing,
            by default True..
        """
        open_function = fs.open if fs is not None else open
        with open_function(path, mode="rb") as source:
            try:
                self.parquet_file = ParquetFile(source=source)
            except ArrowInvalid as e:
                self._add_error(error=str(e))
                return
        if self.parquet_table_name not in self.metadata_s3_keys.keys():
            self._add_error(
                error=f"'{self.parquet_table_name}' is an not in the list of keys in the metadata bucket"
            )
        elif validate_column_attributes:
            self._validate_column_attributes(parquet_file=self.parquet_file)

    def _validate_column_attributes(
        self,
        parquet_file,
        validate_column_names: bool = True,
        validate_column_types: bool = True,
    ):
        """
        Parameters
        ----------
        parquet_file :
            The Parquet file being validated.
        validate_column_names : bool, optional
            Set to false so that validate_column_names is not called when testing,
            by default True.
        validate_column_types : bool, optional
            Set to false so that validate_column_types is not called when testing,
            by default True.
        """
        client = boto3.client("s3")
        metadata_file = json.loads(
            client.get_object(
                Bucket=self.metadata_bucket,
                Key=self.metadata_s3_keys[self.parquet_table_name],
            )["Body"]
            .read()
            .decode("UTF-8")
        )
        self.metadata_cols = {}
        for col in metadata_file["columns"]:
            if col["name"].lower() not in [
                "mojap_end_datetime",
                "mojap_current_record",
                "mojap_start_datetime",
                "mojap_document_path",
            ]:
                self.metadata_cols[col["name"].lower()] = col["type"].lower()
        self.metadata_cols["extraction_timestamp"] = "character"

        self.parquet_cols = {}
        for col_name, col_type in zip(
            parquet_file.schema_arrow.names, parquet_file.schema_arrow.types
        ):
            self.parquet_cols[col_name.lower()] = str(col_type).lower()

        # Parquet files generated by full load tasks do not contain an "op" column.
        if "op" not in self.parquet_cols:
            self.metadata_cols.pop("op")

        if validate_column_names:
            self._validate_column_names(
                metadata_cols=self.metadata_cols,
                parquet_cols=self.parquet_cols,
            )

        if validate_column_types:
            self._validate_column_types(
                metadata_cols=self.metadata_cols,
                parquet_cols=self.parquet_cols,
            )

    def _validate_column_names(
        self,
        metadata_cols: dict,
        parquet_cols: dict,
    ):
        """
        Parameters
        ----------
        metadata_cols : dict
            Dictionary containing the column names as keys and their data type as
            values, generated from the metadata file for the purpose of easier
            comparison against the Parquet file properties.
        parquet_cols : dict
            Dictionary containing the column names as keys and their data type as
            values, generated from the Parquet file for the purpose of easier
            comparison against the metadata file properties.
        """
        metadata_cols_set = set(metadata_cols)
        parquet_cols_set = set(parquet_cols)

        if metadata_cols_set != parquet_cols_set:
            in_metadata_not_parquet = metadata_cols_set.difference(parquet_cols_set)
            in_parquet_not_metadata = parquet_cols_set.difference(metadata_cols_set)
            if in_metadata_not_parquet:
                self._add_error(
                    error=(
                        f"The following columns are in the metadata but not in the "
                        f"extracted file: {', '.join(in_metadata_not_parquet)}."
                    )
                )
            if in_parquet_not_metadata:
                self._add_error(
                    error=(
                        f"The following columns are in the extracted file but not "
                        f"in the metadata: {', '.join(in_parquet_not_metadata)}."
                    )
                )

    def _validate_column_types(
        self,
        metadata_cols: dict,
        parquet_cols: dict,
    ):
        """
        Parameters
        ----------
        metadata_cols : dict
            Dictionary containing the column names as keys and their data type as
            values, generated from the metadata file for the purpose of easier
            comparison against the Parquet file properties.
        parquet_cols : dict
            Dictionary containing the column names as keys and their data type as
            values, generated from the Parquet file for the purpose of easier
            comparison against the metadata file properties.
        """
        # This loop validates the data type for columns with valid name and type pairs
        # that exist in both metadata & parquet files by using the intersection.
        for col in sorted(set(metadata_cols).intersection(set(parquet_cols))):
            try:
                agnostic_parquet_type = return_agnostic_type(
                    data_type=parquet_cols[col], column_name=col
                )
                agnostic_metadata_type = strip_data_type(metadata_cols[col])
                if agnostic_metadata_type not in type_lookup.values():
                    raise MetadataTypeMismatchException(
                        f"'{agnostic_metadata_type}' is not a valid agnostic type.'"
                    )
                if agnostic_parquet_type != agnostic_metadata_type:
                    self._add_error(
                        error=(
                            f"Expected the agnostic type '{agnostic_metadata_type}' "
                            f"but got '{agnostic_parquet_type}' for column "
                            f"'{col}': '{parquet_cols[col]}'."
                        )
                    )
            except MetadataTypeMismatchException as e:
                self._add_error(error=str(e))


def handler(event, context):  # noqa: C901 pylint: disable=unused-argument
    pass_bucket = os.environ["PASS_BUCKET"]
    fail_bucket = os.environ["FAIL_BUCKET"]
    metadata_bucket = os.environ["METADATA_BUCKET"]
    metadata_path = os.environ["METADATA_PATH"]
    valid_files_mutable = os.environ.get("VALID_FILES_MUTABLE", "false").lower() == "true"

    logger.info(f"Event: {event}")
    logger.info("Binary solo: 0001110101010111")

    # Get the bucket and key from the event
    record = event["Records"][0]
    bucket_from = record["s3"]["bucket"]["name"]
    key = unquote_plus(record["s3"]["object"]["key"])

    logger.info(f"Bucket from: {bucket_from}")
    logger.info(f"Key: {key}")

    paginator = client.get_paginator("list_objects_v2")
    page_iterator = paginator.paginate(Bucket=metadata_bucket, Prefix=metadata_path)
    contents = []
    try:
        for page in page_iterator:
            contents += page["Contents"]
    except KeyError:
        pass

    metadata_s3_keys = {}
    for object_ in contents:
        metadata_s3_key = object_["Key"]
        logger.info(f"Metadata S3 key: {metadata_s3_key}")
        metadata_table_name = metadata_s3_key.rsplit("/", 1)[-1].rsplit(".", 1)[0]
        metadata_s3_keys[metadata_table_name] = metadata_s3_key

    logger.info(f"key: {key}")
    parquet_table_name = key.rsplit("/", 2)[1].lower()

    logger.info(f"Metadata S3 keys: {metadata_s3_keys}")
    logger.info(f"Parquet table name: {parquet_table_name}")

    try:
        fileValidator = FileValidator(
            key=key,
            pass_bucket=pass_bucket,
            fail_bucket=fail_bucket,
            bucket_from=bucket_from,
            parquet_table_name=parquet_table_name,
            metadata_s3_keys=metadata_s3_keys,
            metadata_bucket=metadata_bucket,
            valid_files_mutable=valid_files_mutable
        )
    except Exception as e:
        logger.exception(f"Error creating FileValidator: {e}")
        # Raise exception to stop the Lambda function
        raise e

    fileValidator.execute()
