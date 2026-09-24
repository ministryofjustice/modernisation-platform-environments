import json
import os

import boto3

secretsmanager = boto3.client("secretsmanager")

REQUIRED_RDS_FIELDS = {"username", "password"}


def lambda_handler(event, context):
    rds_secret_arn = os.environ["RDS_SECRET_ARN"]
    dms_secret_arn = os.environ["DMS_SECRET_ARN"]
    db_host = os.environ["DB_HOST"]
    db_port = int(os.environ["DB_PORT"])

    rds_response = secretsmanager.get_secret_value(
        SecretId=rds_secret_arn
    )
    rds_secret = json.loads(rds_response["SecretString"])

    missing_fields = REQUIRED_RDS_FIELDS.difference(rds_secret)
    if missing_fields:
        raise ValueError(
            "RDS-managed secret is missing required credential fields: "
            + ", ".join(sorted(missing_fields))
        )

    required_dms_secret = {
        "username": rds_secret["username"],
        "password": rds_secret["password"],
        "host": db_host,
        "port": db_port,
    }

    try:
        current_response = secretsmanager.get_secret_value(
            SecretId=dms_secret_arn
        )
        current_dms_secret = json.loads(current_response["SecretString"])
    except secretsmanager.exceptions.ResourceNotFoundException:
        current_dms_secret = None

    if current_dms_secret == required_dms_secret:
        return {
            "statusCode": 200,
            "changed": False,
            "message": "DMS source secret is already current.",
        }

    secretsmanager.put_secret_value(
        SecretId=dms_secret_arn,
        SecretString=json.dumps(required_dms_secret),
    )

    return {
        "statusCode": 200,
        "changed": True,
        "message": "DMS source secret synchronised successfully.",
    }
