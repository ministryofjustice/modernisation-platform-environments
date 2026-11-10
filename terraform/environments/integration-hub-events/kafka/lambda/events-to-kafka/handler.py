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


def lambda_handler(event, context):
    # An exception here fails the invocation so EventBridge retries it
    producer.send(
        TOPIC,
        key=event["id"].encode("utf-8"),
        value=json.dumps(event).encode("utf-8"),
    ).get(timeout=30)
    logger.info("Published event %s to topic %s", event["id"], TOPIC)
