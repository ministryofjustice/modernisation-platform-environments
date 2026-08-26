"""exec into your aws account, run python3 
   python_scripts/s3_checksum_comparison.py bucket1 bucket2 to compare between buckets 1 and 2"""

import boto3
import typer
import os
import logging
from types import SimpleNamespace

logging.basicConfig(level=logging.INFO)


app = typer.Typer(chain=True)

s3 = boto3.client("s3")

logger = logging.getLogger(__name__)

def get_etags_all_objects(bucket_name: str):
    "gets the metadata of all objects in an s3 bucket"
    total_metadata = s3.list_objects_v2(Bucket=bucket_name)
    etags = {meta["Key"]: meta["ETag"] for meta in total_metadata["Contents"]}
    return etags

def copy_bucket_contents(source_bucket, destination_bucket):
    """Function to copy all objects from source bucket to destination bucket."""
    logger.info(f"Copying contents from {source_bucket} to {destination_bucket}...")
    # Use AWS CLI to sync the buckets
    os.system(f"aws s3 sync s3://{source_bucket} s3://{destination_bucket}")

def delete_bucket_contents(bucket_name: str):
    """Function to delete all objects from a specified S3 bucket."""
    logger.info(f"Deleting contents from {bucket_name}...")
    object_response_paginator = s3.get_paginator('list_object_versions')

    delete_marker_list = []
    version_list = []

    for object_response_itr in object_response_paginator.paginate(Bucket=bucket_name):
        if 'DeleteMarkers' in object_response_itr:
            for delete_marker in object_response_itr['DeleteMarkers']:
                delete_marker_list.append({'Key': delete_marker['Key'], 'VersionId': delete_marker['VersionId']})

        if 'Versions' in object_response_itr:
            for version in object_response_itr['Versions']:
                version_list.append({'Key': version['Key'], 'VersionId': version['VersionId']})

    for i in range(0, len(delete_marker_list), 1000):
        response = s3.delete_objects(
            Bucket=bucket_name,
            Delete={
                'Objects': delete_marker_list[i:i+1000],
                'Quiet': True
            }
        )
        print(response)

    for i in range(0, len(version_list), 1000):
        response = s3.delete_objects(
            Bucket=bucket_name,
            Delete={
                'Objects': version_list[i:i+1000],
                'Quiet': True
            }
        )
        logger.info(response)

@app.callback()
def get_bucket_names(ctx: typer.Context):
    # Input from user for source and destination prefixes
    source_prefix = typer.prompt("Enter the prefix of the source S3 bucket")
    destination_prefix = typer.prompt("Enter the prefix of the destination S3 bucket")

    # List source buckets that start with the given prefix and exclude ones with 'logs' suffix
    source_buckets_response = s3.list_buckets()
    source_buckets = [
        bucket['Name'] for bucket in source_buckets_response['Buckets'] 
        if bucket['Name'].startswith(source_prefix) and not bucket['Name'].endswith('logs')
    ]
    
    if not source_buckets:
        logger.error(f"No source buckets found with the prefix '{source_prefix}' (excluding buckets with 'logs' suffix)")
        raise typer.Exit()

    elif len(source_buckets) > 1:
        selected_source_bucket = None
        for source_bucket in source_buckets:
            answer = typer.prompt(f"Select source bucket: {source_bucket} (y/n)?").lower()
            if answer == "y":
                selected_source_bucket = source_bucket
                break
    else:
        selected_source_bucket = source_buckets[0]

    # List destination buckets that start with the destination prefix
    destination_buckets = [
        bucket['Name'] for bucket in source_buckets_response['Buckets']
        if bucket['Name'].startswith(destination_prefix)
    ]

    if not destination_buckets:
        logger.error(f"No destination buckets found with the prefix '{destination_prefix}'")
        raise typer.Exit()
    elif len(destination_buckets) > 1:
        selected_destination_bucket = None
        for destination_bucket in destination_buckets:
            answer = typer.prompt(f"Select destination bucket: {destination_bucket} (y/n)?").lower()
            if answer == "y":
                selected_destination_bucket = destination_bucket
                break
    else:
        selected_destination_bucket = destination_buckets[0]

    ctx.obj = SimpleNamespace(source_bucket = selected_source_bucket, destination_bucket = selected_destination_bucket)



@app.command("copy")
def pair_and_copy_buckets(ctx: typer.Context):
    """Main function for the bucket copying process."""
    source_bucket = ctx.obj.source_bucket
    destination_bucket = ctx.obj.destination_bucket
    copy_bucket_contents(source_bucket, destination_bucket)
    logger.info("\nThe following bucket pairs were copied:")
    logger.info(f"Source: {source_bucket}, Destination: {destination_bucket}")

@app.command("verify")
def compare_buckets(ctx: typer.Context):
    source_bucket = ctx.obj.source_bucket
    destination_bucket = ctx.obj.destination_bucket
    original_bucket_tags = get_etags_all_objects(source_bucket)
    new_bucket_tags = get_etags_all_objects(destination_bucket)
    bucket_tags_diff = set(original_bucket_tags) ^ set(new_bucket_tags)
    if original_bucket_tags == new_bucket_tags or len(bucket_tags_diff) == 0:
        logger.info("Buckets are the same")
    else:
        logger.warning(f"Buckets are different:")
        for key in bucket_tags_diff:
            if (key in original_bucket_tags) and (key in new_bucket_tags):
                logger.warning(f"Original: {original_bucket_tags[key]}")
                logger.warning(f"New: {new_bucket_tags[key]}")
            elif (key in original_bucket_tags) and (key not in new_bucket_tags):
                logger.warning(f"{key} not in new bucket")
            elif (key not in original_bucket_tags) and (key in new_bucket_tags):
                logger.warning(f"{key} not in original bucket")

@app.command("delete")
def delete_from_bucket(ctx: typer.Context):
    source_bucket = ctx.obj.source_bucket
    delete_bucket_contents(source_bucket)


if __name__ == "__main__":
    app()