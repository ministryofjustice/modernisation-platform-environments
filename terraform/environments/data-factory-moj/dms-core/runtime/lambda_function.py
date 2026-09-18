import json
import os
import time

import boto3

dms = boto3.client("dms")
lambda_client = boto3.client("lambda")

CREDENTIAL_SYNC_FUNCTION_ARN = os.environ["CREDENTIAL_SYNC_FUNCTION_ARN"]
REPLICATION_INSTANCE_ARN = os.environ["REPLICATION_INSTANCE_ARN"]
SOURCE_ENDPOINT_ARN = os.environ["SOURCE_ENDPOINT_ARN"]
REPLICATION_TASK_ARN = os.environ["REPLICATION_TASK_ARN"]

POLL_INTERVAL_SECONDS = 10
MAX_POLL_ATTEMPTS = 30

START_TYPES = {
    "start": "start-replication",
    "resume": "resume-processing",
}


def synchronise_credentials():
    response = lambda_client.invoke(
        FunctionName=CREDENTIAL_SYNC_FUNCTION_ARN,
        InvocationType="RequestResponse",
        Payload=json.dumps({"trigger": "preflight"}).encode("utf-8"),
    )

    payload = json.loads(response["Payload"].read() or b"{}")

    if response.get("FunctionError"):
        raise RuntimeError("DMS source credential synchronisation failed.")

    if payload.get("statusCode") != 200:
        raise RuntimeError(
            "DMS source credential synchronisation returned an unsuccessful response."
        )


def get_connection():
    response = dms.describe_connections(
        Filters=[
            {
                "Name": "endpoint-arn",
                "Values": [SOURCE_ENDPOINT_ARN],
            },
            {
                "Name": "replication-instance-arn",
                "Values": [REPLICATION_INSTANCE_ARN],
            },
        ]
    )

    connections = response.get("Connections", [])
    if not connections:
        raise RuntimeError(
            "AWS DMS did not return a connection test for the source endpoint."
        )

    return connections[0]


def test_source_connection():
    dms.test_connection(
        ReplicationInstanceArn=REPLICATION_INSTANCE_ARN,
        EndpointArn=SOURCE_ENDPOINT_ARN,
    )

    for _ in range(MAX_POLL_ATTEMPTS):
        connection = get_connection()
        status = connection.get("Status")

        if status == "successful":
            return

        if status == "failed":
            failure_message = connection.get(
                "LastFailureMessage",
                "AWS DMS did not provide a failure message.",
            )
            raise RuntimeError(
                f"DMS source endpoint connection test failed: {failure_message}"
            )

        if status != "testing":
            raise RuntimeError(
                f"DMS source endpoint returned unexpected connection status: {status}"
            )

        time.sleep(POLL_INTERVAL_SECONDS)

    raise TimeoutError(
        "Timed out waiting for the DMS source endpoint connection test."
    )


def lambda_handler(event, context):
    action = event.get("action")

    if action not in START_TYPES:
        raise ValueError("action must be either 'start' or 'resume'.")

    synchronise_credentials()
    test_source_connection()

    response = dms.start_replication_task(
        ReplicationTaskArn=REPLICATION_TASK_ARN,
        StartReplicationTaskType=START_TYPES[action],
    )

    task = response["ReplicationTask"]

    return {
        "statusCode": 200,
        "action": action,
        "replicationTaskArn": task["ReplicationTaskArn"],
        "replicationTaskStatus": task["Status"],
        "message": (
            "DMS source credentials synchronised, endpoint preflight passed "
            f"and replication task {action} was requested."
        ),
    }