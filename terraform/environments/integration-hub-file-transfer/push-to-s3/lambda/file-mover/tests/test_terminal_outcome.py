import json
from datetime import datetime, timezone

import pytest
from botocore.exceptions import ClientError
from file_mover import TerminalFailure, completion_detail, parse_requested_action
from terminal_outcome import TerminalOutcomes
from test_file_mover import requested_event


class FakeTable:
    def __init__(self):
        self.items = {}

    def get_item(self, Key, ConsistentRead):
        assert ConsistentRead is True
        return {"Item": self.items[Key["id"]]} if Key["id"] in self.items else {}

    def put_item(self, Item, ConditionExpression):
        assert ConditionExpression == "attribute_not_exists(id)"
        if Item["id"] in self.items:
            raise ClientError(
                {"Error": {"Code": "ConditionalCheckFailedException"}}, "PutItem"
            )
        self.items[Item["id"]] = Item

    def update_item(self, Key, UpdateExpression, ConditionExpression, ExpressionAttributeNames, ExpressionAttributeValues):
        assert UpdateExpression == "SET #published = :published"
        assert ExpressionAttributeNames == {"#published": "published"}
        assert ConditionExpression == "attribute_exists(id) AND envelopeId = :envelopeId"
        assert self.items[Key["id"]]["envelopeId"] == ExpressionAttributeValues[":envelopeId"]
        self.items[Key["id"]]["published"] = ExpressionAttributeValues[":published"]


def test_competing_claim_reuses_first_status():
    table = FakeTable()
    outcomes = TerminalOutcomes(table, 86400)
    request = parse_requested_action(requested_event())
    failed = completion_detail(request, "failed", datetime.now(timezone.utc), failure=TerminalFailure("RETRIES_EXHAUSTED", "The request failed"))
    succeeded = completion_detail(request, "succeeded", datetime.now(timezone.utc))

    first = outcomes.record(request, failed)
    second = outcomes.record(request, succeeded)

    assert first["detail"] == second["detail"]
    assert json.loads(second["detail"])["data"]["status"] == "failed"


def test_publish_failure_retries_stored_detail_without_new_claim():
    table = FakeTable()
    outcomes = TerminalOutcomes(table, 86400)
    request = parse_requested_action(requested_event())
    detail = completion_detail(request, "succeeded", datetime.now(timezone.utc))
    item = outcomes.record(request, detail)
    calls = []

    def publish(_, payload):
        calls.append(payload)
        if len(calls) == 1:
            raise RuntimeError("temporary event bus failure")

    with pytest.raises(RuntimeError, match="temporary"):
        outcomes.publish(request, item, publish)
    assert outcomes.get(request).get("published") is None
    outcomes.publish(request, outcomes.get(request), publish)
    outcomes.publish(request, outcomes.get(request), publish)
    assert calls == [detail, detail]


def test_rejects_reused_execution_id_for_another_envelope():
    outcomes = TerminalOutcomes(FakeTable(), 86400)
    request = parse_requested_action(requested_event())
    detail = completion_detail(request, "succeeded", datetime.now(timezone.utc))
    outcomes.record(request, detail)
    other_event = requested_event()
    other_event["id"] = "another-event"

    with pytest.raises(ValueError, match="reused"):
        outcomes.get(parse_requested_action(other_event))