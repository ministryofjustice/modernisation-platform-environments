import copy
import json
from pathlib import Path
from types import SimpleNamespace
from unittest.mock import Mock

import jsonschema
import pytest
from botocore.exceptions import ClientError

from mft_writer import services as aws_services, worker
from mft_writer.completion import build_completion_detail
from mft_writer.config import WriterConfig, validate_route
from mft_writer.diagnostics import (
    AWS_OPERATION_SAFETY_MILLIS,
    REPORTER_OPERATION_SAFETY_MILLIS,
    REPORTER_RECORD_SAFETY_MILLIS,
)
from mft_writer.errors import DeadlineExceeded, InvalidMessage
from mft_writer.events import extract_requested_action
from mft_writer.services import AwsServices
from mft_writer.store import ActionStore

SECRET_PREFIX = "arn:aws:secretsmanager:eu-west-2:123456789012:secret:dispatch-"
DLQ_ARN = "arn:aws:sqs:eu-west-2:123456789012:dlq"


class FakeTable:
    def __init__(self):
        self.items = {}

    def get_item(self, Key, ConsistentRead):
        assert ConsistentRead is True
        return {"Item": copy.deepcopy(self.items[Key["id"]])} if Key["id"] in self.items else {}

    def put_item(self, Item, ConditionExpression):
        assert ConditionExpression == "attribute_not_exists(id)"
        if Item["id"] in self.items:
            raise ClientError({"Error": {"Code": "ConditionalCheckFailedException"}}, "PutItem")
        self.items[Item["id"]] = copy.deepcopy(Item)

    def update_item(self, Key, UpdateExpression, ConditionExpression, ExpressionAttributeValues,
                    ReturnValues, ExpressionAttributeNames=None):
        item = self.items[Key["id"]]
        values = ExpressionAttributeValues
        valid = item["fingerprint"] == values[":fingerprint"]
        if "leaseUntil <= :now" in ConditionExpression:
            valid &= item["state"] == values[":state"] and item["leaseUntil"] <= values[":now"]
        else:
            valid &= item["ownerToken"] == values[":owner"]
            valid &= item["state"] == ("COPIED" if ":success" in values else "IN_PROGRESS")
        if not valid:
            raise ClientError({"Error": {"Code": "ConditionalCheckFailedException"}}, "UpdateItem")
        if "ownerToken = :owner, leaseUntil = :lease" in UpdateExpression:
            item.update(ownerToken=values[":owner"], leaseUntil=values[":lease"], expiration=values[":expiry"])
        elif ":success" in values:
            item.update(state="SUCCEEDED", expiration=values[":expiry"])
            item.pop("ownerToken")
            item.pop("leaseUntil")
        elif ":copied" in values:
            item.update(state="COPIED", completedAt=values[":completed"], expiration=values[":expiry"],
                        deduplicationExpiresAt=values[":dedupe"], leaseUntil=values[":lease"])
            assert ":version" not in values
        else:
            item.update(state="FAILED", completedAt=values[":completed"], expiration=values[":expiry"],
                        failureCode=values[":code"], failureMessage=values[":message"])
            item.pop("ownerToken")
            item.pop("leaseUntil")
        return {"Attributes": copy.deepcopy(item)}


