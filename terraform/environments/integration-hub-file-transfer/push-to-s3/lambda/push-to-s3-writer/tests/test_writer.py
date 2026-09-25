import copy
import json
import os
import uuid
from concurrent.futures import ThreadPoolExecutor
from datetime import datetime, timezone
from pathlib import Path
from threading import Barrier

import boto3
import pytest
import runtime
from boto3.dynamodb.types import TypeSerializer
from botocore.exceptions import ClientError
from botocore.stub import Stubber
from runtime import (
    ActionStore,
    InvalidMessage,
    action_fingerprint,
    action_snapshot,
    copy_versioned_object,
    extract_requested_action,
    process_reporter_record,
    process_writer_record,
    validate_route,
)

SECRET_PREFIX = "arn:aws:secretsmanager:eu-west-2:123456789012:secret:dispatch-"
DESTINATION_BUCKET = "destination-bucket"
DESTINATION_KEY_ARN = "arn:aws:kms:eu-west-2:123456789012:key/abcdef12-3456-7890-abcd-ef1234567890"
ROLE_ARN = "arn:aws:iam::123456789012:role/file-delivery"
DLQ_ARN = "arn:aws:sqs:eu-west-2:123456789012:writer-dlq"


def requested_event():
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
                    "bucket": "clean-bucket",
                    "key": "identity/nested folder/report #1.csv",
                    "versionId": "source-version-1",
                    "sizeBytes": 4096,
                },
                "action": {"name": "push-to-s3"},
                "actionExecutionId": "b1d4e7c2-f073-4ed4-9565-a4c31c54bd7f",
                "requestedAt": "2026-07-10T14:04:00Z",
                "notifications": [],
                "configurationReference": {
                    "secretArn": SECRET_PREFIX + "AbCdE1",
                    "secretVersionId": "immutable-secret-version",
                },
            },
        },
    }


def environment(action_name="push-to-s3", *, reporter=False):
    destination = {
        "bucket": DESTINATION_BUCKET,
        "region": "eu-west-2",
        "destination_prefix": "customer-path/",
        "kms_key_arn": DESTINATION_KEY_ARN,
    }
    action_key = "DELIVERY_ROLE_MAP" if action_name == "push-to-s3" else "MOVER_ROLE_MAP"
    values = {
        "ACTION_NAME": action_name,
        "SOURCE_BUCKET": "clean-bucket",
        "SUPPORTED_REGION": "eu-west-2",
        "IDEMPOTENCY_TABLE": "writer-idempotency",
        "EVENT_BUS_NAME": "file-transfer",
        "AUTHORISED_DESTINATION_MAP": json.dumps({SECRET_PREFIX: destination}),
        "SOURCE_PREFIX_MAP": json.dumps({SECRET_PREFIX: "identity/"}),
        action_key: json.dumps({SECRET_PREFIX: ROLE_ARN}),
        "IDEMPOTENCY_EXPIRY_SECONDS": "604800",
        "TERMINAL_OUTCOME_EXPIRY_SECONDS": "604800",
    }
    if action_name == "push-to-s3-with-hosted-pickup":
        destination["retention_days"] = 7
        destination["bucket"] = "hosted-bucket"
        values["AUTHORISED_DESTINATION_MAP"] = json.dumps({SECRET_PREFIX: destination})
        values["MOVER_ROLE_MAP"] = json.dumps({SECRET_PREFIX: ROLE_ARN})
        values.pop("DELIVERY_ROLE_MAP", None)
    if reporter:
        values["DLQ_ARNS"] = json.dumps({"processing": DLQ_ARN})
    return values


def dispatch_secret(action_name="push-to-s3"):
    if action_name == "push-to-s3":
        details = {
            "bucket_id": DESTINATION_BUCKET,
            "bucket_region": "eu-west-2",
            "destination_prefix": "customer-path/",
            "kms_key_arn": DESTINATION_KEY_ARN,
        }
        action = {"name": action_name, "push_to_s3": details}
    else:
        action = {
            "name": action_name,
            "push_to_s3_with_hosted_pickup": {
                "destination_prefix": "customer-path/",
                "retention_days": 7,
            },
        }
    return json.dumps({"action": action, "notifications": {"email": None}})


class Context:
    aws_request_id = "lambda-request-id"

    def __init__(self, remaining=900_000):
        self.remaining = remaining

    def get_remaining_time_in_millis(self):
        return self.remaining


class NearDeadlineAfterMultipartStart(Context):
    def __init__(self):
        super().__init__()
        self.checks = 0

    def get_remaining_time_in_millis(self):
        self.checks += 1
        return 85_000 if self.checks >= 3 else self.remaining


