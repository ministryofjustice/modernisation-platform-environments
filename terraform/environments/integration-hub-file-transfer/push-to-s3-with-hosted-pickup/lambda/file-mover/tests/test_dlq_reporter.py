import json
from datetime import datetime, timezone

import pytest
from botocore.exceptions import ClientError
from dlq_reporter import FAILURES, DLQReporter
from file_mover import completion_detail, parse_requested_action
from terminal_outcome import TerminalOutcomes
from test_file_mover import FakeEvents, mover, requested_event

QUEUE_ARNS = {stage: f"arn:aws:sqs:eu-west-2:123456789012:{stage}-dlq" for stage in FAILURES}


class FakeTable:
    def __init__(self):
        self.items = {}

    def get_item(self, Key, ConsistentRead):
        assert ConsistentRead is True
        return {"Item": self.items[Key["id"]]} if Key["id"] in self.items else {}

    def put_item(self, Item, ConditionExpression):
        assert ConditionExpression == "attribute_not_exists(id)"
        if Item["id"] in self.items:
            raise ClientError({"Error": {"Code": "ConditionalCheckFailedException"}}, "PutItem")
        self.items[Item["id"]] = Item

    def update_item(self, Key, UpdateExpression, ConditionExpression, ExpressionAttributeNames, ExpressionAttributeValues):
        assert UpdateExpression == "SET #published = :published"
        assert ExpressionAttributeNames == {"#published": "published"}
        assert ConditionExpression == "attribute_exists(id) AND envelopeId = :envelopeId"
        assert self.items[Key["id"]]["envelopeId"] == ExpressionAttributeValues[":envelopeId"]
        self.items[Key["id"]]["published"] = ExpressionAttributeValues[":published"]


def record(stage):
    event = requested_event()
    body = event if stage == "eventbridge" else {"Type": "Notification", "Message": json.dumps(event)}
    return {"messageId": "message-id", "eventSourceARN": QUEUE_ARNS[stage], "body": json.dumps(body)}


def reporter():
    table = FakeTable()
    events = FakeEvents()
    return DLQReporter(TerminalOutcomes(table, 86400), events, "file-transfer", QUEUE_ARNS), table, events


@pytest.mark.parametrize("stage", list(FAILURES))
def test_dlq_stage_emits_one_non_retryable_failure(stage):
    service, table, events = reporter()

    assert service.handle_batch([record(stage), record(stage)]) == {"batchItemFailures": []}
    assert len(events.calls) == 1
    detail = json.loads(events.calls[0]["Entries"][0]["Detail"])
    assert detail["data"]["failure"] == {
        "code": FAILURES[stage][0],
        "message": FAILURES[stage][1],
        "retryable": False,
    }
    assert detail["data"]["object"]["versionId"] == "source-version"
    assert table.items[f"terminal:{detail['data']['actionExecutionId']}"]["published"] is True


def test_reporter_preserves_claimed_success():
    service, table, events = reporter()
    request = parse_requested_action(requested_event())
    detail = completion_detail(request, "succeeded", datetime.now(timezone.utc), destination={"bucket": "hosted", "key": "file"})
    service.outcomes.record(request, detail)

    assert service.handle_batch([record("processing")]) == {"batchItemFailures": []}
    assert json.loads(events.calls[0]["Entries"][0]["Detail"])["data"]["status"] == "succeeded"
    assert table.items[f"terminal:{request.action_execution_id}"]["published"] is True


def test_malformed_message_remains_in_dlq():
    service, _, events = reporter()
    invalid = record("eventbridge")
    invalid["body"] = "not-json"

    assert service.handle_batch([invalid]) == {"batchItemFailures": [{"itemIdentifier": "message-id"}]}
    assert events.calls == []


def test_failed_terminal_claim_stops_late_mover_copy():
    service, _, reporter_events = reporter()
    assert service.handle_batch([record("processing")]) == {"batchItemFailures": []}
    file_mover, destination, mover_events, role_calls = mover()
    file_mover.outcomes = service.outcomes

    assert file_mover.process(requested_event()) == "failed"
    assert destination.calls == []
    assert role_calls == []
    assert mover_events.calls == []
    assert len(reporter_events.calls) == 1


def test_outcome_conflict_preserves_first_failure_and_retries_publish():
    service, table, events = reporter()
    request = parse_requested_action(requested_event())
    first = service.outcomes.record(request, completion_detail(request, "failed", datetime.now(timezone.utc)))
    other = service.outcomes.record(request, completion_detail(request, "succeeded", datetime.now(timezone.utc)))
    assert first["detail"] == other["detail"]
    calls = []

    def publish(_, detail):
        calls.append(detail)
        if len(calls) == 1:
            raise RuntimeError("temporary publish failure")

    with pytest.raises(RuntimeError, match="temporary"):
        service.outcomes.publish(request, first, publish)
    assert service.outcomes.get(request).get("published") is None
    service.outcomes.publish(request, service.outcomes.get(request), publish)
    assert len(calls) == 2
    assert table.items[first["id"]]["published"] is True
    assert events.calls == []