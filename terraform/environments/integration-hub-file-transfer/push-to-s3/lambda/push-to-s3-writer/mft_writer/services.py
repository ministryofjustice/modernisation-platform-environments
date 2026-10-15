from dataclasses import dataclass
from functools import lru_cache
from typing import Any

import boto3
from botocore.config import Config

from mft_writer.config import WriterConfig


@dataclass
class AwsServices:
    secrets: Any
    sts: Any
    table: Any
    eventbridge: Any
    s3_for_role: Any


@lru_cache(maxsize=8)
def _base_aws_clients(region: str, table_name: str) -> tuple[Any, Any, Any, Any, Config]:
    session = boto3.session.Session(region_name=region)
    client_config = Config(
        retries={"mode": "standard", "total_max_attempts": 2},
        connect_timeout=5,
        read_timeout=15,
        max_pool_connections=4,
        tcp_keepalive=True,
    )
    secrets = session.client("secretsmanager", config=client_config)
    sts = session.client("sts", config=client_config)
    table = session.resource("dynamodb", config=client_config).Table(table_name)
    eventbridge = session.client("events", config=client_config)
    return secrets, sts, table, eventbridge, client_config


def create_aws_services(config: WriterConfig) -> AwsServices:
    secrets, sts, table, eventbridge, client_config = _base_aws_clients(
        config.region, config.table_name
    )

    def s3_for_role(role_arn: str, action_id: str) -> Any:
        assumed = sts.assume_role(
            RoleArn=role_arn,
            RoleSessionName=f"file-copy-{action_id[:12]}",
            DurationSeconds=900,
        )["Credentials"]
        role_session = boto3.session.Session(
            aws_access_key_id=assumed["AccessKeyId"],
            aws_secret_access_key=assumed["SecretAccessKey"],
            aws_session_token=assumed["SessionToken"],
            region_name=config.region,
        )
        return role_session.client("s3", config=client_config)

    return AwsServices(secrets, sts, table, eventbridge, s3_for_role)