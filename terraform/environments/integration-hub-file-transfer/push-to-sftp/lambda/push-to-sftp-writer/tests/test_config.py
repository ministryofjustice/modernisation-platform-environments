import json

import pytest

from mft_writer.config import WriterConfig, validate_route, validate_secret_configuration
from mft_writer.errors import InvalidMessage

PREFIX = "arn:aws:secretsmanager:eu-west-2:123456789012:secret:dispatch-"


@pytest.fixture
def destination():
    return {"hostname": "destination.example.com", "username": "delivery", "port": 22,
            "destination_prefix": "incoming/integration-hub/", "host_public_keys": ["ssh-ed25519 AAAA"],
            "destination_cidr_blocks": ["192.0.2.0/24"]}


@pytest.fixture
def config(destination):
    return WriterConfig("push-to-sftp", "clean-bucket", "eu-west-2", "actions", "bus",
                        {PREFIX: destination}, {PREFIX: "group/integration-hub/example/"},
                        {PREFIX: "arn:aws:iam::123456789012:role/delivery"},
                        {PREFIX: "arn:aws:secretsmanager:eu-west-2:123456789012:secret:private-key-AbCdEf"},
                        604800, 604800, {"processing": "arn:aws:sqs:eu-west-2:123456789012:dlq"})


def action(key):
    return {"secret_arn": PREFIX + "AbCdEf", "source_object": {"bucket": "clean-bucket", "key": key}}


@pytest.mark.parametrize("relative", ["test.csv", "nested/test.csv", "literal%20name.csv"])
def test_matches_s3_relative_path_mapping(config, relative):
    route = validate_route(action("group/integration-hub/example/" + relative), config)
    assert route["destination_path"] == "incoming/integration-hub/" + relative


@pytest.mark.parametrize("relative", ["../test.csv", "nested/../../test.csv", "/test.csv", "./test.csv", "nested//test.csv", "bad\x00.csv", "bad\\test.csv", ""])
def test_rejects_filesystem_path_escape(config, relative):
    with pytest.raises(InvalidMessage):
        validate_route(action("group/integration-hub/example/" + relative), config)


def test_configuration_cannot_redirect_destination(config, destination):
    route = validate_route(action("group/integration-hub/example/test.csv"), config)
    secret = {"action": {"name": "push-to-sftp", "push_to_sftp": destination}}
    validate_secret_configuration(json.dumps(secret), "push-to-sftp", route)
    secret["action"]["push_to_sftp"]["hostname"] = "other.example.com"
    with pytest.raises(InvalidMessage):
        validate_secret_configuration(json.dumps(secret), "push-to-sftp", route)