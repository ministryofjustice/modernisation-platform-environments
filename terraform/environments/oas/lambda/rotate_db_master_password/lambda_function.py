import json
import logging
import os

import boto3

logger = logging.getLogger()
logger.setLevel(logging.INFO)

secretsmanager = boto3.client("secretsmanager")
rds = boto3.client("rds")


def lambda_handler(event, context):
    """Manually-invoked rotation for the OAS RDS master password.

    Generates a new password, sets it directly on the RDS instance via
    ModifyDBInstance (no need to know/use the current password), then
    stores the new value in Secrets Manager so they stay in sync.
    """
    db_instance_identifier = os.environ["DB_INSTANCE_IDENTIFIER"]
    secret_id = os.environ["SECRET_ID"]

    current_secret = json.loads(
        secretsmanager.get_secret_value(SecretId=secret_id)["SecretString"]
    )
    username = current_secret["username"]

    new_password = secretsmanager.get_random_password(
        PasswordLength=30,
        ExcludeCharacters="\"@/\\'",
    )["RandomPassword"]

    logger.info("Setting new master password on RDS instance %s", db_instance_identifier)
    rds.modify_db_instance(
        DBInstanceIdentifier=db_instance_identifier,
        MasterUserPassword=new_password,
        ApplyImmediately=True,
    )

    secretsmanager.put_secret_value(
        SecretId=secret_id,
        SecretString=json.dumps({"username": username, "password": new_password}),
    )

    logger.info("Rotation complete, new password stored in secret %s", secret_id)

    return {
        "statusCode": 200,
        "body": f"Master password rotated for {db_instance_identifier}",
    }
