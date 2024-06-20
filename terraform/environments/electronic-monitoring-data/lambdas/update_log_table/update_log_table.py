import pandas as pd
import boto3
import logging
import os

logger = logging.getLogger(__name__)

logger.setLevel(logging.INFO)

S3_LOG_BUCKET = os.environ.get("S3_LOG_BUCKET")
DATABASE_NAME = os.envrion.get("DATABASE_NAME")
TABLE_NAME = os.environ.get("TABLE_NAME")

def s3_path_to_bucket_key(s3_path):
    """
    Splits out s3 file path to bucket key combination
    """
    return s3_path.replace("s3://", "").split("/", 1)


def bucket_key_to_s3_path(bucket, key):
    """
    Takes an S3 bucket and key combination and returns the
    full S3 path to that location.
    """
    return f"s3://{bucket}/{key}"


def _add_slash(s):
    """
    Adds slash to end of string
    """
    return s if s[-1] == "/" else s + "/"


def get_filepaths_from_s3_folder(
    s3_folder_path, file_extension=None, exclude_zero_byte_files=True
):
    """
    Get a list of filepaths from a bucket. If extension is set to a string
    then only return files with that extension otherwise if set to None (default)
    all filepaths are returned.
    :param s3_folder_path: "s3://...."
    :param extension: file extension, e.g. .json
    :param exclude_zero_byte_files: Whether to filter out results of zero size: True
    :return: A list of full s3 paths that were in the given s3 folder path
    """

    s3_resource = boto3.resource("s3")

    if file_extension is not None:
        if file_extension[0] != ".":
            file_extension = "." + file_extension

    # This guarantees that the path the user has given is really a 'folder'.
    s3_folder_path = _add_slash(s3_folder_path)

    bucket, key = s3_path_to_bucket_key(s3_folder_path)

    s3b = s3_resource.Bucket(bucket)
    obs = s3b.objects.filter(Prefix=key)

    if file_extension is not None:
        obs = [o for o in obs if o.key.endswith(file_extension)]

    if exclude_zero_byte_files:
        obs = [o for o in obs if o.size != 0]

    ob_keys = [o.key for o in obs]

    paths = sorted([bucket_key_to_s3_path(bucket, o) for o in ob_keys])

    return paths

def handler(event, context):
    database_name, schema_name, table_name = event.get("db_info")
    s3_path = f"s3://{S3_LOG_BUCKET}/{DATBASE_NAME}/{TABLE_NAME}/database_name={database_name}/full_table_name={database_name}_{schema_name}_{table_name}"
    file_names = [file.split("/")[-1] for file in get_filepaths_from_s3_folder(s3_path)]
    log_table = pd.read_parquet(s3_path)
    log_table["table_to_ap"] = "True"
    try:
        log_table.to_parquet(f"{s3_path}/{file_names[0]}")
    except Exception as e:
        msg = f"An error has occured: {e}"
        logger.error(msg)
        raise msg
    return {}