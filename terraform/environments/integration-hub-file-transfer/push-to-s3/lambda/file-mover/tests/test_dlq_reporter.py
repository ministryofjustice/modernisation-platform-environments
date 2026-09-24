import json

import pytest
from dlq_reporter import FAILURES, DLQReporter
from file_mover import completion_detail, parse_requested_action
from terminal_outcome import TerminalOutcomes
from test_file_mover import FakeEvents, mover, requested_event
from test_terminal_outcome import FakeTable

QUEUE_ARNS = {stage: f"arn:aws:sqs:eu-west-2:123456789012:{stage}-dlq" for stage in FAILURES}


def record(stage, event=None):
    body = event or requested_event()
    if stage != "eventbridge":
        body = {"Type": "Notification", "Message": json.dumps(body)}
    return {
        "messageId": "message-id",
        "eventSourceARN": QUEUE_ARNS[stage],
        "body": json.dumps(body),
    }


def reporter():
    table = FakeTable()
    events = FakeEvents()
    service = DLQReporter(TerminalOutcomes(table, 86400), events, "file-transfer", QUEUE_ARNS)
    return service, table, events


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


def test_previously_claimed_success_is_not_replaced_by_failure():
    service, table, events = reporter()
    request = parse_requested_action(requested_event())
    from datetime import datetime, timezone

    detail = completion_detail(request, "succeeded", datetime.now(timezone.utc), destination={"bucket": "out", "key": "file"})
    service.outcomes.record(request, detail)

    assert service.handle_batch([record("processing")]) == {"batchItemFailures": []}
    assert json.loads(events.calls[0]["Entries"][0]["Detail"])["data"]["status"] == "succeeded"
    assert table.items[f"terminal:{request.action_execution_id}"]["published"] is True


def test_unparseable_message_remains_in_dlq():
    service, _, events = reporter()
    invalid = record("sns")
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