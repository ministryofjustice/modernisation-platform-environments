import json
import unittest
from decimal import Decimal
from types import SimpleNamespace
from unittest.mock import MagicMock

from mft_file_mover.config import Destination
from mft_file_mover.service import FileMoverService


class FileMoverServiceTest(unittest.TestCase):
    def setUp(self):
        self.event = {
            "id": "trigger-event-id",
            "account": "123456789012",
            "source": "uk.gov.justice.service.managed-file-transfer",
            "detail-type": "FileReceived.v1",
            "detail": {
                "metadata": {"correlationId": "correlation-id"},
                "data": {
                    "fileId": "file-id",
                    "object": {
                        "bucket": "incoming",
                        "key": "example/report.csv",
                        "versionId": "source-version",
                        "sizeBytes": 12,
                    },
                },
            },
        }
        self.context = SimpleNamespace(
            aws_request_id="request-id",
            get_remaining_time_in_millis=lambda: 100_000,
        )
        self.store = MagicMock()
        self.store.update_fields.side_effect = self._update_fields
        self.store.transition.side_effect = self._transition
        self.copy_engine = MagicMock()
        self.copy_engine.copy_token.return_value = "copy-token"
        self.eventbridge = MagicMock()
        self.eventbridge.put_events.return_value = {
            "FailedEntryCount": 0,
            "Entries": [{"EventId": "completion-event-id"}],
        }
        self.base_item = {
            "concurrencyId": "correlation-id",
            "operation": "STAGE",
            "status": "IN_PROGRESS",
            "owner": "request-id",
            "event_id": "trigger-event-id",
            "file_id": "file-id",
            "correlation_id": "correlation-id",
            "source_bucket": "incoming",
            "source_key": "example/report.csv",
            "source_version_id": "source-version",
            "source_size_bytes": 12,
        }

    def test_published_stage_resume_completes_without_accessing_s3(self):
        item = {
            **self.base_item,
            "status": "PUBLISHED",
            "destination_bucket": "processing",
            "destination_version_id": "destination-version",
            "output_event_id": "completion-event-id",
        }
        self.store.claim.return_value = SimpleNamespace(state="RESUMED", item=item)
        service = self._stage_service()

        result = service.handle(self.event, self.context)

        self.assertEqual(
            result, {"status": "COMPLETED", "eventId": "completion-event-id"}
        )
        self.copy_engine.inspect_source.assert_not_called()
        completed_fields = self.store.transition.call_args.args[4]
        self.assertEqual(completed_fields["processing_version_id"], "destination-version")
        self.assertEqual(completed_fields["staged_event_id"], "completion-event-id")

    def test_route_uses_the_event_status_and_preserves_the_tag_match_flag(self):
        route_event = {
            **self.event,
            "detail-type": "FileScanResultRecorded.v1",
            "detail": {
                "metadata": {"correlationId": "correlation-id"},
                "data": {
                    **self.event["detail"]["data"],
                    "object": {
                        **self.event["detail"]["data"]["object"],
                        "bucket": "processing",
                    },
                    "scanResultStatus": "NO_THREATS_FOUND",
                    "scanResultStatusMatchesTag": False,
                },
            },
        }
        item = {
            **self.base_item,
            "operation": "ROUTE",
            "source_bucket": "processing",
            "scan_result_status": "NO_THREATS_FOUND",
            "scan_result_status_matches_tag": False,
        }
        self.store.claim.return_value = SimpleNamespace(state="CLAIMED", item=item)
        snapshot = SimpleNamespace(
            tags=[
                {
                    "Key": "GuardDutyMalwareScanStatus",
                    "Value": "NO_THREATS_FOUND",
                }
            ]
        )
        self.copy_engine.inspect_source.return_value = snapshot
        self.copy_engine.copy.side_effect = lambda item, *_args: {
            **item,
            "status": "COPIED",
            "destination_bucket": "clean",
            "destination_version_id": "clean-version",
            "copy_token": "copy-token",
        }
        service = self._route_service()

        result = service.handle(route_event, self.context)

        self.assertEqual(result["status"], "COMPLETED")
        published = json.loads(
            self.eventbridge.put_events.call_args.kwargs["Entries"][0]["Detail"]
        )
        self.assertEqual(published["data"]["route"], "clean")
        self.assertFalse(published["data"]["scanResultStatusMatchesTag"])
        self.copy_engine.delete_source.assert_called_once()

    def test_enabled_stage_receipt_is_created_after_source_deletion(self):
        item = {
            **self.base_item,
            "status": "SOURCE_DELETED",
            "destination_bucket": "processing",
            "destination_version_id": "destination-version",
        }
        self.store.claim.return_value = SimpleNamespace(state="RESUMED", item=item)
        self.copy_engine.create_receipt.return_value = (
            "example/report.csv.receipt",
            "receipt-version",
            "receipt-token",
        )
        service = self._stage_service(receipt_enabled=True)

        service.handle(self.event, self.context)

        self.copy_engine.inspect_source.assert_not_called()
        self.copy_engine.create_receipt.assert_called_once_with(item, "incoming-kms-key")
        receipt_transition = self.store.transition.call_args_list[0]
        self.assertEqual(receipt_transition.args[3], "RECEIPT_CREATED")

    def test_verified_resume_deletes_without_reading_the_source(self):
        item = {
            **self.base_item,
            "status": "VERIFIED",
            "destination_bucket": "processing",
            "destination_version_id": "destination-version",
        }
        self.store.claim.return_value = SimpleNamespace(state="RESUMED", item=item)
        service = self._stage_service()

        result = service.handle(self.event, self.context)

        self.assertEqual(result["status"], "COMPLETED")
        self.copy_engine.inspect_source.assert_not_called()
        self.copy_engine.delete_source.assert_called_once_with(item)

    def test_publication_failure_preserves_the_source_deleted_checkpoint(self):
        item = {
            **self.base_item,
            "status": "SOURCE_DELETED",
            "destination_bucket": "processing",
            "destination_version_id": "destination-version",
        }
        self.store.claim.return_value = SimpleNamespace(state="RESUMED", item=item)
        self.eventbridge.put_events.return_value = {
            "FailedEntryCount": 1,
            "Entries": [{"ErrorCode": "InternalFailure"}],
        }
        service = self._stage_service()

        with self.assertRaisesRegex(RuntimeError, "Failed to publish"):
            service.handle(self.event, self.context)

        self.copy_engine.inspect_source.assert_not_called()
        self.copy_engine.delete_source.assert_not_called()
        published_transitions = [
            call for call in self.store.transition.call_args_list if call.args[3] == "PUBLISHED"
        ]
        self.assertEqual(published_transitions, [])

    def test_publish_serializes_integral_dynamodb_decimals_as_json_integers(self):
        service = self._stage_service()
        item = {
            **self.base_item,
            "destination_bucket": "processing",
            "output_detail_type": "FileStagedForScanning.v1",
            "output_detail": {
                "data": {
                    "sourceObject": {"sizeBytes": Decimal("12")},
                    "stagedObject": {"sizeBytes": Decimal("12")},
                }
            },
        }

        service._publish(item)

        detail = json.loads(
            self.eventbridge.put_events.call_args.kwargs["Entries"][0]["Detail"]
        )
        self.assertEqual(detail["data"]["sourceObject"]["sizeBytes"], 12)
        self.assertIsInstance(detail["data"]["sourceObject"]["sizeBytes"], int)

    def test_publish_rejects_a_fractional_dynamodb_decimal(self):
        service = self._stage_service()
        item = {
            **self.base_item,
            "destination_bucket": "processing",
            "output_detail_type": "FileStagedForScanning.v1",
            "output_detail": {"data": {"sourceObject": {"sizeBytes": Decimal("1.5")}}},
        }

        with self.assertRaisesRegex(TypeError, "Decimal is not JSON serializable"):
            service._publish(item)

    def _stage_service(self, receipt_enabled=False):
        config = SimpleNamespace(
            account_id="123456789012",
            source_bucket="incoming",
            destinations={"processing": Destination("processing", "processing-kms-key")},
            event_bus_arn="event-bus-arn",
            idempotency_expiry_seconds=3600,
            receipt_enabled=receipt_enabled,
            receipt_kms_key_arn="incoming-kms-key",
        )
        return FileMoverService(
            "STAGE", config, self.store, self.copy_engine, self.eventbridge, MagicMock()
        )

    def _route_service(self):
        config = SimpleNamespace(
            account_id="123456789012",
            source_bucket="processing",
            destinations={
                route: Destination(route, f"{route}-kms-key")
                for route in ["clean", "quarantine", "investigation"]
            },
            event_bus_arn="event-bus-arn",
            idempotency_expiry_seconds=3600,
            receipt_enabled=False,
        )
        return FileMoverService(
            "ROUTE", config, self.store, self.copy_engine, self.eventbridge, MagicMock()
        )

    @staticmethod
    def _update_fields(item, _owner, fields):
        return {**item, **fields}

    @staticmethod
    def _transition(item, _owner, _expected, status, fields=None, remove=None):
        result = {**item, "status": status, **(fields or {})}
        for name in remove or []:
            result.pop(name, None)
        return result


if __name__ == "__main__":
    unittest.main()