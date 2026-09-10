import json
import os

import boto3
import psycopg2


secretsmanager = boto3.client("secretsmanager")


def lambda_handler(event, context):
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
                    SELECT COUNT(*)
                    FROM public.dms_integration_test
                    """
                )

                row_count = cursor.fetchone()[0]

        return {
            "statusCode": 200,
            "message": "DMS integration test database seeded successfully.",
            "rowCount": row_count,
        }

    finally:
        connection.close()
        