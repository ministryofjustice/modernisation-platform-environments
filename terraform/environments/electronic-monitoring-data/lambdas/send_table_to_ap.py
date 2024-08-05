import json
import boto3
import datetime
import logging
import os

logger = logging.getLogger(__name__)
logger.setLevel(logging.INFO)


s3_client = boto3.client("s3")

AP_DESTINATION_BUCKET = os.environ.get("AP_DESTINATION_BUCKET")

def s3_path_to_bucket_key(s3_path):
    """
    Splits out s3 file path to bucket key combination
    """
    return s3_path.replace("s3://", "").split("/", 1)


def camel_to_snake(camel_case: str) -> str:
    """Convert a CamelCase string to snake_case.
    Parameters
    ----------
    camel_case
        The CamelCase string to be converted to snake_case.
    Returns
    -------
    str
        The snake_case representation of the input string.
    Raises
    ------
    ValueError
        If camel_case is an all upper case string.
    Example
    -------
    >>> snake_string = camel_to_snake('CamelCase')
    >>> print(snake_string)
    'camel_case'
    """
    if camel_case.isupper():
        msg = f"{camel_case} is all upper case. Cannot convert to snake case."
        raise ValueError(msg)

    snake_case = ""

    for i, char in enumerate(camel_case):
        if (
            i > 0
            and i != len(camel_case) - 1
            and char.isupper()
            and camel_case[i - 1].isupper()
            and camel_case[i + 1].islower()
        ):
            # Character is not the first or last character and is upper case
            # and is preceded by upper case but followed by lower case so
            # presume is start of a new word.
            snake_case += "_"

        elif i > 0 and char.isupper() and camel_case[i - 1].isupper():
            # Character is not the first character and is upper case
            # and is preceded by upper case character so presume is part of a
            # "shout-y" word and so don't precede the character with _
            pass

        elif char.isupper() and i > 0:
            # Not the first character in the string so want to put an _ before
            # it.
            snake_case += "_"

        if not char.isalnum():
            snake_case += "_"

        snake_case += char.lower()

    return snake_case


def make_snake(string: str) -> str:
    """Convert given string to snake_case.
    This will attempt to convert in order:
    1. if string already contains `_` then just ensure all characters are lower
       case and then return it
    2. if the string is all upper case, convert to lower and return
    3. otherwise pass through to the camel_to_snake function.
    """
    if "_" in string:
        string_elements = string.split("_")
        return "_".join([make_snake(element) for element in string_elements])
    elif string.isupper():
        return string.lower()
    else:
        return camel_to_snake(string)


# lambda function to copy file from 1 s3 to another s3
def handler(event, context):
    # Specify source bucket
    for key, value in event.items():
        database_table_name, source_s3_key = key, value
    bucket, source_key = s3_path_to_bucket_key(source_s3_key)
    database_name, schema_name, table_name, file_name = source_key.split("/")

    ap_table_name = make_snake(table_name)
    logger.info(f"Copying table {table_name} from database {database_name}")
    destination_key = f"electronic_monitoring/load/{database_name}/{ap_table_name}/{file_name}"
    logger.info(
        f"""Copying file: {source_key} from bucket: {bucket}
        to {destination_key} in bucket: {AP_DESTINATION_BUCKET}"""
    )

    copy_object = {"Bucket": bucket, "Key": source_key}

    try:
        # Put the object into the destination bucket
        response = s3_client.copy_object(
            Bucket=AP_DESTINATION_BUCKET,
            Key=destination_key,
            CopySource=copy_object,
            ServerSideEncryption="AES256",
            ACL="bucket-owner-full-control",
            BucketKeyEnabled=True,
        )
        response_code = response["ResponseMetadata"]["HTTPStatusCode"]
        if response_code == 200:
            logger.info(f"{source_key} succesfully transferred to {AP_DESTINATION_BUCKET}")
        else:
            msg = f"An error has occurred writing {destination_key} to {AP_DESTINATION_BUCKET}, with response code: {response_code}"
            logger.error(msg)
            raise Exception(msg)
    except Exception as e:
        msg = f"An exception has occured: {e}"
        logger.error(msg)
        raise Exception(msg)

    return (database_name, schema_name, table_name)
