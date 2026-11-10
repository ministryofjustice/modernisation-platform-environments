import base64
import json
import logging
import os

from aws_msk_iam_sasl_signer import MSKAuthTokenProvider
from kafka import KafkaProducer

logger = logging.getLogger()
logger.setLevel(logging.INFO)

REGION = os.environ["AWS_REGION"]
TOPIC = os.environ["KAFKA_TOPIC"]
BOOTSTRAP_SERVERS = os.environ["BOOTSTRAP_SERVERS"].split(",")


class TokenProvider:
    def token(self):
        token, _ = MSKAuthTokenProvider.generate_auth_token(REGION)
        return token


# Created outside the handler so warm invocations reuse the connection
producer = KafkaProducer(
    bootstrap_servers=BOOTSTRAP_SERVERS,
    security_protocol="SASL_SSL",
    sasl_mechanism="OAUTHBEARER",
    sasl_oauth_token_provider=TokenProvider(),
    acks="all",
    retries=3,
)


def response(status_code, message):
    return {
        "statusCode": status_code,
        "headers": {"content-type": "application/json"},
        "body": json.dumps({"message": message}),
    }


def lambda_handler(event, context):
    # API Gateway HTTP API (payload format 2.0) request
    event_name = event["pathParameters"]["eventName"]
    body = event.get("body") or "{}"
    if event.get("isBase64Encoded"):
        body = base64.b64decode(body).decode("utf-8")

    try:
        payload = json.loads(body)
    except ValueError:
        return response(400, "Request body must be valid JSON")

    # An exception here returns a 500 to the caller
    producer.send(
        TOPIC,
        key=event_name.encode("utf-8"),
        value=json.dumps({"name": event_name, "payload": payload}).encode("utf-8"),
    ).get(timeout=30)
    logger.info("Published event %s to topic %s", event_name, TOPIC)
    return response(200, "Event published")