class FakeTable:
    def __init__(self):
        self.items = {}

    def get_item(self, Key, ConsistentRead):
        return {"Item": copy.deepcopy(self.items[Key["id"]])} if Key["id"] in self.items else {}

    def put_item(self, Item, ConditionExpression):
        if Item["id"] in self.items:
            raise ClientError({"Error": {"Code": "ConditionalCheckFailedException"}}, "PutItem")
        self.items[Item["id"]] = copy.deepcopy(Item)

    def update_item(
        self,
        Key,
        UpdateExpression,
        ConditionExpression,
        ExpressionAttributeValues,
        ReturnValues,
        ExpressionAttributeNames=None,
    ):
        item = self.items[Key["id"]]
        values = ExpressionAttributeValues
        state = item.get("state")
        condition_ok = item.get("fingerprint") == values.get(":fingerprint")
        if "leaseUntil <= :now" in ConditionExpression:
            condition_ok &= state == values[":state"] and item.get("leaseUntil", 0) <= values[":now"]
        elif ":success" in values:
            condition_ok &= state == "COPIED" and item.get("ownerToken") == values[":owner"]
        elif ":copied" in values or ":failed" in values:
            condition_ok &= state == "IN_PROGRESS" and item.get("ownerToken") == values[":owner"]
        if not condition_ok:
            raise ClientError({"Error": {"Code": "ConditionalCheckFailedException"}}, "UpdateItem")

        if "ownerToken = :owner, leaseUntil = :lease" in UpdateExpression:
            item.update(
                ownerToken=values[":owner"],
                leaseUntil=values[":lease"],
                expiration=values[":expiry"],
            )
        elif ":success" in values:
            item.update(state="SUCCEEDED", expiration=values[":expiry"])
            item.pop("ownerToken", None)
            item.pop("leaseUntil", None)
        elif ":copied" in values:
            item.update(
                state="COPIED",
                completedAt=values[":completed"],
                deduplicationExpiresAt=values[":dedupe"],
                expiration=values[":expiry"],
                leaseUntil=values[":lease"],
            )
            if ":version" in values:
                item["destinationVersionId"] = values[":version"]
        elif ":failed" in values:
            item.update(
                state="FAILED",
                completedAt=values[":completed"],
                failureCode=values[":code"],
                failureMessage=values[":message"],
                expiration=values[":expiry"],
            )
            item.pop("ownerToken", None)
            item.pop("leaseUntil", None)
        return {"Attributes": copy.deepcopy(item)}


class FakeS3:
    def __init__(self, *, fail_part=None, head_size=4096, head_metadata=None):
        self.calls = []
        self.fail_part = fail_part
        self.head_size = head_size
        self.head_metadata = head_metadata or {}

    def head_object(self, **kwargs):
        self.calls.append(("head_object", kwargs))
        return {"ContentLength": self.head_size, **self.head_metadata}

    def copy_object(self, **kwargs):
        self.calls.append(("copy_object", kwargs))
        return {"VersionId": "destination-version-1"}

    def create_multipart_upload(self, **kwargs):
        self.calls.append(("create_multipart_upload", kwargs))
        return {"UploadId": "upload-1"}

    def upload_part_copy(self, **kwargs):
        self.calls.append(("upload_part_copy", kwargs))
        if kwargs["PartNumber"] == self.fail_part:
            raise RuntimeError("simulated copy error")
        return {"CopyPartResult": {"ETag": f"etag-{kwargs['PartNumber']}"}}

    def complete_multipart_upload(self, **kwargs):
        self.calls.append(("complete_multipart_upload", kwargs))
        return {"VersionId": "multipart-destination-version"}

    def abort_multipart_upload(self, **kwargs):
        self.calls.append(("abort_multipart_upload", kwargs))


class FakeSecrets:
    def __init__(self, value=None):
        self.value = value or dispatch_secret()
        self.calls = []

    def get_secret_value(self, **kwargs):
        self.calls.append(kwargs)
        return {"VersionId": kwargs["VersionId"], "SecretString": self.value}


class FakeEvents:
    def __init__(self, fail_first=False):
        self.calls = []
        self.fail_first = fail_first

    def put_events(self, **kwargs):
        self.calls.append(kwargs)
        if self.fail_first and len(self.calls) == 1:
            return {
                "FailedEntryCount": 1,
                "Entries": [
                    {
                        "ErrorCode": "InternalFailure",
                        "ErrorMessage": (
                            "denied for arn:aws:secretsmanager:eu-west-2:123456789012:secret:private "
                            "using AKIA1234567890ABCDEF"
                        ),
                    }
                ],
                "ResponseMetadata": {
                    "RequestId": "eventbridge-request-id",
                    "HTTPStatusCode": 200,
                    "RetryAttempts": 1,
                },
            }
        return {"FailedEntryCount": 0, "Entries": [{"EventId": "event-id"}]}


class FakeServices:
    def __init__(self, *, fail_publish_first=False):
        self.table = FakeTable()
        self.secrets = FakeSecrets()
        self.eventbridge = FakeEvents(fail_first=fail_publish_first)
        self.s3 = FakeS3()
        self.assumed_roles = []

    def s3_for_role(self, role_arn, action_id):
        self.assumed_roles.append((role_arn, action_id))
        return self.s3


def writer_config(monkeypatch, *, reporter=False):
    values = environment(reporter=reporter)
    for key, value in values.items():
        monkeypatch.setenv(key, value)
    return runtime.WriterConfig.from_environment(os.environ, reporter=reporter)


def record(event=None, *, queue_arn="arn:aws:sqs:eu-west-2:123456789012:writer"):
    return {
        "messageId": "sqs-message-id",
        "eventSourceARN": queue_arn,
        "attributes": {"ApproximateReceiveCount": "3"},
        "body": json.dumps(event or requested_event()),
    }


