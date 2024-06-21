import boto3
import json
from logging import getLogger
from aws_lambda_powertools.utilities.streaming.transformations import ZipTransform
from aws_lambda_powertools.utilities.streaming.s3_object import S3Object

logger = getLogger(__name__)


def handler(event, context):
    """
    Read contents of a zip file and log directory structure and item count.
    """
    logger.info(event)

    event_type = event["Records"][0]["eventName"]
    bucket = event["Records"][0]["s3"]["bucket"]["name"]
    object_key = event["Records"][0]["s3"]["object"]["key"]

    # Check if the object key ends with '.zip'
    if not object_key.endswith(".zip"):
        logger.info(f"Stopping for'{object_key = }' as suffix other than '.zip'")
        return None

    logger.info(f"{object_key = } added to {bucket = } via {event_type = }")

    # Create S3 client
    s3_client = boto3.client("s3")

    s3_object = S3Object(bucket=bucket, key=object_key)

    logger.info(f"Read in {object_key} from S3.")

    # Extract files from the zip
    zip_ref = s3_object.transform(ZipTransform())
    # List all files in the zip
    file_list = zip_ref.namelist()

    # Total number of files
    total_files = len(file_list)
    logger.info(f"Looping through {total_files} files.")
    # Directory structure dictionary
    directory_structure = {}

    # Read each file's content and build directory structure
    for file_name in file_list:
        if not file_name.endswith("/"):
            parts = file_name.split("/")
            current_dict = directory_structure

            # Traverse the directory structure and create dictionary entries
            for part in parts[:-1]:
                if part not in current_dict:
                    current_dict[part] = {}
                current_dict = current_dict[part]

    logger.info(f"\n\nJSON directory structure:\n{directory_structure}")

    logger.info(f"\n\n Total files in {object_key}: {total_files}")

    # Writing the JSON file with the information
    json_data = {
        "total_objects": total_files,
        "directory_structure": directory_structure,
    }
    json_content = json.dumps(json_data)

    # Saving JSON content to a new file with .json extension
    new_object_key = object_key + ".info.json"

    s3_client.put_object(
        Bucket=bucket, Key=new_object_key, Body=json_content.encode("utf-8")
    )

    logger.info(f"Zip info saved to {new_object_key}")

    return None
