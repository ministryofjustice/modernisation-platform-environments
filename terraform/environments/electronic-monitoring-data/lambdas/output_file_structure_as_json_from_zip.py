import base64
import datetime
import gzip
import io
import json
import logging

from aws_lambda_powertools.utilities.streaming.transformations import ZipTransform
from aws_lambda_powertools.utilities.streaming.s3_object import S3Object
import boto3


logger = logging.getLogger(__name__)
logger.setLevel(logging.INFO)

def upload_json_gz(s3client, bucket, key, obj, default=None, encoding='utf-8'):
    ''' upload python dict into s3 bucket with gzip archive '''
    inmem = io.BytesIO()
    with gzip.GzipFile(fileobj=inmem, mode='wb') as fh:
        with io.TextIOWrapper(fh, encoding=encoding) as wrapper:
            wrapper.write(json.dumps(obj, ensure_ascii=False, default=default))
    inmem.seek(0)
    s3client.put_object(Bucket=bucket, Body=inmem, Key=key)


def handler(event, context):
    """
    Read contents of a zip file to create a json file convertable into tabular format consumable by Athena. 
    This json file describes the directory structure surrounding each deepest level file, 
    and populates key-value pairs that can be interpreted as columns and row values later.
    """

    logger.info(event)

    event_type = event["Records"][0]["eventName"]
    bucket = event["Records"][0]["s3"]["bucket"]["name"]
    object_key = event["Records"][0]["s3"]["object"]["key"]

    # Create S3 client
    s3_client = boto3.client("s3")

    s3_object = S3Object(bucket=bucket, key=object_key)

    logger.info(f"Read in {object_key} from S3.")

    # Extract files from the zip
    zip_ref = s3_object.transform(ZipTransform())

    # Extract a list of all deeply nested files in the zip, and construct a json file
    json_structure = {"data": []}
    data_list = []
    file_count = 0

    logger.info(f"Looping through all files and collecting metadata into tabular format.")

    for file in zip_ref.namelist():
        if not file.endswith("/"):
            info = zip_ref.getinfo(file)
            file_count+=1
            parts = file.split("/")
            json_schema = {
                'ParentGroup': parts[-6], 
                'SubGroup': parts[-5], 
                'PrimaryField': parts[-4], 
                'SecondaryField': parts[-3], 
                'ReportType': parts[-2], 
                'FileName': parts[-1],
                'FileSize': info.file_size,
                'Modified': f"{datetime.datetime(*info.date_time)}"
            }
            data_list.append(json_schema)
            json_structure['data'] = data_list

    logger.info(f"\n\nNumber of files processed in zip file:\n{file_count}")

    # Saving JSON content to a new file with .json extension
    new_file_base_name = object_key.split(".zip")[0]
    uncompressed_object_key = new_file_base_name + "_uncompressed_file_structure.json"
    compressed_object_key = new_file_base_name + "_compressed_file_structure.json.gz"

    #Uncompressed variant for testing
    logger.info(f"Attempting conversion of large dictionary into an uncompressed json file")

    json_str = json.dumps(json_structure)
    json_bytes = json_str.encode('utf-8')

    s3_client.put_object(
        Bucket=bucket, Key=uncompressed_object_key, Body=json_bytes
    )
    logger.info(f"Uncompressed JSON saved to {uncompressed_object_key}")

    #Compressed json for comparison

    logger.info(f"\n\nPerforming JSON compression")

    upload_json_gz(s3_client, bucket, compressed_object_key, json_structure)

    #s3_client.put_object(
    #    Bucket=bucket, Key=compressed_object_key, Body=gzip.compress(json_str)
    #)

    logger.info(f"Compressed JSON saved to {compressed_object_key}")

    return None
