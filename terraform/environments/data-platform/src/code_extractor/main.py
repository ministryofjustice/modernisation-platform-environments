import boto3
import zipfile
import io

s3 = boto3.resource("s3")


def handler(event, context):

    print("event", event)
    print("bucketname:", event["detail"]["bucket"]["name"])
    print("Key:", event["detail"]["object"]["key"])

    # specify the bucket name and the key of the zip file
    bucket_name = event["detail"]["bucket"]["name"]
    zip_key = event["detail"]["object"]["key"]

    # get the zip file object from S3
    zip_obj = s3.Object(bucket_name, zip_key)

    # read the contents of the zip file
    buffer = io.BytesIO(zip_obj.get()["Body"].read())
    print(buffer)

    # create a ZipFile object from the buffer
    zipfile_object = zipfile.ZipFile(buffer)

    # specify the output bucket name and prefix for the unzipped files
    output_bucket_name = bucket_name
    output_prefix = "code/output_script/"

    # iterate through each file in the zip file
    for file in zipfile_object.namelist():
        # read the file from the zip file
        file_data = zipfile_object.read(file)

        # write the file to the output bucket
        s3.Object(output_bucket_name, output_prefix + file).put(Body=file_data)

    print("File saved")
