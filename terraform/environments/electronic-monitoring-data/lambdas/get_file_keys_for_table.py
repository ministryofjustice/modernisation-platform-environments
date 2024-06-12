import json
import boto3
from logging import getLogger
import os

logger = getLogger(__name__)

s3_client = boto3.client("s3")

PARQUET_BUCKET_NAME = os.environ.get("PARQUET_BUCKET_NAME")

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

def s3_path_to_bucket_key(s3_path):
    """
    Splits out s3 file path to bucket key combination
    """
    return s3_path.replace("s3://", "").split("/", 1)

def get_filepaths_from_s3_folder(
    s3_folder_path, file_extension=None, exclude_zero_byte_files=False
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

# lambda function to copy file from 1 s3 to another s3
def handler(event, context):
    # Specify source bucket
    for key, value in event.items():
        database_name, table_name = key, value
    logger.info(f"Copying table {table_name} from database {database_name}")
    source_key = f"{database_name}/{table_name}"
    destination_key = f"electronic_monitoring/load/{database_name}/{table_name}/"
    logger.info(
        f"""Getting file keys: {source_key} from bucket: {PARQUET_BUCKET_NAME}"""
    )

    file_paths = get_filepaths_from_s3_folder(f"s3://{PARQUET_BUCKET_NAME}/{source_key}/")

    return [{source_key: file_path} for file_path in file_paths]