@pytest.fixture
def setup(monkeypatch):
    destination = {"hostname": "destination.example.com", "username": "delivery", "port": 22,
                   "destination_prefix": "incoming/", "host_public_keys": ["ssh-ed25519 AAAA"],
                   "destination_cidr_blocks": ["192.0.2.0/24"]}
    environment = {
        "ACTION_NAME": "push-to-sftp", "SOURCE_BUCKET": "clean-bucket", "SUPPORTED_REGION": "eu-west-2",
        "IDEMPOTENCY_TABLE": "actions", "EVENT_BUS_NAME": "bus",
        "AUTHORISED_DESTINATION_MAP": json.dumps({SECRET_PREFIX: destination}),
        "SOURCE_PREFIX_MAP": json.dumps({SECRET_PREFIX: "identity/"}),
        "DELIVERY_ROLE_MAP": json.dumps({SECRET_PREFIX: "arn:aws:iam::123456789012:role/delivery"}),
        "CREDENTIAL_SECRET_MAP": json.dumps({SECRET_PREFIX: SECRET_PREFIX + "private-AbCdEf"}),
        "IDEMPOTENCY_EXPIRY_SECONDS": "604800", "TERMINAL_OUTCOME_EXPIRY_SECONDS": "604800",
        "DLQ_ARNS": json.dumps({"processing": DLQ_ARN}),
    }
    for name, value in environment.items():
        monkeypatch.setenv(name, value)
    event = {
        "version": "0", "id": "2bd32cbb-c3e2-4b62-8b53-90ea0a7a4de5",
        "detail-type": "FileActionExecutionRequested.v1", "source": "uk.gov.justice.service.managed-file-transfer",
        "account": "123456789012", "time": "2026-07-10T14:04:00Z", "region": "eu-west-2",
        "detail": {
            "metadata": {"correlationId": "7d9f4e4c-0e0f-4a5b-8b4e-4ab1f28fd1d1",
                         "causationId": "aa88e95a-159c-40c1-9e7b-38d00b0b6169",
                         "idempotencyKey": "action-request:b1d4e7c2-f073-4ed4-9565-a4c31c54bd7f"},
            "data": {"fileId": "3f4e3d7a-4e2f-4bc2-9c4e-5f1ef2d4c501",
                     "object": {"bucket": "clean-bucket", "key": "identity/nested/file.csv", "versionId": "source-v1", "sizeBytes": 3},
                     "action": {"name": "push-to-sftp"}, "actionExecutionId": "b1d4e7c2-f073-4ed4-9565-a4c31c54bd7f",
                     "requestedAt": "2026-07-10T14:04:00Z", "notifications": [],
                     "configurationReference": {"secretArn": SECRET_PREFIX + "AbCdEf", "secretVersionId": "dispatch-v1"}},
        },
    }
    secret = json.dumps({"action": {"name": "push-to-sftp", "push_to_sftp": destination}})
    services = AwsServices(Mock(), Mock(), FakeTable(), Mock(), Mock(return_value=(Mock(), Mock())))
    services.secrets.get_secret_value.return_value = {"VersionId": "dispatch-v1", "SecretString": secret}
    services.eventbridge.put_events.return_value = {"FailedEntryCount": 0, "Entries": [{"EventId": "completion-id"}]}
    transfer = Mock(return_value=3)
    monkeypatch.setattr(worker, "transfer_versioned_object", transfer)
    return SimpleNamespace(event=event, record={"messageId": "message-1", "eventSourceARN": DLQ_ARN,
                                              "body": json.dumps({"Type": "Notification", "Message": json.dumps(event)})},
                           config=WriterConfig.from_environment(environment, reporter=True), services=services, transfer=transfer)


def stored_item(setup):
    return next(iter(setup.services.table.items.values()))


@pytest.mark.parametrize("reporter", [False, True])
def test_empty_configuration_rejects_requests_without_side_effects(setup, monkeypatch, reporter):
    for name in ("AUTHORISED_DESTINATION_MAP", "SOURCE_PREFIX_MAP", "DELIVERY_ROLE_MAP", "CREDENTIAL_SECRET_MAP"):
        monkeypatch.setenv(name, "{}")
    metrics = Mock()
    monkeypatch.setattr(worker, "metrics", metrics)
    process = worker.process_reporter_event if reporter else worker.process_writer_event

    assert process({"Records": [setup.record]}, None, setup.services) == {
        "batchItemFailures": [{"itemIdentifier": "message-1"}]
    }
    metric_name = "ReporterRecordFailed" if reporter else "WriterRecordFailed"
    assert any(call.kwargs.get("name") == metric_name for call in metrics.add_metric.call_args_list)
    assert not setup.services.table.items
    setup.services.secrets.get_secret_value.assert_not_called()
    setup.services.sts.assume_role.assert_not_called()
    setup.services.clients_for_role.assert_not_called()
    setup.services.eventbridge.put_events.assert_not_called()
    setup.transfer.assert_not_called()


