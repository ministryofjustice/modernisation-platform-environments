import json
import boto3
import re
import logging
import os

logger = logging.getLogger(__name__)
logger.setLevel(logging.INFO)

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

# Lambda function to copy file from one S3 bucket to another
def handler(event, context):
    # Specify source bucket
    for key, value in event.items():
        database_name, table_name = key, value
    logger.info(f"Copying table {table_name} from database {database_name}")

    source_key = f"{database_name}/*/{table_name}"
    destination_key = f"electronic_monitoring/load/{database_name}/{table_name}/"
    logger.info(f"Getting file keys: {source_key} from bucket: {PARQUET_BUCKET_NAME}")

    # List objects in the source folder and filter using regex pattern
    file_paths = get_filepaths_from_s3_folder(f"s3://{PARQUET_BUCKET_NAME}/{database_name}/")
    pattern = re.compile(rf'{database_name}/.*?/{table_name}', re.IGNORECASE)
    filtered_paths = [path for path in file_paths if pattern.search(path)]

    logger.info(f"Number of files: {len(filtered_paths)}")

    # Return list of file paths that match the pattern
    return [{source_key: file_path} for file_path in filtered_paths]
