import json


def lambda_handler(event, context):
    request_id = event.get("requestContext", {}).get("requestId") or context.aws_request_id
    return {
        "statusCode": 503,
        "headers": {"content-type": "application/json", "x-correlation-id": request_id},
        "body": json.dumps({
            "requestId": request_id,
            "error": {
                "code": "application_not_deployed",
                "message": "Deploy the benefit checker API application code",
            },
        }),
    }
