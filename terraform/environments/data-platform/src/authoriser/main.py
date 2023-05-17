import os
import json
import logging


def handler(event, context):
    logging.info(f"event: {event}")

    authorizationToken = json.dumps(event["multiValueHeaders"]["authorisationToken"])
    characters_to_remove = '"[]"'
    for character in characters_to_remove:
        authorizationToken = authorizationToken.replace(character, "")

    if authorizationToken == os.environ["authorisationToken"]:
        auth = "Allow"
    else:
        auth = "Deny"

    authResponse = {
        "principalId": "abc123",
        "policyDocument": {
            "Version": "2012-10-17",
            "Statement": [
                {
                    "Action": "execute-api:Invoke",
                    "Resource": [os.environ["api_resource_arn"]],
                    "Effect": auth,
                }
            ],
        },
    }

    return authResponse
