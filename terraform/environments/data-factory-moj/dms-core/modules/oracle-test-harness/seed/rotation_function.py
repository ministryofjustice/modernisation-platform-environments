import json
import os
import re

import boto3
import oracledb
from botocore.exceptions import ClientError


secretsmanager = boto3.client("secretsmanager")

VALID_USERNAME = re.compile(r"^[A-Z][A-Z0-9_]{0,29}$")
VALID_PASSWORD = re.compile(r"^[A-Za-z0-9]+$")

REQUIRED_SECRET_FIELDS = {
    "username",
    "password",
    "host",
    "port",
}

ROTATION_STEPS = {
    "createSecret",
    "setSecret",
    "testSecret",
    "finishSecret",
}


def lambda_handler(event, context):
    secret_id = event["SecretId"]
    client_request_token = event["ClientRequestToken"]
    step = event["Step"]

    configuration = load_configuration()

    if secret_id != configuration["dms_secret_arn"]:
        raise ValueError(
            "The requested secret is not the configured Oracle DMS secret."
        )

    if step not in ROTATION_STEPS:
        raise ValueError(f"Unsupported rotation step: {step}")

    metadata = secretsmanager.describe_secret(SecretId=secret_id)

    if not metadata.get("RotationEnabled"):
        raise ValueError("Rotation is not enabled for the Oracle DMS secret.")

    version_stages = metadata.get("VersionIdsToStages", {})

    if client_request_token not in version_stages:
        raise ValueError(
            "The rotation token does not identify a secret version."
        )

    token_stages = version_stages[client_request_token]

    if "AWSCURRENT" in token_stages:
        return {
            "statusCode": 200,
            "step": step,
            "message": "The requested secret version is already current.",
        }

    if "AWSPENDING" not in token_stages:
        raise ValueError(
            "The rotation token is not staged as AWSPENDING."
        )

    handlers = {
        "createSecret": create_secret,
        "setSecret": set_secret,
        "testSecret": test_secret,
        "finishSecret": finish_secret,
    }

    handlers[step](
        configuration,
        secret_id,
        client_request_token,
    )

    return {
        "statusCode": 200,
        "step": step,
        "message": f"Oracle DMS secret rotation step {step} completed.",
    }


def load_configuration():
    dms_username = os.environ["DMS_USERNAME"].upper()

    if not VALID_USERNAME.fullmatch(dms_username):
        raise ValueError(
            "DMS_USERNAME must be a valid unquoted Oracle identifier "
            "containing no more than 30 characters."
        )

    return {
        "rds_secret_arn": os.environ["RDS_SECRET_ARN"],
        "dms_secret_arn": os.environ["DMS_SECRET_ARN"],
        "host": os.environ["DB_HOST"],
        "port": int(os.environ["DB_PORT"]),
        "database_name": os.environ["DB_NAME"],
        "dms_username": dms_username,
    }


def create_secret(configuration, secret_id, client_request_token):
    current_secret = get_secret(
        secret_id,
        version_stage="AWSCURRENT",
    )
    validate_target(configuration, current_secret)

    try:
        get_secret(
            secret_id,
            version_stage="AWSPENDING",
            version_id=client_request_token,
        )
        return
    except ClientError as error:
        if error.response["Error"]["Code"] != "ResourceNotFoundException":
            raise

    password_response = secretsmanager.get_random_password(
        PasswordLength=30,
        ExcludePunctuation=True,
        RequireEachIncludedType=True,
    )

    pending_secret = dict(current_secret)
    pending_secret["password"] = password_response["RandomPassword"]

    secretsmanager.put_secret_value(
        SecretId=secret_id,
        ClientRequestToken=client_request_token,
        SecretString=json.dumps(pending_secret),
        VersionStages=["AWSPENDING"],
    )


