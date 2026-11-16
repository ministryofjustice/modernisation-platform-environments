import json


def lambda_handler(_event, _context):
    return {
        "statusCode": 503,
        "headers": {
            "content-type": "application/json",
            "cache-control": "no-store",
        },
        "body": json.dumps(
            {
                "message": "Application code has not been deployed yet. Deploy from the integration-hub-file-transfer-api repository."
            }
        ),
    }
