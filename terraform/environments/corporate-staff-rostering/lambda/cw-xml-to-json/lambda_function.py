import base64
import json
import zlib

import boto3
import xmltodict


DEST_LOG_GROUP = "cwagent-windows-application-json"


def xml_to_dict(xml_string):
    try:
        xml_dict = xmltodict.parse(xml_string)
        return xml_dict
    except Exception as e:
        return f"Error: {e}"


def lambda_handler(event, context):
    logs_client = boto3.client("logs")

    print("==>", "event")
    print(event)
    print("==>", "context")
    print(context)
    print("==>", 'event["awslogs"]["data"]')
    print(event["awslogs"]["data"])

    compressed_payload = base64.b64decode(event["awslogs"]["data"])
    print("==>", "compressed_payload")
    print(compressed_payload)

    uncompressed_payload = zlib.decompress(compressed_payload, 16 + zlib.MAX_WBITS)
    print("==>", "uncompressed_payload")
    print(uncompressed_payload)

    log_data = json.loads(uncompressed_payload)
    print("==>", "log_data")
    print(log_data)

    dest_log_group = DEST_LOG_GROUP
    dest_log_stream = log_data["logStream"]

    for log_event in log_data["logEvents"]:
        new_log_message = xml_to_dict(log_event)

        logs_client.put_log_events(
            logGroupName=dest_log_group,
            logStreamName=dest_log_stream,
            logEvents=[
                {
                    "timestamp": log_event["timestamp"],
                    "message": json.dumps(new_log_message),
                }
            ],
        )

    return {"statusCode": 200, "body": json.dumps("Log processing complete")}
