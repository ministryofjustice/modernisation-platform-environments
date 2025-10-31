import boto3
import pyarrow.parquet as pq
import typer
from logging import getLogger

logger = getLogger(__name__)
s3 = boto3.client("s3")
glue = boto3.client("glue")

BUCKET_PREFIX = "dms-data-validation"

app = typer.Typer()


def get_bucket_name(bucket_prefix: str = BUCKET_PREFIX):
    bucket_names = [bucket["Name"] for bucket in s3.list_buckets()["Buckets"]]
    for bucket_name in bucket_names:
        if str(bucket_name).startswith(bucket_prefix):
            return bucket_name
    msg = f"No bucket with prefix {bucket_prefix} in this account's S3 buckets."
    logger.error(msg)
    raise TypeError(msg)


def get_all_file_paths(bucket_name, database_name):
    base_s3_path = f"dms_data_validation/glue_df_output/database_name={database_name}/"
    file_paths = [
        response["Key"]
        for response in s3.list_objects_v2(Bucket=bucket_name, Prefix=base_s3_path)[
            "Contents"
        ]
    ]
    return [file_path for file_path in file_paths if file_path.endswith("parquet")]


def replace_table_values(file_path):
    data = pq.read_table(file_path).to_pandas()
    data["table_to_ap"] = "False"
    response = data.to_parquet(file_path)
    return response


@app.command()
def rewrite_database_as_not_in_ap(database_name: str):
    bucket_name = get_bucket_name()
    file_paths = get_all_file_paths(bucket_name, database_name)
    for file_path in file_paths:
        replace_table_values(f"s3://{bucket_name}/{file_path}")


if __name__ == "__main__":
    app()
