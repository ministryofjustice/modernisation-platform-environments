"""
takes the json mojap metadatas of each table and moves them to the AP
"""

import boto3
import os
import logging
import json

s3 = boto3.client("s3")

logger = logging.getLogger(__name__)
logger.setLevel(logging.INFO)


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
            # and is preceded by upper case but followed by lower case so
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


def handler(event, context):
    # Specify source bucket
    source_bucket_name = event["Records"][0]["s3"]["bucket"]["name"]
    destination_bucket = os.environ.get("METADATA_BUCKET_NAME")
    # Get object that has been uploaded
    file_key = event["Records"][0]["s3"]["object"]["key"].replace("%3D", "=")
    file_parts = file_key.split("/")
    database_name = file_parts[0].split("=")[-1]
    table_name = file_parts[1].split("=")[-1]
    file_name = file_parts[2]
    logger.info(
        f"Copying metadata... Database: {database_name}, Table: {table_name}, File: {file_name}"
    )
    if not file_name.endswith(".json"):
        msg = f"File {file_name} is not a json file"
        logger.error(msg)
        raise Exception(msg)
    snake_table_name = make_snake(table_name)
    destination_key = f"electronic_monitoring/metadata/database_name={database_name}/{snake_table_name}.json"
    logger.info(f"Copying to: {destination_bucket}, {destination_key}")
    # Specify from where file needs to be copied
    copy_object = {"Bucket": source_bucket_name, "Key": file_key}

    try:
        # Put the object into the destination bucket
        response = s3.copy_object(
            Bucket=destination_bucket,
            Key=destination_key,
            CopySource=copy_object,
            ServerSideEncryption="AES256",
            ACL="bucket-owner-full-control",
            BucketKeyEnabled=True,
        )
        response_code = response["ResponseMetadata"]["HTTPStatusCode"]
        if response_code == 200:
            logger.info(f"{file_name} succesfully transferred to {destination_bucket}")
        else:
            msg = f"An error has occurred writing {destination_key} to {destination_bucket}, with response code: {response_code}"
            logger.error(msg)
            raise Exception(msg)
    except Exception as e:
        msg = f"An exception has occured: {e}"
        logger.error(msg)
        raise Exception(msg)

    return {
        "statusCode": 200,
        "body": json.dumps("File has been Successfully Copied"),
    }