def make_snapshot(config):
    event = requested_event()
    action = extract_requested_action(event, config.action_name)
    route = validate_route(action, config)
    fingerprint = action_fingerprint(action, route, config)
    return action, route, action_snapshot(action, route, config, fingerprint)


def seed_state(config, table, state, *, lease_until=0):
    action, route, item = make_snapshot(config)
    item.update(
        state=state,
        ownerToken="old-owner",
        leaseUntil=lease_until,
        expiration=4_000_000_000,
        deduplicationExpiresAt=4_000_000_000,
        destinationVersionId="destination-version-1",
    )
    table.items[item["id"]] = copy.deepcopy(item)
    return action, route, item


def test_route_preserves_nested_special_filename_and_rejects_empty_relative_key(monkeypatch):
    config = writer_config(monkeypatch)
    action = extract_requested_action(requested_event(), config.action_name)

    assert validate_route(action, config)["destination_key"] == "customer-path/nested folder/report #1.csv"
    action["source_object"]["key"] = "identity/"
    with pytest.raises(InvalidMessage, match="no relative filename"):
        validate_route(action, config)


def test_distinct_relative_names_remain_distinct_destination_keys(monkeypatch):
    config = writer_config(monkeypatch)
    first = extract_requested_action(requested_event(), config.action_name)
    second = copy.deepcopy(first)
    second["source_object"]["key"] = "identity/other folder/report #1.csv"

    first_key = validate_route(first, config)["destination_key"]
    second_key = validate_route(second, config)["destination_key"]

    assert first_key == "customer-path/nested folder/report #1.csv"
    assert second_key == "customer-path/other folder/report #1.csv"
    assert first_key != second_key


def test_route_rejects_unconfigured_source_bucket(monkeypatch):
    config = writer_config(monkeypatch)
    action = extract_requested_action(requested_event(), config.action_name)
    action["source_object"]["bucket"] = "other-bucket"

    with pytest.raises(InvalidMessage, match="source bucket"):
        validate_route(action, config)


def test_writer_copies_exact_source_version_with_explicit_kms(monkeypatch):
    config = writer_config(monkeypatch)
    services = FakeServices()

    result = process_writer_record(record(), config, services, Context())

    assert result == "copied"
    copied = next(params for operation, params in services.s3.calls if operation == "copy_object")
    assert copied["CopySource"] == {
        "Bucket": "clean-bucket",
        "Key": "identity/nested folder/report #1.csv",
        "VersionId": "source-version-1",
    }
    assert copied["ServerSideEncryption"] == "aws:kms"
    assert copied["SSEKMSKeyId"] == DESTINATION_KEY_ARN
    assert services.secrets.calls == [
        {"SecretId": SECRET_PREFIX + "AbCdE1", "VersionId": "immutable-secret-version"}
    ]
    assert services.table.items[requested_event()["detail"]["data"]["actionExecutionId"]]["state"] == "SUCCEEDED"


def test_copy_object_request_passes_botocore_parameter_validation():
    s3 = boto3.client(
        "s3",
        region_name="eu-west-2",
        aws_access_key_id="dummy",
        aws_secret_access_key="dummy",
        aws_session_token="dummy",
    )
    source = {
        "bucket": "clean-bucket",
        "key": "identity/nested folder/report #1.csv",
        "versionId": "source-version-1",
        "sizeBytes": 4096,
    }
    route = {
        "destination_bucket": DESTINATION_BUCKET,
        "destination_key": "customer-path/nested folder/report #1.csv",
        "kms_key_arn": DESTINATION_KEY_ARN,
    }
    expected_source = {
        "Bucket": source["bucket"],
        "Key": source["key"],
        "VersionId": source["versionId"],
    }
    stubber = Stubber(s3)
    stubber.add_response(
        "head_object",
        {"ContentLength": source["sizeBytes"]},
        {"Bucket": source["bucket"], "Key": source["key"], "VersionId": source["versionId"]},
    )
    stubber.add_response(
        "copy_object",
        {"VersionId": "destination-version"},
        {
            "Bucket": route["destination_bucket"],
            "Key": route["destination_key"],
            "CopySource": expected_source,
            "MetadataDirective": "COPY",
            "TaggingDirective": "REPLACE",
            "ServerSideEncryption": "aws:kms",
            "SSEKMSKeyId": route["kms_key_arn"],
        },
    )

    with stubber:
        assert copy_versioned_object(s3, source, route, "push-to-s3", Context()) == (
            "destination-version",
            source["sizeBytes"],
        )


