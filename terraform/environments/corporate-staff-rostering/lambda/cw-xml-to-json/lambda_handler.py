import base64
import json
import zlib

import boto3
import xmltodict


def xml_to_dict(xml_string):
    try:
        xml_dict = xmltodict.parse(xml_string)
        return xml_dict
    except Exception as e:
        return f"Error: {e}"


def handler(event, context):
    logs_client = boto3.client("logs")

    for record in event["awslogs"]["data"]:
        compressed_payload = base64.b64decode(record)
        uncompressed_payload = zlib.decompress(compressed_payload, 16 + zlib.MAX_WBITS)
        log_data = json.loads(uncompressed_payload)

        dest_log_group = log_data["logGroup"] + "-json"
        dest_log_stream = log_data["logStream"]

        for log_event in log_data["logEvents"]:
            new_log_message = xml_to_dict(log_event)

            logs_client.put_log_events(
                logGroupName=dest_log_group,
                logStreamName=dest_log_stream,
                logEvents=[
                    {
                        "originalLogGroup": log_data["logGroup"],
                        "originalLogStream": log_data["logStream"],
                        "timestamp": log_event["timestamp"],
                        "message": json.dumps(new_log_message),
                    }
                ],
            )

    return {"statusCode": 200, "body": json.dumps("Log processing complete")}