def test_upload_checkpoint_completion_and_duplicate(setup):
    assert worker.process_writer_record(setup.record, setup.config, setup.services, None) == "copied"
    assert stored_item(setup)["state"] == "SUCCEEDED"
    assert "destinationVersionId" not in stored_item(setup)
    setup.services.secrets.get_secret_value.assert_called_with(SecretId=SECRET_PREFIX + "AbCdEf", VersionId="dispatch-v1")
    assert worker.process_writer_record(setup.record, setup.config, setup.services, None) == "duplicate"
    setup.transfer.assert_called_once()
    setup.services.clients_for_role.assert_called_once()
    schema = json.loads((Path(__file__).parents[4] / "schemas/FileActionExecutionCompleted.v1.json").read_text())
    detail = build_completion_detail(stored_item(setup), "succeeded")
    completed = {**setup.event, "detail-type": "FileActionExecutionCompleted.v1", "detail": detail}
    jsonschema.validate(completed, schema)
    assert detail["data"]["result"] == {"protocol": "sftp", "destinationPath": "incoming/nested/file.csv", "bytesTransferred": 3}


@pytest.mark.parametrize("reporter", [False, True])
def test_completion_retry_does_not_read_credentials_or_reconnect(setup, reporter):
    setup.services.eventbridge.put_events.side_effect = RuntimeError("publish failed")
    with pytest.raises(RuntimeError):
        worker.process_writer_record(setup.record, setup.config, setup.services, None)
    assert stored_item(setup)["state"] == "COPIED"
    stored_item(setup)["leaseUntil"] = 0
    setup.services.eventbridge.put_events.side_effect = None
    process = worker.process_reporter_record if reporter else worker.process_writer_record
    assert process(setup.record, setup.config, setup.services, None) in {"published", "copied-reported"}
    setup.transfer.assert_called_once()
    setup.services.clients_for_role.assert_called_once()
    assert stored_item(setup)["state"] == "SUCCEEDED"


def test_active_lease_and_changed_action_fail_closed(setup):
    setup.transfer.side_effect = OSError("remote unavailable")
    with pytest.raises(OSError):
        worker.process_writer_record(setup.record, setup.config, setup.services, None)
    with pytest.raises(RuntimeError, match="lease"):
        worker.process_writer_record(setup.record, setup.config, setup.services, None)
    setup.config.destinations[SECRET_PREFIX]["port"] = 2222
    with pytest.raises(InvalidMessage):
        worker.process_writer_record(setup.record, setup.config, setup.services, None)
    setup.transfer.assert_called_once()


def test_dispatch_version_mismatch_prevents_side_effects(setup):
    setup.services.secrets.get_secret_value.return_value["VersionId"] = "wrong-version"
    with pytest.raises(InvalidMessage):
        worker.process_writer_record(setup.record, setup.config, setup.services, None)
    assert not setup.services.table.items
    setup.services.clients_for_role.assert_not_called()


@pytest.mark.parametrize("wrapped", [False, True])
def test_reporter_terminal_failure_can_be_republished_without_credentials(setup, wrapped):
    if not wrapped:
        setup.record["body"] = json.dumps(setup.event)
    assert worker.process_reporter_record(setup.record, setup.config, setup.services, None) == "failed-reported"
    assert worker.process_reporter_record(setup.record, setup.config, setup.services, None) == "failed-republished"
    setup.services.secrets.get_secret_value.assert_not_called()
    setup.services.clients_for_role.assert_not_called()
    setup.transfer.assert_not_called()


def test_expired_action_requires_reporter_and_owner_token_is_enforced(setup):
    action = extract_requested_action(setup.record["body"], setup.config.action_name)
    route = validate_route(action, setup.config)
    item = worker.action_snapshot(action, route, setup.config, worker.action_fingerprint(action, route, setup.config))
    store = ActionStore(setup.services.table)
    _, claimed, owner = store.claim(item, now=0, lease_seconds=30, idempotency_seconds=60, terminal_seconds=60)
    assert store.claim(item, now=61, lease_seconds=30, idempotency_seconds=60, terminal_seconds=60)[0] == "expired"
    with pytest.raises(ClientError):
        store.mark_copied(claimed, "wrong-owner", None, "now", 60, 60, 30)
    assert store.claim(item, now=61, lease_seconds=30, idempotency_seconds=60, terminal_seconds=60, allow_expired=True)[0] == "claimed-expired"
    assert owner != stored_item(setup)["ownerToken"]


