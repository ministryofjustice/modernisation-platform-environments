import json
import os

import boto3
import psycopg2


secretsmanager = boto3.client("secretsmanager")


def lambda_handler(event, context):
    action = event.get("action", "seed")

    if action not in {"seed", "mutate"}:
        return {
            "statusCode": 400,
            "message": f"Unsupported action: {action}",
        }

    secret_arn = os.environ["RDS_SECRET_ARN"]
    db_host = os.environ["DB_HOST"]
    db_port = int(os.environ["DB_PORT"])
    db_name = os.environ["DB_NAME"]

    response = secretsmanager.get_secret_value(
        SecretId=secret_arn
    )

    secret = json.loads(response["SecretString"])

    connection = psycopg2.connect(
        host=db_host,
        port=db_port,
        dbname=db_name,
        user=secret["username"],
        password=secret["password"],
        sslmode="require",
        connect_timeout=10,
    )

    try:
        if action == "seed":
            return seed_database(connection)

        return mutate_database(connection)

    finally:
        connection.close()


def seed_database(connection):
    with connection:
        with connection.cursor() as cursor:
            cursor.execute(
                """
                CREATE TABLE IF NOT EXISTS public.dms_integration_test (
                    id BIGINT PRIMARY KEY,
                    description TEXT NOT NULL,
                    created_at TIMESTAMPTZ NOT NULL
                )
                """
            )

            cursor.execute(
                """
                INSERT INTO public.dms_integration_test (
                    id,
                    description,
                    created_at
                )
                VALUES
                    (1, 'First DMS integration test row', TIMESTAMPTZ '2026-09-10 09:00:00+00'),
                    (2, 'Second DMS integration test row', TIMESTAMPTZ '2026-09-10 09:01:00+00'),
                    (3, 'Third DMS integration test row', TIMESTAMPTZ '2026-09-10 09:02:00+00')
                ON CONFLICT (id)
                DO UPDATE SET
                    description = EXCLUDED.description,
                    created_at = EXCLUDED.created_at
                """
            )

            cursor.execute(
                """
                DELETE FROM public.dms_integration_test
                WHERE id > 3
                """
            )

            cursor.execute(
                """
                SELECT COUNT(*)
                FROM public.dms_integration_test
                """
            )

            row_count = cursor.fetchone()[0]

    return {
        "statusCode": 200,
        "action": "seed",
        "message": "DMS integration test database seeded successfully.",
        "rowCount": row_count,
    }


def mutate_database(connection):
    with connection:
        with connection.cursor() as cursor:
            cursor.execute(
                """
                INSERT INTO public.dms_integration_test (
                    id,
                    description,
                    created_at
                )
                VALUES (
                    4,
                    'Fourth DMS integration test row - CDC insert',
                    TIMESTAMPTZ '2026-09-10 10:00:00+00'
                )
                ON CONFLICT (id)
                DO UPDATE SET
                    description = EXCLUDED.description,
                    created_at = EXCLUDED.created_at
                """
            )

            cursor.execute(
                """
                UPDATE public.dms_integration_test
                SET description = 'Second DMS integration test row - CDC updated'
                WHERE id = 2
                """
            )

            cursor.execute(
                """
                DELETE FROM public.dms_integration_test
                WHERE id = 3
                """
            )

            cursor.execute(
                """
                SELECT id, description
                FROM public.dms_integration_test
                ORDER BY id
                """
            )

            rows = [
                {
                    "id": row[0],
                    "description": row[1],
                }
                for row in cursor.fetchall()
            ]

    return {
        "statusCode": 200,
        "action": "mutate",
        "message": "DMS CDC test mutations applied successfully.",
        "rows": rows,
    }
