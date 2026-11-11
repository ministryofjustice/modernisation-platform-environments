def lambda_handler(_event, _context):
    return {
        "statusCode": 503,
        "headers": {
            "content-type": "text/plain; charset=utf-8",
            "cache-control": "no-store",
        },
        "body": "Application code has not been deployed yet. Deploy from the integration-hub-file-transfer-api repository.",
    }
