"""exec into your aws account, run python3 
   python_scripts/s3_checksum_comparison.py bucket1 bucket2 to compare between buckets 1 and 2"""

import boto3
import typer

app = typer.Typer()

s3 = boto3.client("s3")


def get_etags_all_objects(bucket_name: str):
    "gets the metadata of all objects in an s3 bucket"
    total_metadata = s3.list_objects_v2(bucket_name)
    etags = {meta["Key"]: meta["ETag"] for meta in total_metadata["Contents"]}
    return etags


@app.command
def compare_buckets(original_bucket: str, new_bucket: str):
    original_bucket_tags = get_etags_all_objects(original_bucket)
    new_bucket_tags = get_etags_all_objects(new_bucket)
    if original_bucket_tags == new_bucket_tags:
        print("Buckets are the same")
    else:
        bucket_tags_diff = set(original_bucket_tags) ^ set(new_bucket_tags)
        print(str(bucket_tags_diff))


if __name__ == "__main__":
    app.run()