def test_record_failures_emit_partial_batch_metric_without_secret_text(setup, monkeypatch, capsys):
    metrics = Mock()
    monkeypatch.setattr(worker, "metrics", metrics)
    setup.transfer.side_effect = OSError("PRIVATE-KEY-SHOULD-NOT-APPEAR")
    assert worker.process_writer_event({"Records": [setup.record]}, None, setup.services) == {"batchItemFailures": [{"itemIdentifier": "message-1"}]}
    assert any(call.kwargs.get("name") == "WriterRecordFailed" for call in metrics.add_metric.call_args_list)
    assert "PRIVATE-KEY-SHOULD-NOT-APPEAR" not in capsys.readouterr().out


def test_reporter_clients_have_separate_cached_timeout_configuration(monkeypatch):
    session_factory = Mock()
    monkeypatch.setattr(aws_services.boto3.session, "Session", session_factory)
    aws_services._base_aws_clients.cache_clear()
    try:
        writer = aws_services._base_aws_clients("eu-west-2", "actions", reporter=False)
        reporter = aws_services._base_aws_clients("eu-west-2", "actions", reporter=True)
        assert aws_services._base_aws_clients("eu-west-2", "actions", reporter=False) is writer
        assert aws_services._base_aws_clients("eu-west-2", "actions", reporter=True) is reporter
        assert session_factory.call_count == 2
        for clients, connect, read, margin in (
            (writer, 5, 15, AWS_OPERATION_SAFETY_MILLIS),
            (reporter, 2, 3, REPORTER_OPERATION_SAFETY_MILLIS),
        ):
            config = clients[-1]
            assert (config.connect_timeout, config.read_timeout) == (connect, read)
            assert config.retries == {"mode": "standard", "total_max_attempts": 2}
            assert margin == (2 * (connect + read) + 1 + 4) * 1000
        session = session_factory.return_value
        assert [call.kwargs["config"] for call in session.client.call_args_list] == [
            writer[-1], writer[-1], writer[-1], reporter[-1], reporter[-1], reporter[-1],
        ]
        assert [call.kwargs["config"] for call in session.resource.call_args_list] == [
            writer[-1], reporter[-1],
        ]
    finally:
        aws_services._base_aws_clients.cache_clear()


@pytest.mark.parametrize("reporter", [False, True])
def test_event_selects_the_correct_client_configuration(setup, monkeypatch, reporter):
    factory = Mock(return_value=setup.services)
    monkeypatch.setattr(worker, "create_aws_services", factory)
    monkeypatch.setattr(worker, "metrics", Mock())
    process = worker.process_reporter_event if reporter else worker.process_writer_event
    assert process({"Records": [setup.record]}, None) == {"batchItemFailures": []}
    factory.assert_called_once()
    assert factory.call_args.kwargs == {"reporter": reporter}


@pytest.mark.parametrize("remaining", [REPORTER_RECORD_SAFETY_MILLIS - 1, REPORTER_RECORD_SAFETY_MILLIS])
def test_reporter_defers_all_records_at_the_admission_boundary(setup, monkeypatch, remaining):
    metrics = Mock()
    monkeypatch.setattr(worker, "metrics", metrics)
    table = Mock()
    setup.services.table = table
    context = SimpleNamespace(get_remaining_time_in_millis=lambda: remaining)
    records = [dict(setup.record, messageId=f"message-{index}") for index in range(3)]
    assert worker.process_reporter_event({"Records": records}, context, setup.services) == {
        "batchItemFailures": [{"itemIdentifier": record["messageId"]} for record in records]
    }
    assert not table.method_calls
    setup.services.eventbridge.put_events.assert_not_called()
    assert [call.kwargs["name"] for call in metrics.add_metric.call_args_list] == [
        "ReporterRecordDeferred",
    ] * 3


def test_reporter_admits_a_record_above_the_boundary(setup, monkeypatch):
    monkeypatch.setattr(worker, "metrics", Mock())
    context = SimpleNamespace(
        get_remaining_time_in_millis=lambda: REPORTER_RECORD_SAFETY_MILLIS + 1
    )
    assert worker.process_reporter_event(
        {"Records": [setup.record]}, context, setup.services
    ) == {"batchItemFailures": []}
    assert stored_item(setup)["state"] == "FAILED"
    setup.services.eventbridge.put_events.assert_called_once()