def test_mark_copied_dynamodb_request_has_owner_and_fingerprint_condition(monkeypatch):
    config = writer_config(monkeypatch)
    _, _, item = make_snapshot(config)
    dynamodb = boto3.resource(
        "dynamodb",
        region_name="eu-west-2",
        aws_access_key_id="dummy",
        aws_secret_access_key="dummy",
        aws_session_token="dummy",
    )
    table = dynamodb.Table(config.table_name)
    owner_token = "owner-token"
    completed_at = "2026-09-25T12:00:00Z"
    dedupe_expiry = 1_800_000_000
    terminal_expiry = 1_807_776_000
    lease_until = 1_700_000_000
    version_id = "destination-version"
    serializer = TypeSerializer()

    attributes = {
        "id": item["id"],
        "fingerprint": item["fingerprint"],
        "state": "COPIED",
        "ownerToken": owner_token,
        "completedAt": completed_at,
        "deduplicationExpiresAt": dedupe_expiry,
        "expiration": terminal_expiry,
        "leaseUntil": lease_until,
        "destinationVersionId": version_id,
    }
    attributes = {name: serializer.serialize(value) for name, value in attributes.items()}
    expected = {
        "TableName": config.table_name,
        "Key": {"id": item["id"]},
        "UpdateExpression": (
            "SET #state = :copied, completedAt = :completed, deduplicationExpiresAt = :dedupe, "
            "expiration = :expiry, leaseUntil = :lease, destinationVersionId = :version"
        ),
        "ConditionExpression": "#state = :progress AND ownerToken = :owner AND fingerprint = :fingerprint",
        "ExpressionAttributeNames": {"#state": "state"},
        "ExpressionAttributeValues": {
            ":copied": "COPIED",
            ":owner": owner_token,
            ":fingerprint": item["fingerprint"],
            ":expiry": terminal_expiry,
            ":lease": lease_until,
            ":completed": completed_at,
            ":dedupe": dedupe_expiry,
            ":version": version_id,
            ":progress": "IN_PROGRESS",
        },
        "ReturnValues": "ALL_NEW",
    }
    stubber = Stubber(dynamodb.meta.client)
    stubber.add_response("update_item", {"Attributes": attributes}, expected)

    with stubber:
        result = ActionStore(table).mark_copied(
            item,
            owner_token,
            version_id,
            completed_at,
            dedupe_expiry,
            terminal_expiry,
            lease_until,
        )

    assert result["state"] == "COPIED"
    assert result["destinationVersionId"] == version_id


