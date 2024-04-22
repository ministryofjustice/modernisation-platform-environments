import boto3
from logging import getLogger
import sys
import json

logger = getLogger(__name__)
AWS_REGION = "eu-west-2"

# Initialize Boto3 client for S3
s3 = boto3.client("s3")


def invoke_copy_lambda(
    source_bucket_name, file_key, lambda_function_name, destination_bucket_name
):
    """
    Invoke the Lambda function to copy file from source to destination bucket.
    """
    lambda_client = boto3.client("lambda", region_name=AWS_REGION)
    payload = {
        "source_bucket_name": source_bucket_name,
        "file_key": file_key,
        "destination_bucket_name": destination_bucket_name,
    }
    response = lambda_client.invoke(
        FunctionName=lambda_function_name,
        InvocationType="Event",  # Asynchronous invocation
        Payload=json.dumps(payload),
    )
    logger.info(f"Invoked Lambda '{lambda_function_name}' to copy file '{file_key}'")


def process_s3_bucket(bucket_name, lambda_function_name):
    """
    List objects in the S3 bucket and invoke Lambda for each object.
    """
    try:
        # List objects in the bucket
        response = s3.list_objects_v2(Bucket=bucket_name)

        # If there are objects, invoke Lambda for each object
        if "Contents" in response:
            for obj in response["Contents"]:
                file_key = obj["Key"]
                invoke_copy_lambda(file_key, lambda_function_name)
        else:
            print(f"No objects found in the bucket '{bucket_name}'.")
    except Exception as e:
        print(f"Error: {str(e)}")


if __name__ == "__main__":
    if len(sys.argv) != 3:
        logger.info("Usage: python script.py <bucket_name> <lambda_function_name>")
        sys.exit(1)

    bucket_name = sys.argv[1]
    lambda_function_name = sys.argv[2]

    process_s3_bucket(bucket_name, lambda_function_name)
