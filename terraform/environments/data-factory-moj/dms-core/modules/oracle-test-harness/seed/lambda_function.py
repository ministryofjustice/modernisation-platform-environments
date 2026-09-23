import json
import os
import re
import secrets
import string

import boto3
import oracledb
from botocore.exceptions import ClientError


secretsmanager = boto3.client("secretsmanager")

VALID_USERNAME = re.compile(r"^[A-Z][A-Z0-9_]{0,29}$")

SUPPORTED_ACTIONS = {
    "reset",
    "seed",
    "mutate",
    "read",
}

TABLE_NAME = "DMS_INTEGRATION_TEST"

INITIAL_ROWS = [
    {
        "id": 1,
        "description": "First DMS integration test row",
        "createdAt": "2026-09-10T09:00:00+00:00",
    },
    {
        "id": 2,
        "description": "Second DMS integration test row",
        "createdAt": "2026-09-10T09:01:00+00:00",
    },
    {
        "id": 3,
        "description": "Third DMS integration test row",
        "createdAt": "2026-09-10T09:02:00+00:00",
    },
]

SYS_SELECT_OBJECTS = [
    "ALL_VIEWS",
    "ALL_TAB_PARTITIONS",
    "ALL_INDEXES",
    "ALL_OBJECTS",
    "ALL_TABLES",
    "ALL_USERS",
    "ALL_CATALOG",
    "ALL_CONSTRAINTS",
    "ALL_CONS_COLUMNS",
    "ALL_TAB_COLS",
    "ALL_IND_COLUMNS",
    "ALL_LOG_GROUPS",
    "V_$ARCHIVED_LOG",
    "V_$LOG",
    "V_$LOGFILE",
    "V_$DATABASE",
    "V_$THREAD",
    "V_$PARAMETER",
    "V_$NLS_PARAMETERS",
    "V_$TIMEZONE_NAMES",
    "V_$TRANSACTION",
    "V_$CONTAINERS",
    "DBA_REGISTRY",
    "OBJ$",
    "ALL_ENCRYPTED_COLUMNS",
    "V_$LOGMNR_LOGS",
    "V_$LOGMNR_CONTENTS",
    "REGISTRY$SQLPATCH",
]

SYS_EXECUTE_OBJECTS = [
    "DBMS_LOGMNR",
]


def lambda_handler(event, context):
    action = (event or {}).get("action", "seed")

    if action not in SUPPORTED_ACTIONS:
        return {
            "statusCode": 400,
            "action": action,
            "message": (
                f"Unsupported action: {action}. Supported actions are: "
                + ", ".join(sorted(SUPPORTED_ACTIONS))
                + "."
            ),
        }

    configuration = load_configuration()

    handlers = {
        "reset": reset_database,
        "seed": seed_database,
        "mutate": mutate_database,
        "read": read_database,
    }

    return handlers[action](configuration)


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
        "archive_retention_hours": int(
            os.environ["ARCHIVE_RETENTION_HOURS"]
        ),
    }


def seed_database(configuration):
    admin_secret = get_secret(configuration["rds_secret_arn"])
    dms_password = get_or_create_dms_password(configuration)

    with connect(
        configuration,
        admin_secret["username"],
        admin_secret["password"],
    ) as admin_connection:
        prepare_oracle_source(
            admin_connection,
            configuration["dms_username"],
            dms_password,
            configuration["archive_retention_hours"],
        )

    put_dms_secret(
        configuration,
        configuration["dms_username"],
        dms_password,
    )

    with connect(
        configuration,
        configuration["dms_username"],
        dms_password,
    ) as dms_connection:
        rows = seed_test_table(dms_connection)

    return build_response(
        action="seed",
        message=(
            "Oracle source prepared and DMS integration-test data "
            "seeded successfully."
        ),
        rows=rows,
        changes={
            "inserted": [row["id"] for row in INITIAL_ROWS],
        },
    )


def mutate_database(configuration):
    dms_secret = get_secret(configuration["dms_secret_arn"])

    with connect(
        configuration,
        dms_secret["username"],
        dms_secret["password"],
    ) as connection:
        rows = mutate_test_table(connection)

    return build_response(
        action="mutate",
        message="Oracle DMS CDC test mutations applied successfully.",
        rows=rows,
        changes={
            "inserted": [4],
            "updated": [2],
            "deleted": [3],
        },
    )


def reset_database(configuration):
    dms_secret = get_secret(configuration["dms_secret_arn"])

    with connect(
        configuration,
        dms_secret["username"],
        dms_secret["password"],
    ) as connection:
        deleted_row_count, rows = reset_test_table(connection)

    return build_response(
        action="reset",
        message=(
            "Oracle DMS integration-test table reset successfully."
        ),
        rows=rows,
        changes={
            "deletedDuringReset": deleted_row_count,
        },
    )