def test_multipart_part_size_supports_sources_over_five_tb_and_respects_s3_bounds():
    size = 5 * 1000**4 + 1

    assert runtime.MAX_MULTIPART_OBJECT_BYTES == runtime.MAX_S3_PARTS * runtime.MAX_MULTIPART_PART_BYTES
    part_size = runtime._multipart_part_size(size)

    assert part_size % (1024 * 1024) == 0
    assert runtime.MIN_MULTIPART_PART_BYTES <= part_size <= runtime.MAX_MULTIPART_PART_BYTES
    assert 1 < -(-size // part_size) <= runtime.MAX_S3_PARTS
    assert runtime._multipart_part_size(runtime.MAX_MULTIPART_OBJECT_BYTES) <= runtime.MAX_MULTIPART_PART_BYTES
    with pytest.raises(InvalidMessage, match="S3 object size limit"):
        runtime._multipart_part_size(runtime.MAX_MULTIPART_OBJECT_BYTES + 1)


def test_zero_byte_source_uses_copy_object(monkeypatch):
    config = writer_config(monkeypatch)
    services = FakeServices()
    source = {"bucket": "clean-bucket", "key": "identity/empty.txt", "versionId": "source-version", "sizeBytes": 0}
    services.s3.head_size = 0
    action = extract_requested_action(requested_event(), config.action_name)
    route = validate_route(action, config)

    version_id, copied_size = copy_versioned_object(services.s3, source, route, config.action_name, Context())

    assert (version_id, copied_size) == ("destination-version-1", 0)
    assert [operation for operation, _ in services.s3.calls] == ["head_object", "copy_object"]


def test_publication_retry_uses_copy_marker_without_recopy(monkeypatch):
    config = writer_config(monkeypatch)
    services = FakeServices(fail_publish_first=True)

    with pytest.raises(RuntimeError, match="EventBridge rejected"):
        process_writer_record(record(), config, services, Context())
    action_id = requested_event()["detail"]["data"]["actionExecutionId"]
    assert services.table.items[action_id]["state"] == "COPIED"
    first_detail = services.eventbridge.calls[0]["Entries"][0]["Detail"]
    assert services.table.items[action_id]["completedAt"]
    services.table.items[action_id]["leaseUntil"] = 0

    assert process_writer_record(record(), config, services, Context()) == "published"
    assert services.eventbridge.calls[1]["Entries"][0]["Detail"] == first_detail
    assert sum(operation == "copy_object" for operation, _ in services.s3.calls) == 1
    assert services.table.items[action_id]["state"] == "SUCCEEDED"


def test_terminal_duplicate_is_acknowledged_without_copy(monkeypatch):
    config = writer_config(monkeypatch)
    services = FakeServices()
    process_writer_record(record(), config, services, Context())

    assert process_writer_record(record(), config, services, Context()) == "duplicate"
    assert sum(operation == "copy_object" for operation, _ in services.s3.calls) == 1


def test_terminal_claim_expires_after_seven_days(monkeypatch):
    config = writer_config(monkeypatch)
    services = FakeServices()

    process_writer_record(record(), config, services, Context())

    terminal_expiry = services.table.items[requested_event()["detail"]["data"]["actionExecutionId"]]["expiration"]
    assert terminal_expiry == pytest.approx(int(datetime.now(timezone.utc).timestamp()) + 7 * 24 * 60 * 60, abs=2)


def test_claim_expires_with_seven_day_deduplication_window(monkeypatch):
    config = writer_config(monkeypatch)
    _, _, item = make_snapshot(config)
    store = ActionStore(FakeTable())

    state, stored, _ = store.claim(
        item,
        now=1_000,
        lease_seconds=60,
        idempotency_seconds=config.idempotency_seconds,
        terminal_seconds=config.terminal_seconds,
    )

    assert state == "claimed"
    assert stored["deduplicationExpiresAt"] == 1_000 + 7 * 24 * 60 * 60
    assert stored["expiration"] == stored["deduplicationExpiresAt"]


def test_writer_does_not_reclaim_expired_nonterminal_marker(monkeypatch):
    config = writer_config(monkeypatch)
    services = FakeServices()
    _, _, item = seed_state(config, services.table, "IN_PROGRESS", lease_until=0)
    services.table.items[item["id"]]["deduplicationExpiresAt"] = 1

    with pytest.raises(RuntimeError, match="outcome may be uncertain"):
        process_writer_record(record(), config, services, Context())

    assert services.table.items[item["id"]]["state"] == "IN_PROGRESS"
    assert not services.s3.calls


def test_reporter_terminalises_expired_nonterminal_marker_as_uncertain(monkeypatch):
    config = writer_config(monkeypatch, reporter=True)
    services = FakeServices()
    _, _, item = seed_state(config, services.table, "IN_PROGRESS", lease_until=0)
    services.table.items[item["id"]]["deduplicationExpiresAt"] = 1

    assert process_reporter_record(record(queue_arn=DLQ_ARN), config, services, Context()) == "failed-reported"

    stored = services.table.items[item["id"]]
    detail = json.loads(services.eventbridge.calls[0]["Entries"][0]["Detail"])
    assert stored["state"] == "FAILED"
    assert "outcome may be uncertain" in detail["data"]["failure"]["message"]


def test_action_fingerprint_binds_source_size_file_and_correlation(monkeypatch):
    config = writer_config(monkeypatch)
    action, route, _ = make_snapshot(config)
    fingerprint = action_fingerprint(action, route, config)

    for section, key, value in (
        ("source_object", "sizeBytes", 4097),
        ("data", "fileId", str(uuid.uuid4())),
        ("metadata", "correlationId", str(uuid.uuid4())),
    ):
        modified = copy.deepcopy(action)
        modified[section][key] = value
        assert action_fingerprint(modified, route, config) != fingerprint


def test_writer_refuses_to_start_copy_near_deadline(monkeypatch):
    config = writer_config(monkeypatch)
    services = FakeServices()

    with pytest.raises(TimeoutError):
        process_writer_record(record(), config, services, Context(remaining=20_000))

    assert not services.s3.calls
    assert services.table.items[requested_event()["detail"]["data"]["actionExecutionId"]]["state"] == "IN_PROGRESS"


def test_writer_accepts_zero_byte_source_version(monkeypatch):
    config = writer_config(monkeypatch)
    event = requested_event()
    event["detail"]["data"]["object"]["sizeBytes"] = 0
    services = FakeServices()
    services.s3.head_size = 0

    assert process_writer_record(record(event), config, services, Context()) == "copied"
    assert any(operation == "copy_object" for operation, _ in services.s3.calls)
    assert not any(operation == "create_multipart_upload" for operation, _ in services.s3.calls)


def test_invalid_dispatch_secret_does_not_claim_or_copy(monkeypatch):
    config = writer_config(monkeypatch)
    services = FakeServices()
    services.secrets.value = dispatch_secret().replace("customer-path/", "other-path/")

    with pytest.raises(InvalidMessage, match="does not match the authorised destination"):
        process_writer_record(record(), config, services, Context())

    assert not services.table.items
    assert not services.s3.calls


def test_stale_in_progress_claim_can_be_recovered(monkeypatch):
    config = writer_config(monkeypatch)
    _, _, item = make_snapshot(config)
    table = FakeTable()
    store = ActionStore(table)
    now = 1_000
    state, _stored, first_owner = store.claim(
        item,
        now=now,
        lease_seconds=60,
        idempotency_seconds=config.idempotency_seconds,
        terminal_seconds=config.terminal_seconds,
    )
    table.items[item["id"]]["leaseUntil"] = now + 30

    state, recovered, second_owner = store.claim(
        item,
        now=now + 31,
        lease_seconds=60,
        idempotency_seconds=config.idempotency_seconds,
        terminal_seconds=config.terminal_seconds,
    )

    assert state == "claimed"
    assert first_owner != second_owner
    assert recovered["ownerToken"] == second_owner
    assert recovered["expiration"] == now + config.idempotency_seconds


def test_multipart_copy_is_sequential_and_aborts_on_failure(monkeypatch):
    monkeypatch.setattr(runtime, "MAX_COPY_OBJECT_BYTES", 1)
    monkeypatch.setattr(runtime, "MULTIPART_PART_BYTES", 5 * 1024 * 1024)
    s3 = FakeS3(fail_part=2, head_size=11 * 1024 * 1024)
    source = {
        "bucket": "clean-bucket",
        "key": "identity/a.bin",
        "versionId": "version-1",
        "sizeBytes": 11 * 1024 * 1024,
    }
    route = {
        "destination_bucket": DESTINATION_BUCKET,
        "destination_key": "pickup/a.bin",
        "kms_key_arn": DESTINATION_KEY_ARN,
    }

    with pytest.raises(RuntimeError, match="simulated"):
        copy_versioned_object(s3, source, route, "push-to-s3-with-hosted-pickup", Context())

    calls = [operation for operation, _ in s3.calls]
    assert calls.count("upload_part_copy") == 2
    assert calls[-1] == "abort_multipart_upload"
    create = next(params for operation, params in s3.calls if operation == "create_multipart_upload")
    assert create["ServerSideEncryption"] == "aws:kms"
    assert create["BucketKeyEnabled"] is True
    first_part = next(params for operation, params in s3.calls if operation == "upload_part_copy")
    assert first_part["CopySourceRange"] == f"bytes=0-{5 * 1024 * 1024 - 1}"


def test_multipart_copy_aborts_when_deadline_reserve_stops_part_work(monkeypatch):
    monkeypatch.setattr(runtime, "MAX_COPY_OBJECT_BYTES", 1)
    s3 = FakeS3(head_size=11 * 1024 * 1024)
    source = {
        "bucket": "clean-bucket",
        "key": "identity/a.bin",
        "versionId": "version-1",
        "sizeBytes": 11 * 1024 * 1024,
    }
    route = {
        "destination_bucket": DESTINATION_BUCKET,
        "destination_key": "pickup/a.bin",
        "kms_key_arn": DESTINATION_KEY_ARN,
    }

    with pytest.raises(TimeoutError, match="UploadPartCopy"):
        copy_versioned_object(s3, source, route, "push-to-s3", NearDeadlineAfterMultipartStart())

    assert [operation for operation, _ in s3.calls][-1] == "abort_multipart_upload"


def test_multipart_copy_preserves_source_metadata_without_copying_tags(monkeypatch):
    monkeypatch.setattr(runtime, "MAX_COPY_OBJECT_BYTES", 1)
    monkeypatch.setattr(runtime, "MULTIPART_PART_BYTES", 5 * 1024 * 1024)
    expires = datetime(2025, 1, 2, tzinfo=timezone.utc)
    metadata = {
        "CacheControl": "private, max-age=600",
        "ContentDisposition": 'attachment; filename="report #1.csv"',
        "ContentEncoding": "gzip",
        "ContentLanguage": "en-GB",
        "ContentType": "text/csv",
        "Expires": expires,
        "Metadata": {"source-id": "nested/path #1", "x-custom": "a=b&c"},
    }
    s3 = FakeS3(head_size=11 * 1024 * 1024, head_metadata=metadata)
    source = {
        "bucket": "clean-bucket",
        "key": "identity/nested folder/report #1.csv",
        "versionId": "exact-source-version",
        "sizeBytes": 11 * 1024 * 1024,
    }
    route = {
        "destination_bucket": DESTINATION_BUCKET,
        "destination_key": "customer-path/nested folder/report #1.csv",
        "kms_key_arn": DESTINATION_KEY_ARN,
    }

    copy_versioned_object(s3, source, route, "push-to-s3", Context())

    create = next(params for operation, params in s3.calls if operation == "create_multipart_upload")
    parts = [params for operation, params in s3.calls if operation == "upload_part_copy"]
    assert {key: create[key] for key in metadata} == metadata
    assert "Tagging" not in create
    assert all(part["CopySource"]["VersionId"] == "exact-source-version" for part in parts)


def test_single_copy_explicitly_preserves_metadata_but_not_tags(monkeypatch):
    config = writer_config(monkeypatch)
    services = FakeServices()
    action = extract_requested_action(requested_event(), config.action_name)
    route = validate_route(action, config)

    copy_versioned_object(services.s3, action["source_object"], route, config.action_name, Context())

    copied = next(params for operation, params in services.s3.calls if operation == "copy_object")
    assert copied["MetadataDirective"] == "COPY"
    assert copied["TaggingDirective"] == "REPLACE"
    assert "Tagging" not in copied


def test_reporter_commits_and_publishes_failed_outcome_only_for_authorised_dlq(monkeypatch):
    config = writer_config(monkeypatch, reporter=True)
    services = FakeServices()
    seed_state(config, services.table, "IN_PROGRESS", lease_until=0)
    dlq_record = record(queue_arn=DLQ_ARN)

    assert process_reporter_record(dlq_record, config, services, Context()) == "failed-reported"
    item = services.table.items[requested_event()["detail"]["data"]["actionExecutionId"]]
    assert item["state"] == "FAILED"
    published = json.loads(services.eventbridge.calls[0]["Entries"][0]["Detail"])
    assert published["data"]["status"] == "failed"
    assert published["metadata"]["idempotencyKey"] == f"action-complete:{item['id']}"


@pytest.mark.parametrize("wrapped", [False, True], ids=["eventbridge", "sns"])
def test_reporter_claims_and_reports_dlq_event_without_existing_item(monkeypatch, wrapped):
    config = writer_config(monkeypatch, reporter=True)
    services = FakeServices()
    dlq_record = record(queue_arn=DLQ_ARN)
    if wrapped:
        dlq_record["body"] = json.dumps(
            {"Type": "Notification", "Message": json.dumps(requested_event())}
        )

    assert process_reporter_record(dlq_record, config, services, Context()) == "failed-reported"

    item = services.table.items[requested_event()["detail"]["data"]["actionExecutionId"]]
    published = json.loads(services.eventbridge.calls[0]["Entries"][0]["Detail"])
    assert item["state"] == "FAILED"
    assert published["data"]["status"] == "failed"
    assert services.secrets.calls == []
    assert not services.s3.calls


def test_writer_and_reporter_race_has_one_atomic_terminal_outcome(monkeypatch):
    config = writer_config(monkeypatch, reporter=True)
    services = FakeServices()
    start = Barrier(2)

    def run_writer():
        start.wait()
        return process_writer_record(record(), config, services, Context())

    def run_reporter():
        start.wait()
        try:
            return process_reporter_record(record(queue_arn=DLQ_ARN), config, services, Context())
        except RuntimeError:
            return "deferred"

    with ThreadPoolExecutor(max_workers=2) as workers:
        writer_result = workers.submit(run_writer)
        reporter_result = workers.submit(run_reporter)
        writer_result.result()
        reporter_result.result()

    action_id = requested_event()["detail"]["data"]["actionExecutionId"]
    terminal = services.table.items[action_id]
    assert terminal["state"] in {"SUCCEEDED", "FAILED"}
    if terminal["state"] == "SUCCEEDED":
        assert sum(operation == "copy_object" for operation, _ in services.s3.calls) == 1
    else:
        assert not services.s3.calls


def test_reporter_defers_active_writer_and_does_not_override_success(monkeypatch):
    config = writer_config(monkeypatch, reporter=True)
    active_services = FakeServices()
    seed_state(config, active_services.table, "IN_PROGRESS", lease_until=4_000_000_000)

    with pytest.raises(RuntimeError, match="still active"):
        process_reporter_record(record(queue_arn=DLQ_ARN), config, active_services, Context())
    assert not active_services.eventbridge.calls

    success_services = FakeServices()
    seed_state(config, success_services.table, "SUCCEEDED")
    assert process_reporter_record(record(queue_arn=DLQ_ARN), config, success_services, Context()) == "already-succeeded"
    assert not success_services.eventbridge.calls


def test_reporter_publishes_success_when_copy_marker_exists(monkeypatch):
    config = writer_config(monkeypatch, reporter=True)
    services = FakeServices()
    seed_state(config, services.table, "COPIED", lease_until=0)

    assert process_reporter_record(record(queue_arn=DLQ_ARN), config, services, Context()) == "copied-reported"
    published = json.loads(services.eventbridge.calls[0]["Entries"][0]["Detail"])
    assert published["data"]["status"] == "succeeded"
    assert services.table.items[requested_event()["detail"]["data"]["actionExecutionId"]]["state"] == "SUCCEEDED"


def test_reporter_retries_failed_completion_without_changing_terminal_state(monkeypatch):
    config = writer_config(monkeypatch, reporter=True)
    services = FakeServices(fail_publish_first=True)
    seed_state(config, services.table, "IN_PROGRESS", lease_until=0)

    with pytest.raises(RuntimeError, match="EventBridge rejected"):
        process_reporter_record(record(queue_arn=DLQ_ARN), config, services, Context())
    action_id = requested_event()["detail"]["data"]["actionExecutionId"]
    first_detail = services.eventbridge.calls[0]["Entries"][0]["Detail"]
    assert services.table.items[action_id]["state"] == "FAILED"

    assert process_reporter_record(record(queue_arn=DLQ_ARN), config, services, Context()) == "failed-republished"
    assert services.eventbridge.calls[1]["Entries"][0]["Detail"] == first_detail
    assert services.table.items[action_id]["state"] == "FAILED"


def test_writer_returns_partial_batch_failures(monkeypatch):
    writer_config(monkeypatch)
    services = FakeServices()
    malformed = record()
    malformed["messageId"] = "malformed-message"
    malformed["body"] = "not-json"

    result = runtime.process_writer_event(
        {"Records": [record(), malformed]}, Context(), services
    )

    assert result == {"batchItemFailures": [{"itemIdentifier": "malformed-message"}]}


def test_failure_log_retains_sanitised_service_error_and_live_operation(monkeypatch):
    writer_config(monkeypatch)
    services = FakeServices(fail_publish_first=True)
    active_fields = {}
    emitted = []
    monkeypatch.setattr(runtime.logger, "append_keys", lambda **values: active_fields.update(values))
    monkeypatch.setattr(
        runtime.logger,
        "remove_keys",
        lambda keys: [active_fields.pop(key, None) for key in keys],
    )
    monkeypatch.setattr(
        runtime.logger,
        "error",
        lambda message, **values: emitted.append({**active_fields, **values}),
    )

    result = runtime.process_writer_event({"Records": [record()]}, Context(), services)

    assert result == {"batchItemFailures": [{"itemIdentifier": "sqs-message-id"}]}
    failure = emitted[0]
    assert failure["operation"] == "publish-completion"
    assert failure["actionExecutionId"] == requested_event()["detail"]["data"]["actionExecutionId"]
    assert failure["awsErrorCode"] == "InternalFailure"
    assert failure["awsRequestId"] == "eventbridge-request-id"
    assert failure["httpStatusCode"] == 200
    assert failure["retryCount"] == 1
    assert failure["retryable"] is True
    assert "denied for" in failure["awsErrorMessage"]
    assert "arn:aws" not in failure["awsErrorMessage"]
    assert "AKIA1234567890ABCDEF" not in failure["awsErrorMessage"]
    assert isinstance(failure["elapsedMillis"], int)
    assert isinstance(failure["remainingTimeMillis"], int)
    assert active_fields == {}


def test_structured_log_context_clears_dynamic_fields_between_records(monkeypatch):
    active_fields = {}
    emitted = []
    monkeypatch.setattr(runtime.logger, "append_keys", lambda **values: active_fields.update(values))
    monkeypatch.setattr(
        runtime.logger,
        "remove_keys",
        lambda keys: [active_fields.pop(key, None) for key in keys],
    )
    monkeypatch.setattr(
        runtime.logger,
        "info",
        lambda message, **values: emitted.append({**active_fields, **values}),
    )

    first_fields = {"sqsMessageId": "first"}
    with runtime.structured_record_context(first_fields):
        runtime._update_log_fields(first_fields, actionExecutionId="first-action")
        runtime.logger.info("first record")
    with runtime.structured_record_context({"sqsMessageId": "second"}):
        runtime.logger.info("second record")

    assert emitted[0]["actionExecutionId"] == "first-action"
    assert "actionExecutionId" not in emitted[1]
    assert active_fields == {}


def test_aws_services_reuse_base_clients_without_reusing_role_credentials(monkeypatch):
    config = writer_config(monkeypatch)
    runtime._base_aws_clients.cache_clear()
    sessions = []

    class FakeStsClient:
        def assume_role(self, RoleArn, RoleSessionName, DurationSeconds):
            return {
                "Credentials": {
                    "AccessKeyId": f"key-{RoleArn.rsplit('/', 1)[-1]}",
                    "SecretAccessKey": f"secret-{RoleArn.rsplit('/', 1)[-1]}",
                    "SessionToken": f"token-{RoleArn.rsplit('/', 1)[-1]}",
                }
            }

    sts_client = FakeStsClient()

    class FakeSession:
        def __init__(self, **kwargs):
            self.kwargs = kwargs
            self.clients = {}
            sessions.append(self)

        def client(self, service_name, config):
            if service_name == "sts":
                return sts_client
            return self.clients.setdefault(service_name, object())

        def resource(self, service_name, config):
            return self

        def Table(self, table_name):
            return self.clients.setdefault(f"dynamodb:{table_name}", object())

    monkeypatch.setattr(runtime.boto3.session, "Session", FakeSession)
    first = runtime.create_aws_services(config)
    second = runtime.create_aws_services(config)

    assert len(sessions) == 1
    assert first.secrets is second.secrets
    assert first.sts is second.sts
    assert first.table is second.table
    assert first.eventbridge is second.eventbridge

    first_s3 = first.s3_for_role(ROLE_ARN, "action-one")
    second_s3 = first.s3_for_role("arn:aws:iam::123456789012:role/other-delivery", "action-two")

    assert first_s3 is not second_s3
    assert sessions[-2].kwargs["aws_access_key_id"] == "key-file-delivery"
    assert sessions[-1].kwargs["aws_access_key_id"] == "key-other-delivery"
    assert sessions[-2].kwargs["aws_session_token"] != sessions[-1].kwargs["aws_session_token"]
    runtime._base_aws_clients.cache_clear()


def test_reporter_rejects_non_dlq_queue(monkeypatch):
    config = writer_config(monkeypatch, reporter=True)
    services = FakeServices()

    with pytest.raises(InvalidMessage, match="dead-letter"):
        process_reporter_record(record(), config, services, Context())


@pytest.mark.parametrize("status", ["succeeded", "failed"])
def test_completion_details_match_eventbridge_schema(status, monkeypatch):
    jsonschema = pytest.importorskip("jsonschema")
    config = writer_config(monkeypatch)
    action, _route, item = make_snapshot(config)
    item["destinationVersionId"] = "destination-version-1"
    item["failureCode"] = "DeliveryAttemptsExhausted"
    item["failureMessage"] = "Delivery attempts exhausted."
    detail = runtime.build_completion_detail(item, status)
    schema_path = Path(__file__).resolve().parents[4] / "schemas" / "FileActionExecutionCompleted.v1.json"
    schema = json.loads(schema_path.read_text())
    envelope = {
        "version": "0",
        "id": str(uuid.uuid4()),
        "detail-type": "FileActionExecutionCompleted.v1",
        "source": "uk.gov.justice.service.managed-file-transfer",
        "account": "123456789012",
        "time": datetime.now(timezone.utc).isoformat(),
        "region": "eu-west-2",
        "detail": detail,
    }

    jsonschema.Draft4Validator(schema).validate(envelope)
    assert detail["metadata"]["causationId"] == action["event"]["id"]
    assert detail["metadata"]["idempotencyKey"] == f"action-complete:{item['id']}"