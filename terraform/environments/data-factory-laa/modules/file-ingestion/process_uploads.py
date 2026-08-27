import awswrangler as wr
import boto3
import os

s3 = boto3.client("s3")

FILE_UPLOADS_BUCKET = os.environ["FILE_UPLOADS_BUCKET"]
PROCESSED_FILE_UPLOADS_BUCKET = os.environ["PROCESSED_FILE_UPLOADS_BUCKET"]
DATABASE_NAME = os.environ["DATABASE_NAME"]
KMS_KEY_ARN = os.environ["KMS_KEY_ARN"]


def lambda_handler(event, context):
    # Get first-level directories only
    paginator = s3.get_paginator("list_objects_v2")

    directories = []

    for page in paginator.paginate(
        Bucket=FILE_UPLOADS_BUCKET,
        Delimiter="/",
    ):
        directories.extend(
            prefix["Prefix"]
            for prefix in page.get("CommonPrefixes", [])
        )

    for directory in directories:
        table_name = directory.rstrip("/")

        print(f"Processing table: {table_name}")

        csv_path = f"s3://{FILE_UPLOADS_BUCKET}/{directory}*.csv"

        try:
            print(f"Reading {table_name} using UTF-8")

            df = wr.s3.read_csv(
                path=csv_path,
                encoding="utf-8",
                use_threads=False,
            )

        except UnicodeDecodeError as exc:
            print(
                f"UTF-8 decoding failed for {table_name}: {exc}. "
                "Retrying with cp1252."
            )

            df = wr.s3.read_csv(
                path=csv_path,
                encoding="cp1252",
                use_threads=False,
            )

        print(f"Read {len(df)} rows for table {table_name}")

        wr.s3.to_parquet(
            df=df.astype(str),
            path=f"s3://{PROCESSED_FILE_UPLOADS_BUCKET}/{table_name}/",
            dataset=True,
            database=DATABASE_NAME,
            table=table_name,
            mode="overwrite",
            s3_additional_kwargs={
                "ServerSideEncryption": "aws:kms",
                "SSEKMSKeyId": KMS_KEY_ARN,
            },
        )

        print(f"Finished processing table: {table_name}")