def read_database(configuration):
    dms_secret = get_secret(configuration["dms_secret_arn"])

    with connect(
        configuration,
        dms_secret["username"],
        dms_secret["password"],
    ) as connection:
        rows = read_test_table(connection)

    return build_response(
        action="read",
        message=(
            "Oracle DMS integration-test table read successfully."
        ),
        rows=rows,
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


def get_secret(secret_arn):
    response = secretsmanager.get_secret_value(
        SecretId=secret_arn
    )

    secret = json.loads(response["SecretString"])

    missing_fields = {"username", "password"}.difference(secret)
    if missing_fields:
        raise ValueError(
            "Secrets Manager secret is missing required credential fields: "
            + ", ".join(sorted(missing_fields))
        )

    return secret


def get_or_create_dms_password(configuration):
    try:
        current_secret = get_secret(configuration["dms_secret_arn"])

        if current_secret["username"].upper() == configuration["dms_username"]:
            return current_secret["password"]

    except ClientError as error:
        if error.response["Error"]["Code"] != "ResourceNotFoundException":
            raise

    return generate_password()


def generate_password(length=30):
    alphabet = string.ascii_letters + string.digits

    password_characters = [
        secrets.choice(string.ascii_uppercase),
        secrets.choice(string.ascii_lowercase),
        secrets.choice(string.digits),
    ]

    password_characters.extend(
        secrets.choice(alphabet)
        for _ in range(length - len(password_characters))
    )

    secrets.SystemRandom().shuffle(password_characters)

    return "".join(password_characters)


def put_dms_secret(configuration, username, password):
    required_secret = {
        "username": username,
        "password": password,
        "host": configuration["host"],
        "port": configuration["port"],
    }

    try:
        current_secret = get_secret(configuration["dms_secret_arn"])
    except ClientError as error:
        if error.response["Error"]["Code"] != "ResourceNotFoundException":
            raise
        current_secret = None

    if current_secret == required_secret:
        return False

    secretsmanager.put_secret_value(
        SecretId=configuration["dms_secret_arn"],
        SecretString=json.dumps(required_secret),
    )

    return True


def prepare_oracle_source(
    connection,
    dms_username,
    dms_password,
    archive_retention_hours,
):
    with connection.cursor() as cursor:
        configure_archive_log_retention(
            cursor,
            archive_retention_hours,
        )
        configure_supplemental_logging(cursor)
        create_or_update_dms_user(
            cursor,
            dms_username,
            dms_password,
        )
        grant_dms_privileges(cursor, dms_username)

    connection.commit()


def configure_archive_log_retention(cursor, retention_hours):
    cursor.execute(
        """
        BEGIN
            rdsadmin.rdsadmin_util.set_configuration(
                'archivelog retention hours',
                :retention_hours
            );
        END;
        """,
        retention_hours=retention_hours,
    )


def configure_supplemental_logging(cursor):
    cursor.execute(
        """
        SELECT
            supplemental_log_data_min,
            supplemental_log_data_pk
        FROM v$database
        """
    )

    minimum_logging, primary_key_logging = cursor.fetchone()

    if minimum_logging != "YES":
        cursor.execute(
            """
            BEGIN
                rdsadmin.rdsadmin_util.alter_supplemental_logging(
                    'ADD'
                );
            END;
            """
        )

    if primary_key_logging != "YES":
        cursor.execute(
            """
            BEGIN
                rdsadmin.rdsadmin_util.alter_supplemental_logging(
                    'ADD',
                    'PRIMARY KEY'
                );
            END;
            """
        )


def create_or_update_dms_user(cursor, dms_username, dms_password):
    cursor.execute(
        """
        SELECT COUNT(*)
        FROM all_users
        WHERE username = :username
        """,
        username=dms_username,
    )

    user_exists = cursor.fetchone()[0] == 1

    if user_exists:
        cursor.execute(
            f'ALTER USER {dms_username} IDENTIFIED BY "{dms_password}" '
            "ACCOUNT UNLOCK"
        )
    else:
        cursor.execute(
            f'CREATE USER {dms_username} IDENTIFIED BY "{dms_password}" '
            "DEFAULT TABLESPACE USERS "
            "QUOTA UNLIMITED ON USERS"
        )


def grant_dms_privileges(cursor, dms_username):
    direct_grants = [
        "CREATE SESSION",
        "CREATE TABLE",
        "SELECT ANY TRANSACTION",
        "LOGMINING",
    ]

    for privilege in direct_grants:
        cursor.execute(
            f"GRANT {privilege} TO {dms_username}"
        )

    cursor.execute(
        f"GRANT SELECT ON DBA_TABLESPACES TO {dms_username}"
    )

    cursor.execute(
        f"GRANT EXECUTE ON rdsadmin.rdsadmin_util TO {dms_username}"
    )

    for object_name in SYS_SELECT_OBJECTS:
        cursor.callproc(
            "rdsadmin.rdsadmin_util.grant_sys_object",
            [object_name, dms_username, "SELECT"],
        )

    for object_name in SYS_EXECUTE_OBJECTS:
        cursor.callproc(
            "rdsadmin.rdsadmin_util.grant_sys_object",
            [object_name, dms_username, "EXECUTE"],
        )


def reset_test_table(connection):
    with connection.cursor() as cursor:
        ensure_test_table(cursor)

        cursor.execute(
            f"""
            DELETE FROM {TABLE_NAME}
            """
        )

        deleted_row_count = cursor.rowcount
        rows = fetch_rows(cursor)

    connection.commit()

    return deleted_row_count, rows


def seed_test_table(connection):
    with connection.cursor() as cursor:
        ensure_test_table(cursor)

        cursor.execute(
            f"""
            DELETE FROM {TABLE_NAME}
            """
        )

        cursor.executemany(
            f"""
            INSERT INTO {TABLE_NAME} (
                ID,
                DESCRIPTION,
                CREATED_AT
            )
            VALUES (
                :id,
                :description,
                TO_TIMESTAMP_TZ(
                    :created_at,
                    'YYYY-MM-DD"T"HH24:MI:SSTZH:TZM'
                )
            )
            """,
            [
                {
                    "id": row["id"],
                    "description": row["description"],
                    "created_at": row["createdAt"],
                }
                for row in INITIAL_ROWS
            ],
        )

        rows = fetch_rows(cursor)
        assert_rows_match(
            rows,
            INITIAL_ROWS,
            "Oracle seed",
        )

    connection.commit()

    return rows


def mutate_test_table(connection):
    with connection.cursor() as cursor:
        ensure_test_table(cursor)

        current_rows = fetch_rows(cursor)
        assert_rows_match(
            current_rows,
            INITIAL_ROWS,
            "Oracle mutation starting state",
        )

        cursor.execute(
            f"""
            INSERT INTO {TABLE_NAME} (
                ID,
                DESCRIPTION,
                CREATED_AT
            )
            VALUES (
                4,
                'Fourth DMS integration test row - CDC insert',
                TO_TIMESTAMP_TZ(
                    '2026-09-10T10:00:00+00:00',
                    'YYYY-MM-DD"T"HH24:MI:SSTZH:TZM'
                )
            )
            """
        )
        require_affected_row_count(
            cursor.rowcount,
            expected=1,
            operation="insert ID 4",
        )

        cursor.execute(
            f"""
            UPDATE {TABLE_NAME}
            SET DESCRIPTION =
                'Second DMS integration test row - CDC updated'
            WHERE ID = 2
            """
        )
        require_affected_row_count(
            cursor.rowcount,
            expected=1,
            operation="update ID 2",
        )

        cursor.execute(
            f"""
            DELETE FROM {TABLE_NAME}
            WHERE ID = 3
            """
        )
        require_affected_row_count(
            cursor.rowcount,
            expected=1,
            operation="delete ID 3",
        )

        rows = fetch_rows(cursor)

    connection.commit()

    return rows


def read_test_table(connection):
    with connection.cursor() as cursor:
        ensure_test_table(cursor)
        rows = fetch_rows(cursor)

    return rows


def ensure_test_table(cursor):
    cursor.execute(
        """
        SELECT COUNT(*)
        FROM user_tables
        WHERE table_name = :table_name
        """,
        table_name=TABLE_NAME,
    )

    if cursor.fetchone()[0] == 0:
        cursor.execute(
            f"""
            CREATE TABLE {TABLE_NAME} (
                ID NUMBER(19) PRIMARY KEY,
                DESCRIPTION VARCHAR2(200) NOT NULL,
                CREATED_AT TIMESTAMP WITH TIME ZONE NOT NULL
            )
            """
        )


def fetch_rows(cursor):
    cursor.execute(
        f"""
        SELECT
            ID,
            DESCRIPTION,
            CREATED_AT
        FROM {TABLE_NAME}
        ORDER BY ID
        """
    )

    return [
        {
            "id": row[0],
            "description": row[1],
            "createdAt": row[2].isoformat(),
        }
        for row in cursor.fetchall()
    ]


def assert_rows_match(actual_rows, expected_rows, operation):
    if actual_rows != expected_rows:
        raise RuntimeError(
            f"{operation} produced or received an unexpected table state. "
            f"Expected: {expected_rows}. Actual: {actual_rows}."
        )


def require_affected_row_count(
    actual,
    expected,
    operation,
):
    if actual != expected:
        raise RuntimeError(
            f"Oracle mutation operation '{operation}' affected "
            f"{actual} rows; expected {expected}."
        )


def build_response(
    action,
    message,
    rows,
    changes=None,
):
    response = {
        "statusCode": 200,
        "engine": "oracle",
        "action": action,
        "message": message,
        "rowCount": len(rows),
        "rows": rows,
    }

    if changes is not None:
        response["changes"] = changes

    return response
