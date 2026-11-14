import base64
import json
import logging
import os

from aws_msk_iam_sasl_signer import MSKAuthTokenProvider
from kafka import KafkaProducer
from kafka.sasl.oauth import AbstractTokenProvider

logger = logging.getLogger()
logger.setLevel(logging.INFO)

REGION = os.environ["AWS_REGION"]
TOPIC = os.environ["KAFKA_TOPIC"]
BOOTSTRAP_SERVERS = os.environ["BOOTSTRAP_SERVERS"].split(",")

_producer = None


class TokenProvider(AbstractTokenProvider):
    def token(self):
        token, _ = MSKAuthTokenProvider.generate_auth_token(REGION)
        return token


def get_producer():
    # Created on first use rather than at import, so a Kafka outage does not break
    # Lambda initialisation. Warm invocations reuse the connection.
    global _producer
    if _producer is None:
        _producer = KafkaProducer(
            bootstrap_servers=BOOTSTRAP_SERVERS,
            security_protocol="SASL_SSL",
            sasl_mechanism="OAUTHBEARER",
            sasl_oauth_token_provider=TokenProvider(),
            acks="all",
            retries=3,
        )
    return _producer


def reset_producer():
    global _producer
    if _producer is not None:
        try:
            _producer.close(timeout=5)
        except Exception:
            logger.exception("Failed to close Kafka producer")
        _producer = None


def response(status_code, message):
    return {
        "statusCode": status_code,
        "headers": {"content-type": "application/json"},
        "body": json.dumps({"message": message}),
    }


def publish(event_name, payload):
    # A failure resets the producer so the next request reconnects
    try:
        get_producer().send(
            TOPIC,
            key=event_name.encode("utf-8"),
            value=json.dumps({"name": event_name, "payload": payload}).encode("utf-8"),
        ).get(timeout=10)
    except Exception:
        logger.exception("Failed to publish event %s to topic %s", event_name, TOPIC)
        reset_producer()
        raise
    logger.info("Published event %s to topic %s", event_name, TOPIC)


def lambda_handler(event, context):
    # Event from the EventBridge rule on the events bus. An exception makes EventBridge retry.
    if "detail-type" in event:
        publish(event["detail-type"], event["detail"])
        return

    # API Gateway HTTP API (payload format 2.0) request
    event_name = event["pathParameters"]["eventName"]
    body = event.get("body") or "{}"

    if event.get("isBase64Encoded"):
        body = base64.b64decode(body).decode("utf-8")

    logger.info("Received request for event %s with body %s", event_name, body)
    try:
        payload = json.loads(body)
    except ValueError:
        return response(400, "Request body must be valid JSON")

    try:
        publish(event_name, payload)
    except Exception:
        return response(500, "Failed to publish event")
    return response(200, "Event published")
