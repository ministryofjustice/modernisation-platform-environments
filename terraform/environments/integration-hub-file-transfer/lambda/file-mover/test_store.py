import unittest
from types import SimpleNamespace
from unittest.mock import MagicMock

from mft_file_mover.store import OperationStore


class ConditionalFailure(Exception):
    response = {"Error": {"Code": "ConditionalCheckFailedException"}}


class OperationStoreTest(unittest.TestCase):
    def setUp(self):
        self.table = MagicMock()
        self.store = OperationStore(self.table, clock=lambda: 100)
        self.event = SimpleNamespace(
            correlation_id="correlation-id",
            event_id="event-id",
            file_id="file-id",
            source_bucket="incoming",
            source_key="example/report.csv",
            source_version_id="source-version",
            source_size_bytes=10,
            scan_result_status=None,
            scan_result_status_matches_tag=None,
        )
        self.existing_input = {
            "file_id": "file-id",
            "correlation_id": "correlation-id",
            "source_bucket": "incoming",
            "source_key": "example/report.csv",
            "source_version_id": "source-version",
            "source_size_bytes": 10,
        }

    def test_claims_a_new_operation(self):
        claim = self.store.claim(self.event, "STAGE", "request-1", 900, 3600)

        self.assertEqual(claim.state, "CLAIMED")
        self.assertEqual(claim.item["status"], "IN_PROGRESS")
        self.assertEqual(claim.item["expiration"], 3700)

    def test_reports_an_active_operation(self):
        self.table.put_item.side_effect = ConditionalFailure()
        self.table.get_item.return_value = {
            "Item": {
                **self.existing_input,
                "concurrencyId": "correlation-id",
                "operation": "STAGE",
                "status": "COPIED",
                "owner": "request-1",
                "lease_expires_at": 101,
            }
        }

        claim = self.store.claim(self.event, "STAGE", "request-2", 900, 3600)

        self.assertEqual(claim.state, "ACTIVE")
        self.table.update_item.assert_not_called()

    def test_takes_over_an_expired_operation_without_losing_its_checkpoint(self):
        self.table.put_item.side_effect = ConditionalFailure()
        existing = {
            **self.existing_input,
            "concurrencyId": "correlation-id",
            "operation": "STAGE",
            "status": "SOURCE_DELETED",
            "owner": "request-1",
            "lease_expires_at": 99,
        }
        self.table.get_item.return_value = {"Item": existing}
        self.table.update_item.return_value = {
            "Attributes": {**existing, "owner": "request-2", "lease_expires_at": 900}
        }

        claim = self.store.claim(self.event, "STAGE", "request-2", 900, 3600)

        self.assertEqual(claim.state, "RESUMED")
        self.assertEqual(claim.item["status"], "SOURCE_DELETED")

    def test_returns_a_completed_result_without_taking_ownership(self):
        self.table.put_item.side_effect = ConditionalFailure()
        self.table.get_item.return_value = {
            "Item": {
                **self.existing_input,
                "concurrencyId": "correlation-id",
                "operation": "STAGE",
                "status": "COMPLETED",
                "owner": "request-1",
            }
        }

        claim = self.store.claim(self.event, "STAGE", "request-2", 900, 3600)

        self.assertEqual(claim.state, "COMPLETED")

    def test_rejects_an_existing_claim_for_conflicting_immutable_input(self):
        self.table.put_item.side_effect = ConditionalFailure()
        self.table.get_item.return_value = {
            "Item": {
                "concurrencyId": "correlation-id",
                "operation": "STAGE",
                "status": "COMPLETED",
                "owner": "request-1",
                "file_id": "file-id",
                "correlation_id": "correlation-id",
                "source_bucket": "incoming",
                "source_key": "different.csv",
                "source_version_id": "source-version",
                "source_size_bytes": 10,
            }
        }

        with self.assertRaisesRegex(RuntimeError, "source_key"):
            self.store.claim(self.event, "STAGE", "request-2", 900, 3600)


if __name__ == "__main__":
    unittest.main()