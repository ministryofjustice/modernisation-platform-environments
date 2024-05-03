import awswrangler as wr
import os

RDS_ARN = os.environ.get("RDS_ARN")
SECRET_ARN = os.environ.get("SECRET_ARN")


def get_rds_connection(rds_arn=RDS_ARN, secret_arn=SECRET_ARN):
    rds_connection = wr.SECRET_AR.data_api.rds.connect(
        secret_arn=secret_arn, rds_arn=rds_arn, database="test"
    )
    return rds_connection


def handler(event, context):
    conn = get_rds_connection()
    return "done"
