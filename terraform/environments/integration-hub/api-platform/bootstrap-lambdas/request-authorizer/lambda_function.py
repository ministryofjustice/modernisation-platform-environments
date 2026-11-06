def lambda_handler(_event, _context):
    return {
        "isAuthorized": False,
        "context": {
            "reason": "Application code has not been deployed yet.",
        },
    }
