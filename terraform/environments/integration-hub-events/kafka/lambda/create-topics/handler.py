import logging
import os

from aws_msk_iam_sasl_signer import MSKAuthTokenProvider
from kafka.admin import KafkaAdminClient, NewTopic
from kafka.errors import TopicAlreadyExistsError

logger = logging.getLogger()
logger.setLevel(logging.INFO)

REGION = os.environ["AWS_REGION"]
BOOTSTRAP_SERVERS = os.environ["BOOTSTRAP_SERVERS"].split(",")


class TokenProvider:
    def token(self):
        token, _ = MSKAuthTokenProvider.generate_auth_token(REGION)
        return token


def lambda_handler(event, context):
    # event: {"topics": [{"name": "...", "partitions": 3, "replication_factor": 1}]}
    admin = KafkaAdminClient(
        bootstrap_servers=BOOTSTRAP_SERVERS,
        security_protocol="SASL_SSL",
        sasl_mechanism="OAUTHBEARER",
        sasl_oauth_token_provider=TokenProvider(),
    )
    try:
        for topic in event["topics"]:
            try:
                admin.create_topics(
                    [
                        NewTopic(
                            name=topic["name"],
                            num_partitions=topic["partitions"],
                            replication_factor=topic["replication_factor"],
                        )
                    ]
                )
                logger.info("Created topic %s", topic["name"])
            except TopicAlreadyExistsError:
                logger.info("Topic %s already exists", topic["name"])
    finally:
        admin.close()
