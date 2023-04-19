import boto3
import zipfile
import io
import os
import logging
from pathlib import Path

logging.getLogger().setLevel(logging.INFO)
s3 = boto3.client("s3")


def handler(event, context):

    logging.info(f"event: {event}")

    # specify the bucket name and the key of the zip file
    bucket_name = event["detail"]["requestParameters"]["bucketName"]
    zip_key = event["detail"]["requestParameters"]["key"]

    logging.info(f"bucketname: {bucket_name}")
    logging.info(f"Key: {zip_key}")

    # get the zip file object from S3
    zip_obj = s3.get_object(Bucket=bucket_name, Key=zip_key)

    # read the contents of the zip file
    buffer = io.BytesIO(zip_obj.get("Body").read())
    zipfile_object = zipfile.ZipFile(buffer)

    # specify the output bucket name and prefix for the unzipped files
    output_bucket_name = bucket_name
    # eg code_zips/example_2/file.zip
    project = Path(zip_key).parts[1]
    output_prefix = os.path.join("code", project, "extracted")
    logging.info(f"output_prefix: {output_prefix}")

    # iterate through each file in the zip file
    for file in zipfile_object.namelist():
        # read the file from the zip file
        file_data = zipfile_object.open(file)
        output_key = os.path.join(output_prefix, file)

        # write the file to the output bucket
        try:
            s3.upload_fileobj(file_data, output_bucket_name, output_key)
        except Exception as e:
            logging.error(e)
        logging.info(f"{file} successfully uploaded")

    logging.info("Unzip completed")