def test_reporter_preserves_successes_and_failures_when_the_batch_runs_out_of_time(setup, monkeypatch):
    metrics = Mock()
    monkeypatch.setattr(worker, "metrics", metrics)
    remaining = Mock(return_value=60_000)
    context = SimpleNamespace(get_remaining_time_in_millis=remaining)
    records = [dict(setup.record, messageId=f"message-{index}") for index in range(4)]

    def process_record(record, *_args):
        if record["messageId"] == "message-0":
            return "already-succeeded"
        remaining.return_value = REPORTER_RECORD_SAFETY_MILLIS
        raise TimeoutError("AWS operation timed out")

    process = Mock(side_effect=process_record)
    monkeypatch.setattr(worker, "process_reporter_record", process)
    assert worker.process_reporter_event({"Records": records}, context, setup.services) == {
        "batchItemFailures": [
            {"itemIdentifier": "message-1"},
            {"itemIdentifier": "message-2"},
            {"itemIdentifier": "message-3"},
        ]
    }
    assert process.call_count == 2
    assert [call.kwargs["name"] for call in metrics.add_metric.call_args_list] == [
        "ReporterRecordAlready-Succeeded", "ReporterRecordFailed",
        "ReporterRecordDeferred", "ReporterRecordDeferred",
    ]


@pytest.mark.parametrize("exhaust_after", ["put_item", "get_item", "update_item", "put_events"])
def test_reporter_guards_each_copied_recovery_call_and_retains_the_checkpoint(
    setup, monkeypatch, exhaust_after
):
    setup.services.eventbridge.put_events.side_effect = RuntimeError("publish failed")
    with pytest.raises(RuntimeError):
        worker.process_writer_record(setup.record, setup.config, setup.services, None)
    stored_item(setup)["leaseUntil"] = 0
    original_owner = stored_item(setup)["ownerToken"]
    publisher = setup.services.eventbridge.put_events
    publisher.side_effect = None
    publisher.reset_mock()
    metrics = Mock()
    monkeypatch.setattr(worker, "metrics", metrics)
    remaining = Mock(return_value=60_000)
    context = SimpleNamespace(get_remaining_time_in_millis=remaining)
    calls = []
    exhausted = False

    def wrap_call(name, original):
        def guarded_call(*args, **kwargs):
            nonlocal exhausted
            calls.append(name)
            try:
                return original(*args, **kwargs)
            finally:
                if name == exhaust_after and not exhausted:
                    exhausted = True
                    remaining.return_value = REPORTER_OPERATION_SAFETY_MILLIS
        return guarded_call

    for name in ("put_item", "get_item", "update_item"):
        monkeypatch.setattr(setup.services.table, name, wrap_call(name, getattr(setup.services.table, name)))
    monkeypatch.setattr(setup.services.eventbridge, "put_events", wrap_call("put_events", publisher))
    records = [setup.record, dict(setup.record, messageId="message-2")]
    assert worker.process_reporter_event({"Records": records}, context, setup.services) == {
        "batchItemFailures": [{"itemIdentifier": "message-1"}, {"itemIdentifier": "message-2"}]
    }
    expected_calls = ["put_item", "get_item", "update_item", "put_events"]
    assert calls == expected_calls[:expected_calls.index(exhaust_after) + 1]
    assert stored_item(setup)["state"] == "COPIED"
    if exhaust_after in {"put_item", "get_item"}:
        assert stored_item(setup)["ownerToken"] == original_owner
    else:
        assert stored_item(setup)["ownerToken"] != original_owner
        assert stored_item(setup)["leaseUntil"] > 0
    assert [call.kwargs["name"] for call in metrics.add_metric.call_args_list] == [
        "ReporterRecordDeferred", "ReporterRecordDeferred",
    ]

    stored_item(setup)["leaseUntil"] = 0
    remaining.return_value = 60_000
    assert worker.process_reporter_event(
        {"Records": [setup.record]}, context, setup.services
    ) == {"batchItemFailures": []}
    assert stored_item(setup)["state"] == "SUCCEEDED"
    setup.transfer.assert_called_once()
    setup.services.clients_for_role.assert_called_once()
    assert publisher.call_count == (2 if exhaust_after == "put_events" else 1)
    details = [json.loads(call.kwargs["Entries"][0]["Detail"]) for call in publisher.call_args_list]
    assert all(detail == details[0] for detail in details)


