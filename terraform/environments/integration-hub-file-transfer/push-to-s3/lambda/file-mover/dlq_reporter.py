import json
from datetime import datetime, timezone

from file_mover import (
    TerminalFailure,
    completion_detail,
    parse_requested_action,
    publish_completion,
)

FAILURES = {
    "eventbridge": ("EVENTBRIDGE_DELIVERY_EXHAUSTED", "EventBridge could not deliver the action request"),
    "sns": ("SNS_DELIVERY_EXHAUSTED", "SNS could not deliver the action request"),
    "processing": ("PROCESSING_RETRIES_EXHAUSTED", "The action request exhausted processing retries"),
}


class DLQReporter:
    def __init__(self, outcomes, events, event_bus_name, queue_arns):
        self.outcomes = outcomes
        self.events = events
        self.event_bus_name = event_bus_name
        self.stages = {arn: stage for stage, arn in queue_arns.items()}
        if set(queue_arns) != set(FAILURES) or len(self.stages) != len(FAILURES):
            raise ValueError("Exactly one distinct queue ARN is required for each DLQ stage")

    def process(self, record):
        stage = self.stages[record["eventSourceARN"]]
        envelope = json.loads(record["body"])
        event = json.loads(envelope["Message"]) if stage != "eventbridge" else envelope
        request = parse_requested_action(event)
        item = self.outcomes.get(request)
        if item is None:
            code, message = FAILURES[stage]
            detail = completion_detail(
                request,
                "failed",
                datetime.now(timezone.utc),
                failure=TerminalFailure(code, message),
            )
            item = self.outcomes.record(request, detail)
        self.outcomes.publish(request, item, self._publish)

    def _publish(self, request, detail):
        publish_completion(self.events, self.event_bus_name, request, detail)

    def handle_batch(self, records):
        failures = []
        for record in records:
            try:
                self.process(record)
            except Exception:  # noqa: BLE001 - return every failed record to its DLQ
                failures.append({"itemIdentifier": record["messageId"]})
        return {"batchItemFailures": failures}