def set_secret(configuration, secret_id, client_request_token):
    current_secret = get_secret(
        secret_id,
        version_stage="AWSCURRENT",
    )
    pending_secret = get_secret(
        secret_id,
        version_stage="AWSPENDING",
        version_id=client_request_token,
    )

    validate_target(configuration, current_secret)
    validate_target(configuration, pending_secret)
    validate_matching_targets(current_secret, pending_secret)

    if can_connect(configuration, pending_secret):
        return

    with connect(
        configuration,
        current_secret["username"],
        current_secret["password"],
    ):
        pass

    pending_password = pending_secret["password"]

    if not VALID_PASSWORD.fullmatch(pending_password):
        raise ValueError(
            "The generated Oracle password contains unsupported characters."
        )

    admin_secret = get_secret(
        configuration["rds_secret_arn"],
        version_stage="AWSCURRENT",
        required_fields={"username", "password"},
    )

    with connect(
        configuration,
        admin_secret["username"],
        admin_secret["password"],
    ) as admin_connection:
        with admin_connection.cursor() as cursor:
            cursor.execute(
                f'ALTER USER {configuration["dms_username"]} '
                f'IDENTIFIED BY "{pending_password}" ACCOUNT UNLOCK'
            )

        admin_connection.commit()


def test_secret(configuration, secret_id, client_request_token):
    pending_secret = get_secret(
        secret_id,
        version_stage="AWSPENDING",
        version_id=client_request_token,
    )
    validate_target(configuration, pending_secret)

    with connect(
        configuration,
        pending_secret["username"],
        pending_secret["password"],
    ) as connection:
        with connection.cursor() as cursor:
            cursor.execute("SELECT 1 FROM dual")

            if cursor.fetchone()[0] != 1:
                raise RuntimeError(
                    "Oracle returned an unexpected rotation test result."
                )


def finish_secret(configuration, secret_id, client_request_token):
    metadata = secretsmanager.describe_secret(SecretId=secret_id)

    current_version_id = None

    for version_id, stages in metadata.get(
        "VersionIdsToStages",
        {},
    ).items():
        if "AWSCURRENT" in stages:
            if version_id == client_request_token:
                return

            current_version_id = version_id
            break

    if current_version_id is None:
        raise RuntimeError(
            "The Oracle DMS secret has no AWSCURRENT version."
        )

    secretsmanager.update_secret_version_stage(
        SecretId=secret_id,
        VersionStage="AWSCURRENT",
        MoveToVersionId=client_request_token,
        RemoveFromVersionId=current_version_id,
    )


def get_secret(
    secret_id,
    version_stage,
    version_id=None,
    required_fields=None,
):
    request = {
        "SecretId": secret_id,
        "VersionStage": version_stage,
    }

    if version_id is not None:
        request["VersionId"] = version_id

    response = secretsmanager.get_secret_value(**request)
    secret = json.loads(response["SecretString"])

    expected_fields = (
        REQUIRED_SECRET_FIELDS
        if required_fields is None
        else required_fields
    )
    missing_fields = expected_fields.difference(secret)

    if missing_fields:
        raise ValueError(
            "Secrets Manager secret is missing required fields: "
            + ", ".join(sorted(missing_fields))
        )

    return secret


def validate_target(configuration, secret):
    if secret["username"].upper() != configuration["dms_username"]:
        raise ValueError(
            "The secret username does not match the configured DMS user."
        )

    if secret["host"] != configuration["host"]:
        raise ValueError(
            "The secret host does not match the configured Oracle source."
        )

    if int(secret["port"]) != configuration["port"]:
        raise ValueError(
            "The secret port does not match the configured Oracle source."
        )


def validate_matching_targets(current_secret, pending_secret):
    for field in ("username", "host", "port"):
        if str(current_secret[field]).upper() != str(
            pending_secret[field]
        ).upper():
            raise ValueError(
                f"AWSCURRENT and AWSPENDING do not match for {field}."
            )


def connect(configuration, username, password):
    dsn = oracledb.makedsn(
        configuration["host"],
        configuration["port"],
        service_name=configuration["database_name"],
    )

    return oracledb.connect(
        user=username,
        password=password,
        dsn=dsn,
        tcp_connect_timeout=10,
    )


def can_connect(configuration, secret):
    try:
        with connect(
            configuration,
            secret["username"],
            secret["password"],
        ):
            return True
    except oracledb.Error:
        return False