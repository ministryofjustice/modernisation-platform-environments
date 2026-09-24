import json
import os
import time

import boto3


dms = boto3.client("dms")
lambda_client = boto3.client("lambda")

CREDENTIAL_SYNC_FUNCTION_ARN = os.environ.get(
    "CREDENTIAL_SYNC_FUNCTION_ARN"
)
REPLICATION_INSTANCE_ARN = os.environ["REPLICATION_INSTANCE_ARN"]
SOURCE_ENDPOINT_ARN = os.environ["SOURCE_ENDPOINT_ARN"]
REPLICATION_TASK_ARN = os.environ.get("REPLICATION_TASK_ARN")

POLL_INTERVAL_SECONDS = 10
MAX_POLL_ATTEMPTS = 30

START_TYPES = {
    "start": "start-replication",
    "resume": "resume-processing",
}

SUPPORTED_ACTIONS = {
    "preflight",
    *START_TYPES,
}


def synchronise_credentials():
    if CREDENTIAL_SYNC_FUNCTION_ARN is None:
        return False

    response = lambda_client.invoke(
        FunctionName=CREDENTIAL_SYNC_FUNCTION_ARN,
        InvocationType="RequestResponse",
        Payload=json.dumps({"trigger": "preflight"}).encode("utf-8"),
    )

    payload = json.loads(response["Payload"].read() or b"{}")

    if response.get("FunctionError"):
        raise RuntimeError(
            "DMS source credential synchronisation failed."
        )

    if payload.get("statusCode") != 200:
        raise RuntimeError(
            "DMS source credential synchronisation returned an "
            "unsuccessful response."
        )

    return True


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
            "AWS DMS did not return a connection test for the source "
            "endpoint."
        )

    return connections[0]


def test_source_connection():
    dms.test_connection(
        ReplicationInstanceArn=REPLICATION_INSTANCE_ARN,
        EndpointArn=SOURCE_ENDPOINT_ARN,
    )

    for attempt in range(1, MAX_POLL_ATTEMPTS + 1):
        connection = get_connection()
        status = connection.get("Status")

        if status == "successful":
            return {
                "status": status,
                "pollAttempts": attempt,
            }

        if status == "failed":
            failure_message = connection.get(
                "LastFailureMessage",
                "AWS DMS did not provide a failure message.",
            )

            raise RuntimeError(
                "DMS source endpoint connection test failed: "
                f"{failure_message}"
            )

        if status != "testing":
            raise RuntimeError(
                "DMS source endpoint returned unexpected connection "
                f"status: {status}"
            )

        time.sleep(POLL_INTERVAL_SECONDS)

    raise TimeoutError(
        "Timed out waiting for the DMS source endpoint connection test."
    )


def start_replication_task(action):
    if REPLICATION_TASK_ARN is None:
        raise RuntimeError(
            "REPLICATION_TASK_ARN must be configured for start or resume."
        )

    response = dms.start_replication_task(
        ReplicationTaskArn=REPLICATION_TASK_ARN,
        StartReplicationTaskType=START_TYPES[action],
    )

    return response["ReplicationTask"]


def lambda_handler(event, context):
    action = event.get("action")

    if action not in SUPPORTED_ACTIONS:
        raise ValueError(
            "action must be 'preflight', 'start' or 'resume'."
        )

    credentials_synchronised = synchronise_credentials()
    connection = test_source_connection()

    if action == "preflight":
        return {
            "statusCode": 200,
            "action": action,
            "credentialsSynchronised": credentials_synchronised,
            "sourceEndpointArn": SOURCE_ENDPOINT_ARN,
            "replicationInstanceArn": REPLICATION_INSTANCE_ARN,
            "connectionStatus": connection["status"],
            "pollAttempts": connection["pollAttempts"],
            "message": (
                "DMS source credential lifecycle completed and endpoint "
                "preflight passed."
            ),
        }

    task = start_replication_task(action)

    return {
        "statusCode": 200,
        "action": action,
        "credentialsSynchronised": credentials_synchronised,
        "sourceEndpointArn": SOURCE_ENDPOINT_ARN,
        "replicationInstanceArn": REPLICATION_INSTANCE_ARN,
        "replicationTaskArn": task["ReplicationTaskArn"],
        "replicationTaskStatus": task["Status"],
        "connectionStatus": connection["status"],
        "pollAttempts": connection["pollAttempts"],
        "message": (
            "DMS source credential lifecycle completed, endpoint "
            f"preflight passed and replication task {action} was requested."
        ),
    }
