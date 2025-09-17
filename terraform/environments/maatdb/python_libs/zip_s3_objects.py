#!/usr/bin/env python3.12
import os
import logging
import zipfile
import datetime
import boto3

LOGGER = logging.getLogger()
LOGGER.setLevel(os.environ.get("LOGLEVEL", "INFO"))

# === ENV ===
BUCKET = os.environ.get("BUCKET")                 # required
LOCALPATH = os.environ.get("LOCALPATH") or ""     # optional prefix (e.g., "some/folder/")
FILETYPES = os.environ.get("FILETYPES")           # e.g., "csv,txt"
ARCHIVE_NAME = os.environ.get("ARCHIVE_NAME")     # required
REMOVEFILESAFTER = (os.environ.get("REMOVEFILESAFTER") or "").upper() == "YES"

ARCHIVE_SUFFIX = datetime.datetime.now(datetime.timezone.utc).strftime("%y%m%d%H%M%S")

FILE_EXTENSIONS = None
if FILETYPES:
    FILE_EXTENSIONS = tuple("." + ext.strip().lstrip(".") for ext in FILETYPES.split(","))

# Validate required env
if not BUCKET or not ARCHIVE_NAME:
    LOGGER.error("Need BUCKET & ARCHIVE_NAME defined")
    raise Exception("Need BUCKET & ARCHIVE_NAME defined")

def iter_keys(s3, bucket: str, prefix: str):
    """Yield object keys under prefix (skips folder placeholders)."""
    paginator = s3.get_paginator("list_objects_v2")
    for page in paginator.paginate(Bucket=bucket, Prefix=prefix):
        for obj in page.get("Contents", []):
            key = obj["Key"]
            if key.endswith("/") or key == prefix:
                continue
            yield key

def should_include(key: str) -> bool:
    return key.endswith(FILE_EXTENSIONS) if FILE_EXTENSIONS else True

def lambda_handler(event, context):
    s3 = boto3.client("s3")
    cloudwatch = boto3.client("cloudwatch")

    prefix = LOCALPATH
    full_zip_name = f"{ARCHIVE_NAME}-{ARCHIVE_SUFFIX}.zip"
    zip_path = os.path.join("/tmp", full_zip_name)

    # --- Collect eligible files ---
    keys_to_archive = [key for key in iter_keys(s3, BUCKET, prefix) if should_include(key)]

    if not keys_to_archive:
        LOGGER.info("No files to archive under prefix '%s'", prefix)
        if context:
            cloudwatch.put_metric_data(
                Namespace="lambda_ftp",
                MetricData=[{
                    "MetricName": "Fetched S3 Objects",
                    "Dimensions": [{"Name": "Lambda name", "Value": context.function_name}],
                    "Timestamp": datetime.datetime.now(datetime.timezone.utc),
                    "Value": 0,
                    "Unit": "Count",
                }],
            )
        return {"archived": 0, "archive_key": None}

    processed = 0
    keys_to_delete = []

    LOGGER.info("Creating ZIP at %s", zip_path)
    # --- Create ZIP ---
    with zipfile.ZipFile(zip_path, "w", compression=zipfile.ZIP_DEFLATED) as zf:
        for key in keys_to_archive:
            # Determine archive name
            arcname = os.path.basename(key) if prefix else key
            LOGGER.info("Adding %s as %s", key, arcname)

            obj = s3.get_object(Bucket=BUCKET, Key=key)
            body = obj["Body"]
            with zf.open(arcname, "w") as dest:
                for chunk in iter(lambda: body.read(1024 * 1024), b""):
                    dest.write(chunk)

            processed += 1
            keys_to_delete.append(key)

    # --- Upload ZIP to S3 ---
    dest_key = f"{prefix}{full_zip_name}" if prefix else full_zip_name
    LOGGER.info("Uploading ZIP to s3://%s/%s", BUCKET, dest_key)
    s3.upload_file(zip_path, BUCKET, dest_key)

    # --- Optional cleanup of source objects ---
    if REMOVEFILESAFTER and keys_to_delete:
        LOGGER.info("Deleting %d source objects", len(keys_to_delete))
        for i in range(0, len(keys_to_delete), 1000):
            batch = [{"Key": k} for k in keys_to_delete[i : i + 1000]]
            s3.delete_objects(Bucket=BUCKET, Delete={"Objects": batch, "Quiet": True})

    # --- Emit CloudWatch metric ---
    if context:
        cloudwatch.put_metric_data(
            Namespace="lambda_ftp",
            MetricData=[{
                "MetricName": "Fetched S3 Objects",
                "Dimensions": [{"Name": "Lambda name", "Value": context.function_name}],
                "Timestamp": datetime.datetime.now(datetime.timezone.utc),
                "Value": processed,
                "Unit": "Count",
            }],
        )

    # --- Clean up local ZIP ---
    try:
        os.remove(zip_path)
    except OSError:
        pass

    LOGGER.info("Archived %d objects to %s", processed, dest_key)
    return {"archived": processed, "archive_key": dest_key}