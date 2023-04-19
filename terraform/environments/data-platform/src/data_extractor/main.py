from __future__ import print_function
import boto3
import logging
import os
from pathlib import Path

logging.getLogger().setLevel(logging.INFO)
glue = boto3.client("glue")


def handler(event, context):
    logging.info("Event detail:")
    logging.info(event)
    gluejobname = os.environ.get("GLUE_JOB_NAME")

    try:
        bucket_name = event["detail"]["requestParameters"]["bucketName"]
        file_key = event["detail"]["requestParameters"]["key"]
        logging.info(f"Bucket name: {bucket_name}")
        logging.info(f"File key: {file_key}")
        project = Path(file_key).parts[1]
        transform_file_path = os.path.join(
            "s3://",
            bucket_name,
            "code",
            project,
            "extracted",
            "application",
            "transform.py",
        )
        logging.info("Transform filepath: ", transform_file_path)

        args = {
            "--bucketName": bucket_name,
            "--key": file_key,
            "--extra-py-files": transform_file_path,
        }
        runId = glue.start_job_run(JobName=gluejobname, Arguments=args)

        status = glue.get_job_run(JobName=gluejobname, RunId=runId["JobRunId"])
        logging.info("Job Status : ", status["JobRun"]["JobRunState"])

    except Exception as e:
        logging.info(e)
