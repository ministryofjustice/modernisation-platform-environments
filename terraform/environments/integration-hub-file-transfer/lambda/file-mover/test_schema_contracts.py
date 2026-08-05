import json
import unittest
from pathlib import Path
from types import SimpleNamespace

from jsonschema import Draft4Validator, FormatChecker

from mft_file_mover.config import Destination
from mft_file_mover.service import EVENT_SOURCE, FileMoverService


SCHEMA_DIRECTORY = Path(__file__).parents[2] / "schemas"


class CompletionEventSchemaTest(unittest.TestCase):
    def test_stage_completion_event_matches_its_schema(self):
        service = self._service("STAGE")
        item = self._item(
            destination_bucket="processing",
            destination_version_id="destination-version",
        )

        detail, detail_type, _ = service._completion_event(item)

        self._validate(detail_type, detail)

    def test_route_completion_events_match_all_schema_branches(self):
        cases = [
            ("clean", "NO_THREATS_FOUND", True),
            ("quarantine", "THREATS_FOUND", True),
            ("investigation", "FAILED", True),
            ("investigation", "NO_THREATS_FOUND", False),
        ]
        service = self._service("ROUTE")
        for route, status, matches_tag in cases:
            with self.subTest(route=route, status=status, matches_tag=matches_tag):
                item = self._item(
                    operation="ROUTE",
                    source_bucket="processing",
                    destination_bucket=route,
                    destination_version_id=f"{route}-version",
                    route=route,
                    scan_result_status=status,
                    scan_result_status_matches_tag=matches_tag,
                )

                detail, detail_type, _ = service._completion_event(item)

                self._validate(detail_type, detail)

    def _validate(self, detail_type, detail):
        schema = json.loads((SCHEMA_DIRECTORY / f"{detail_type}.json").read_text())
        envelope = {
            "version": "0",
            "id": "6dce6b40-6e43-49f0-a2cf-1da1d43bce22",
            "detail-type": detail_type,
            "source": EVENT_SOURCE,
            "account": "123456789012",
            "time": "2026-07-10T14:01:00Z",
            "region": "eu-west-2",
            "resources": ["arn:aws:s3:::destination/example/report.csv"],
            "detail": detail,
        }
        Draft4Validator(schema, format_checker=FormatChecker()).validate(envelope)

    @staticmethod
    def _item(**overrides):
        return {
            "concurrencyId": "7d9f4e4c-0e0f-4a5b-8b4e-4ab1f28fd1d1",
            "operation": "STAGE",
            "status": "SOURCE_DELETED",
            "event_id": "c5dc9cb4-3b1f-4f01-a4c6-41b30e11d790",
            "file_id": "3f4e3d7a-4e2f-4bc2-9c4e-5f1ef2d4c501",
            "correlation_id": "7d9f4e4c-0e0f-4a5b-8b4e-4ab1f28fd1d1",
            "source_bucket": "incoming",
            "source_key": "example/report.csv",
            "source_version_id": "source-version",
            "source_size_bytes": 12,
            **overrides,
        }

    @staticmethod
    def _service(operation):
        return FileMoverService(
            operation,
            SimpleNamespace(
                destinations={
                    name: Destination(name, f"{name}-kms-key")
                    for name in [
                        "processing",
                        "clean",
                        "quarantine",
                        "investigation",
                    ]
                }
            ),
            None,
            None,
            None,
            None,
        )


if __name__ == "__main__":
    unittest.main()