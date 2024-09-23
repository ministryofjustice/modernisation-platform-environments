"""exec into your aws account, run python3 
   python_scripts/s3_checksum_comparison.py bucket1 bucket2 to compare between buckets 1 and 2"""

import boto3
import typer

app = typer.Typer()

s3 = boto3.client("s3")


def get_etags_all_objects(bucket_name: str):
    "gets the metadata of all objects in an s3 bucket"
    total_metadata = s3.list_objects_v2(Bucket=bucket_name)
    etags = {meta["Key"]: meta["ETag"] for meta in total_metadata["Contents"]}
    return etags


@app.command()
def compare_buckets(original_bucket: str, new_bucket: str):
    original_bucket_tags = get_etags_all_objects(original_bucket)
    new_bucket_tags = get_etags_all_objects(new_bucket)
    bucket_tags_diff = set(original_bucket_tags) ^ set(new_bucket_tags)
    if original_bucket_tags == new_bucket_tags or len(bucket_tags_diff) == 0:
        print("Buckets are the same")
    else:
        print(f"Buckets are different: {str(bucket_tags_diff)}")
        for key in bucket_tags_diff:
            if (key in original_bucket_tags) and (key in new_bucket_tags):
                print(f"Original: {original_bucket_tags[key]}")
                print(f"New: {new_bucket_tags[key]}")
            elif (key in original_bucket_tags) and (key not in new_bucket_tags):
                print(f"{key} not in new bucket")
            elif (key not in original_bucket_tags) and (key in new_bucket_tags):
                print(f"{key} not in original bucket")


if __name__ == "__main__":
    app()
