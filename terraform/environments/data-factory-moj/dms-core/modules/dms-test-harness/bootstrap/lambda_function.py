import json
import os

import boto3

secretsmanager = boto3.client("secretsmanager")


def lambda_handler(event, context):
    rds_secret_arn = os.environ["RDS_SECRET_ARN"]
    dms_secret_arn = os.environ["DMS_SECRET_ARN"]
    db_host = os.environ["DB_HOST"]
    db_port = int(os.environ["DB_PORT"])

    response = secretsmanager.get_secret_value(
        SecretId=rds_secret_arn
    )

    rds_secret = json.loads(response["SecretString"])

    dms_secret = {
        "username": rds_secret["username"],
        "password": rds_secret["password"],
        "host": db_host,
        "port": db_port,
    }

    secretsmanager.put_secret_value(
        SecretId=dms_secret_arn,
        SecretString=json.dumps(dms_secret),
    )

    return {
        "statusCode": 200,
        "message": "DMS source secret synchronised successfully.",
    }