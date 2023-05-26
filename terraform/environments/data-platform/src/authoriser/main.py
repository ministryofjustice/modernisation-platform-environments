import os
import json
import logging


def handler(event, context):
    logging.info(f"event: {event}")

    authorisationToken = json.dumps(event["authorisationToken"])
    characters_to_remove = '"[]"'
    for character in characters_to_remove:
        authorisationToken = authorisationToken.replace(character, "")

    auth = "Allow" if authorisationToken == os.environ["authorisationToken"] else "Deny"

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
