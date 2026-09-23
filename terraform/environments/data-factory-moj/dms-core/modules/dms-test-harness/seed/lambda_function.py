import json
import os

import boto3
import psycopg2


secretsmanager = boto3.client("secretsmanager")

SUPPORTED_ACTIONS = {
    "reset",
    "seed",
    "mutate",
    "read",
}

TABLE_NAME = "public.dms_integration_test"

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
    secret = get_secret(configuration["rds_secret_arn"])

    with connect(configuration, secret) as connection:
        handlers = {
            "reset": reset_database,
            "seed": seed_database,
            "mutate": mutate_database,
            "read": read_database,
        }

        return handlers[action](connection)


def load_configuration():
    return {
        "rds_secret_arn": os.environ["RDS_SECRET_ARN"],
        "host": os.environ["DB_HOST"],
        "port": int(os.environ["DB_PORT"]),
        "database_name": os.environ["DB_NAME"],
    }


def get_secret(secret_arn):
    response = secretsmanager.get_secret_value(
        SecretId=secret_arn,
    )

    secret = json.loads(response["SecretString"])

    missing_fields = {"username", "password"}.difference(secret)

    if missing_fields:
        raise ValueError(
            "Secrets Manager secret is missing required credential fields: "
            + ", ".join(sorted(missing_fields))
        )

    return secret


def connect(configuration, secret):
    return psycopg2.connect(
        host=configuration["host"],
        port=configuration["port"],
        dbname=configuration["database_name"],
        user=secret["username"],
        password=secret["password"],
        sslmode="require",
        connect_timeout=10,
    )


def reset_database(connection):
    with connection:
        with connection.cursor() as cursor:
            ensure_test_table(cursor)

            cursor.execute(
                f"""
                DELETE FROM {TABLE_NAME}
                """
            )

            deleted_row_count = cursor.rowcount
            rows = fetch_rows(cursor)

    return build_response(
        action="reset",
        message=(
            "PostgreSQL DMS integration-test table reset successfully."
        ),
        rows=rows,
        changes={
            "deletedDuringReset": deleted_row_count,
        },
    )


def seed_database(connection):
    with connection:
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
                    id,
                    description,
                    created_at
                )
                VALUES (
                    %s,
                    %s,
                    %s::timestamptz
                )
                """,
                [
                    (
                        row["id"],
                        row["description"],
                        row["createdAt"],
                    )
                    for row in INITIAL_ROWS
                ],
            )

            rows = fetch_rows(cursor)
            assert_rows_match(
                rows,
                INITIAL_ROWS,
                "PostgreSQL seed",
            )

    return build_response(
        action="seed",
        message=(
            "PostgreSQL DMS integration-test data seeded successfully."
        ),
        rows=rows,
        changes={
            "inserted": [row["id"] for row in INITIAL_ROWS],
        },
    )


def mutate_database(connection):
    with connection:
        with connection.cursor() as cursor:
            ensure_test_table(cursor)

            current_rows = fetch_rows(cursor)
            assert_rows_match(
                current_rows,
                INITIAL_ROWS,
                "PostgreSQL mutation starting state",
            )

            cursor.execute(
                f"""
                INSERT INTO {TABLE_NAME} (
                    id,
                    description,
                    created_at
                )
                VALUES (
                    4,
                    'Fourth DMS integration test row - CDC insert',
                    TIMESTAMPTZ '2026-09-10 10:00:00+00'
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
                SET description =
                    'Second DMS integration test row - CDC updated'
                WHERE id = 2
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
                WHERE id = 3
                """
            )
            require_affected_row_count(
                cursor.rowcount,
                expected=1,
                operation="delete ID 3",
            )

            rows = fetch_rows(cursor)

    return build_response(
        action="mutate",
        message=(
            "PostgreSQL DMS CDC test mutations applied successfully."
        ),
        rows=rows,
        changes={
            "inserted": [4],
            "updated": [2],
            "deleted": [3],
        },
    )


def read_database(connection):
    with connection.cursor() as cursor:
        ensure_test_table(cursor)
        rows = fetch_rows(cursor)

    return build_response(
        action="read",
        message=(
            "PostgreSQL DMS integration-test table read successfully."
        ),
        rows=rows,
    )


def ensure_test_table(cursor):
    cursor.execute(
        f"""
        CREATE TABLE IF NOT EXISTS {TABLE_NAME} (
            id BIGINT PRIMARY KEY,
            description TEXT NOT NULL,
            created_at TIMESTAMPTZ NOT NULL
        )
        """
    )


def fetch_rows(cursor):
    cursor.execute(
        f"""
        SELECT
            id,
            description,
            created_at
        FROM {TABLE_NAME}
        ORDER BY id
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
            f"PostgreSQL mutation operation '{operation}' affected "
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
        "engine": "postgresql",
        "action": action,
        "message": message,
        "rowCount": len(rows),
        "rows": rows,
    }

    if changes is not None:
        response["changes"] = changes

    return response
