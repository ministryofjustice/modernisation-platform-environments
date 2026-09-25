import json

import pytest
from runtime import (
    InvalidMessage,
    extract_requested_action,
    resolve_secret_entry,
    unwrap_event,
)


def requested_event(secret_arn="arn:aws:secretsmanager:eu-west-2:123456789012:secret:dispatch-AbCdE1"):
    return {
        "version": "0",
        "id": "2bd32cbb-c3e2-4b62-8b53-90ea0a7a4de5",
        "detail-type": "FileActionExecutionRequested.v1",
        "source": "uk.gov.justice.service.managed-file-transfer",
        "account": "123456789012",
        "time": "2026-07-10T14:04:00Z",
        "region": "eu-west-2",
        "detail": {
            "metadata": {
                "correlationId": "7d9f4e4c-0e0f-4a5b-8b4e-4ab1f28fd1d1",
                "causationId": "aa88e95a-159c-40c1-9e7b-38d00b0b6169",
                "idempotencyKey": "action-request:b1d4e7c2-f073-4ed4-9565-a4c31c54bd7f",
            },
            "data": {
                "fileId": "3f4e3d7a-4e2f-4bc2-9c4e-5f1ef2d4c501",
                "object": {
                    "bucket": "clean",
                    "key": "identity/nested/report.csv",
                    "versionId": "source-version",
                    "sizeBytes": 4096,
                },
                "action": {"name": "push-to-s3"},
                "actionExecutionId": "b1d4e7c2-f073-4ed4-9565-a4c31c54bd7f",
                "requestedAt": "2026-07-10T14:04:00Z",
                "notifications": [],
                "configurationReference": {
                    "secretArn": secret_arn,
                    "secretVersionId": "immutable-secret-version",
                },
            },
        },
    }


def test_extract_requested_action_accepts_direct_event_and_sns_wrapper():
    event = requested_event()
    wrapped = {"Type": "Notification", "Message": json.dumps(event)}

    assert extract_requested_action(event, "push-to-s3")["data"]["actionExecutionId"] == event[
        "detail"
    ]["data"]["actionExecutionId"]
    assert unwrap_event(json.dumps(wrapped)) == event


def test_extract_requested_action_rejects_wrong_action():
    event = requested_event()
    event["detail"]["data"]["action"]["name"] = "another-action"

    with pytest.raises(InvalidMessage, match="does not match"):
        extract_requested_action(event, "push-to-s3")


def test_resolve_secret_entry_requires_one_prefix_and_exact_six_character_suffix():
    prefix = "arn:aws:secretsmanager:eu-west-2:123456789012:secret:dispatch-"
    allowlist = {prefix: {"bucket": "destination"}}

    assert resolve_secret_entry(prefix + "AbCdE1", allowlist)[0] == prefix
    for suffix in ("AbCdE", "AbCdE12", "AbCdE!1"):
        with pytest.raises(InvalidMessage):
            resolve_secret_entry(prefix + suffix, allowlist)


def test_resolve_secret_entry_ignores_shorter_lookalike_prefix():
    arn = "arn:aws:secretsmanager:eu-west-2:123456789012:secret:dispatch-AbCdE1"
    allowlist = {
        "arn:aws:secretsmanager:eu-west-2:123456789012:secret:dispatch-": {},
        "arn:aws:secretsmanager:eu-west-2:123456789012:secret:dispatch-Ab": {},
    }

    selected, _ = resolve_secret_entry(arn, allowlist)

    assert selected == "arn:aws:secretsmanager:eu-west-2:123456789012:secret:dispatch-"


def test_extract_requested_action_rejects_non_object_nested_fields():
    event = requested_event()
    event["detail"]["metadata"] = []

    with pytest.raises(InvalidMessage, match="object fields"):
        extract_requested_action(event, "push-to-s3")


def test_extract_requested_action_rejects_null_s3_version():
    event = requested_event()
    event["detail"]["data"]["object"]["versionId"] = "null"

    with pytest.raises(InvalidMessage, match="immutable S3 version"):
        extract_requested_action(event, "push-to-s3")