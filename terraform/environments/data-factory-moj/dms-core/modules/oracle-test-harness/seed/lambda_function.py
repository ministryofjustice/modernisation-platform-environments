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
    action = event.get("action", "seed")

    if action not in {"seed", "mutate"}:
        return {
            "statusCode": 400,
            "message": f"Unsupported action: {action}",
        }

    configuration = load_configuration()

    if action == "seed":
        return seed_database(configuration)

    return mutate_database(configuration)


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
        row_count = seed_test_table(dms_connection)

    return {
        "statusCode": 200,
        "action": "seed",
        "message": (
            "Oracle source prepared and DMS integration-test data "
            "seeded successfully."
        ),
        "rowCount": row_count,
    }


def mutate_database(configuration):
    dms_secret = get_secret(configuration["dms_secret_arn"])

    with connect(
        configuration,
        dms_secret["username"],
        dms_secret["password"],
    ) as connection:
        rows = mutate_test_table(connection)

    return {
        "statusCode": 200,
        "action": "mutate",
        "message": "Oracle DMS CDC test mutations applied successfully.",
        "rows": rows,
    }


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


def seed_test_table(connection):
    with connection.cursor() as cursor:
        cursor.execute(
            """
            SELECT COUNT(*)
            FROM user_tables
            WHERE table_name = 'DMS_INTEGRATION_TEST'
            """
        )

        if cursor.fetchone()[0] == 0:
            cursor.execute(
                """
                CREATE TABLE DMS_INTEGRATION_TEST (
                    ID NUMBER(19) PRIMARY KEY,
                    DESCRIPTION VARCHAR2(200) NOT NULL,
                    CREATED_AT TIMESTAMP WITH TIME ZONE NOT NULL
                )
                """
            )

        seed_rows = [
            (
                1,
                "First Oracle DMS integration test row",
                "2026-09-22 09:00:00 +00:00",
            ),
            (
                2,
                "Second Oracle DMS integration test row",
                "2026-09-22 09:01:00 +00:00",
            ),
            (
                3,
                "Third Oracle DMS integration test row",
                "2026-09-22 09:02:00 +00:00",
            ),
        ]

        for row_id, description, created_at in seed_rows:
            cursor.execute(
                """
                MERGE INTO DMS_INTEGRATION_TEST target
                USING (
                    SELECT
                        :row_id AS ID,
                        :description AS DESCRIPTION,
                        TO_TIMESTAMP_TZ(
                            :created_at,
                            'YYYY-MM-DD HH24:MI:SS TZH:TZM'
                        ) AS CREATED_AT
                    FROM dual
                ) source
                ON (target.ID = source.ID)
                WHEN MATCHED THEN
                    UPDATE SET
                        target.DESCRIPTION = source.DESCRIPTION,
                        target.CREATED_AT = source.CREATED_AT
                WHEN NOT MATCHED THEN
                    INSERT (
                        ID,
                        DESCRIPTION,
                        CREATED_AT
                    )
                    VALUES (
                        source.ID,
                        source.DESCRIPTION,
                        source.CREATED_AT
                    )
                """,
                row_id=row_id,
                description=description,
                created_at=created_at,
            )

        cursor.execute(
            """
            DELETE FROM DMS_INTEGRATION_TEST
            WHERE ID > 3
            """
        )

        cursor.execute(
            """
            SELECT COUNT(*)
            FROM DMS_INTEGRATION_TEST
            """
        )

        row_count = cursor.fetchone()[0]

    connection.commit()

    return row_count


def mutate_test_table(connection):
    with connection.cursor() as cursor:
        cursor.execute(
            """
            MERGE INTO DMS_INTEGRATION_TEST target
            USING (
                SELECT
                    4 AS ID,
                    'Fourth Oracle DMS integration test row - CDC insert'
                        AS DESCRIPTION,
                    TO_TIMESTAMP_TZ(
                        '2026-09-22 10:00:00 +00:00',
                        'YYYY-MM-DD HH24:MI:SS TZH:TZM'
                    ) AS CREATED_AT
                FROM dual
            ) source
            ON (target.ID = source.ID)
            WHEN MATCHED THEN
                UPDATE SET
                    target.DESCRIPTION = source.DESCRIPTION,
                    target.CREATED_AT = source.CREATED_AT
            WHEN NOT MATCHED THEN
                INSERT (
                    ID,
                    DESCRIPTION,
                    CREATED_AT
                )
                VALUES (
                    source.ID,
                    source.DESCRIPTION,
                    source.CREATED_AT
                )
            """
        )

        cursor.execute(
            """
            UPDATE DMS_INTEGRATION_TEST
            SET DESCRIPTION =
                'Second Oracle DMS integration test row - CDC updated'
            WHERE ID = 2
            """
        )

        cursor.execute(
            """
            DELETE FROM DMS_INTEGRATION_TEST
            WHERE ID = 3
            """
        )

        cursor.execute(
            """
            SELECT ID, DESCRIPTION
            FROM DMS_INTEGRATION_TEST
            ORDER BY ID
            """
        )

        rows = [
            {
                "id": row[0],
                "description": row[1],
            }
            for row in cursor.fetchall()
        ]

    connection.commit()

    return rows
