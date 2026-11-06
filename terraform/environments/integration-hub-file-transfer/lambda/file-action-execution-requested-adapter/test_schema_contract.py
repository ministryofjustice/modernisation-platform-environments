import json
import unittest
from datetime import datetime, timezone
from pathlib import Path

from jsonschema import Draft4Validator, FormatChecker

from dispatcher import (
    DispatchConfiguration,
    build_requested_event_detail,
    parse_file_routed_event,
)


SCHEMA_PATH = Path(__file__).parents[2] / "schemas" / "FileActionExecutionRequested.v1.json"


class RequestedEventSchemaContractTest(unittest.TestCase):
    def test_generated_event_matches_schema(self):
        source_event = {
            "id": "aa88e95a-159c-40c1-9e7b-38d00b0b6169",
            "detail-type": "FileRouted.v1",
            "source": "uk.gov.justice.service.managed-file-transfer",
            "account": "123456789012",
            "detail": {
                "metadata": {
                    "correlationId": "7d9f4e4c-0e0f-4a5b-8b4e-4ab1f28fd1d1",
                    "idempotencyKey": "route:clean:clean:identity/report.csv:version",
                },
                "data": {
                    "fileId": "3f4e3d7a-4e2f-4bc2-9c4e-5f1ef2d4c501",
                    "route": "clean",
                    "destinationObject": {
                        "bucket": "clean",
                        "key": "identity/report.csv",
                        "versionId": "version",
                        "sizeBytes": 4096,
                    },
                },
            },
        }
        routed_file = parse_file_routed_event(source_event)
        configuration = DispatchConfiguration(
            secret_arn=(
                "arn:aws:secretsmanager:eu-west-2:123456789012:"
                "secret:integration-hub-file-transfer/file-dispatch/identity-AbCdEf"
            ),
            secret_version_id="EXAMPLE1-90ab-cdef-fedc-ba9876543210",
            action_name="place-on-sqs",
            notifications=("email",),
        )
        detail = build_requested_event_detail(
            routed_file,
            configuration,
            requested_at=datetime(2026, 8, 19, 12, 30, tzinfo=timezone.utc),
        )
        envelope = {
            "version": "0",
            "id": "2bd32cbb-c3e2-4b62-8b53-90ea0a7a4de5",
            "detail-type": "FileActionExecutionRequested.v1",
            "source": "uk.gov.justice.service.managed-file-transfer",
            "account": "123456789012",
            "time": "2026-08-19T12:30:00Z",
            "region": "eu-west-2",
            "resources": ["arn:aws:s3:::clean/identity/report.csv"],
            "detail": detail,
        }
        schema = json.loads(SCHEMA_PATH.read_text())

        Draft4Validator.check_schema(schema)
        Draft4Validator(schema, format_checker=FormatChecker()).validate(envelope)


if __name__ == "__main__":
    unittest.main()