@pytest.mark.parametrize("exhaust_after, expected_state", [("put_item", "IN_PROGRESS"), ("update_item", "FAILED")])
def test_reporter_deadline_preserves_failed_outcome_recovery(
    setup, monkeypatch, exhaust_after, expected_state
):
    metrics = Mock()
    monkeypatch.setattr(worker, "metrics", metrics)
    remaining = Mock(return_value=60_000)
    context = SimpleNamespace(get_remaining_time_in_millis=remaining)
    original = getattr(setup.services.table, exhaust_after)

    def exhaust_time(*args, **kwargs):
        result = original(*args, **kwargs)
        remaining.return_value = REPORTER_OPERATION_SAFETY_MILLIS
        return result

    monkeypatch.setattr(setup.services.table, exhaust_after, exhaust_time)
    assert worker.process_reporter_event(
        {"Records": [setup.record]}, context, setup.services
    ) == {"batchItemFailures": [{"itemIdentifier": "message-1"}]}
    assert stored_item(setup)["state"] == expected_state
    setup.services.eventbridge.put_events.assert_not_called()
    assert [call.kwargs["name"] for call in metrics.add_metric.call_args_list] == [
        "ReporterRecordDeferred",
    ]
    monkeypatch.setattr(setup.services.table, exhaust_after, original)
    remaining.return_value = 60_000
    stored_item(setup)["leaseUntil"] = 0
    assert worker.process_reporter_event(
        {"Records": [setup.record]}, context, setup.services
    ) == {"batchItemFailures": []}
    assert stored_item(setup)["state"] == "FAILED"
    setup.services.eventbridge.put_events.assert_called_once()
    setup.transfer.assert_not_called()
    assert any(call.kwargs["name"] == "DeliveryFailed" for call in metrics.add_metric.call_args_list)


def test_writer_checkpoints_the_upload_before_deferring_completion(setup, monkeypatch):
    remaining = Mock(return_value=900_000)
    context = SimpleNamespace(get_remaining_time_in_millis=remaining)
    metrics = Mock()
    monkeypatch.setattr(worker, "metrics", metrics)

    def uploaded(*_args):
        remaining.return_value = 75_000
        return 3

    setup.transfer.side_effect = uploaded
    original_update = setup.services.table.update_item

    def checkpoint(*args, **kwargs):
        result = original_update(*args, **kwargs)
        if ":copied" in kwargs["ExpressionAttributeValues"]:
            remaining.return_value = AWS_OPERATION_SAFETY_MILLIS
        return result

    monkeypatch.setattr(setup.services.table, "update_item", checkpoint)
    assert worker.process_writer_event(
        {"Records": [setup.record]}, context, setup.services
    ) == {"batchItemFailures": [{"itemIdentifier": "message-1"}]}
    assert stored_item(setup)["state"] == "COPIED"
    setup.services.eventbridge.put_events.assert_not_called()
    assert any(call.kwargs["name"] == "WriterRecordFailed" for call in metrics.add_metric.call_args_list)

    stored_item(setup)["leaseUntil"] = 0
    remaining.return_value = 900_000
    assert worker.process_writer_event(
        {"Records": [setup.record]}, context, setup.services
    ) == {"batchItemFailures": []}
    assert stored_item(setup)["state"] == "SUCCEEDED"
    setup.transfer.assert_called_once()
    setup.services.clients_for_role.assert_called_once()
    setup.services.eventbridge.put_events.assert_called_once()


@pytest.mark.parametrize("remaining, succeeds", [(REPORTER_OPERATION_SAFETY_MILLIS, False), (REPORTER_OPERATION_SAFETY_MILLIS + 1, True)])
def test_reporter_operation_boundary(setup, remaining, succeeds):
    context = SimpleNamespace(get_remaining_time_in_millis=lambda: remaining)
    if succeeds:
        assert worker.process_reporter_record(
            setup.record, setup.config, setup.services, context
        ) == "failed-reported"
    else:
        with pytest.raises(DeadlineExceeded):
            worker.process_reporter_record(setup.record, setup.config, setup.services, context)
        assert not setup.services.table.items
        setup.services.eventbridge.put_events.assert_not_called()