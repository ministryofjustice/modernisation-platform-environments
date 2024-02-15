import base64
import json
import zlib

import boto3
from botocore.exceptions import ClientError
import xmltodict


DEST_LOG_GROUP = "cwagent-windows-application-json"


def xml_to_dict(xml_string):
    try:
        xml_dict = xmltodict.parse(xml_string)
        return xml_dict
    except Exception as e:
        return f"Error: {e}"


def create_log_stream(log_group_name, log_stream_name):
    client = boto3.client("logs")

    try:
        response = client.describe_log_streams(
            logGroupName=log_group_name, logStreamNamePrefix=log_stream_name, limit=1
        )

        streams = response.get("logStreams", [])
        if not any(s["logStreamName"] == log_stream_name for s in streams):
            print("Creating new log stream.")
            client.create_log_stream(
                logGroupName=log_group_name, logStreamName=log_stream_name
            )

    except ClientError as e:
        print(f"An error occurred: {e}")


def lambda_handler(event, context):
    print("Processing log event.")

    logs_client = boto3.client("logs")

    compressed_payload = base64.b64decode(event["awslogs"]["data"])
    uncompressed_payload = zlib.decompress(compressed_payload, 16 + zlib.MAX_WBITS)

    log_data = json.loads(uncompressed_payload)

    print(log_data)

    dest_log_group = DEST_LOG_GROUP
    dest_log_stream = log_data["logStream"]

    create_log_stream(dest_log_group, dest_log_stream)

    for log_event in log_data["logEvents"]:
        new_log_message = {
            "_": {"sourceLogStream": log_data["logStream"]}
        } | xml_to_dict(log_event["message"])

        new_log_event = {
            "timestamp": log_event["timestamp"],
            "message": json.dumps(new_log_message),
        }

        print("Putting new log event.")
        print(new_log_event)

        logs_client.put_log_events(
            logGroupName=dest_log_group,
            logStreamName=dest_log_stream,
            logEvents=[new_log_event],
        )

    return {"statusCode": 200, "body": json.dumps("Log processing complete.")}
