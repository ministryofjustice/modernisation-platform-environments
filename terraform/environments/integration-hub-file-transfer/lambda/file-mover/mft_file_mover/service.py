import json
import time
from decimal import Decimal

from mft_file_mover.events import EVENT_SOURCE, parse_file_mover_event
from mft_file_mover.model import select_route


class OperationInProgress(RuntimeError):
    pass


class FileMoverService:
    def __init__(self, operation, config, store, copy_engine, eventbridge, logger):
        self.operation = operation
        self.config = config
        self.store = store
        self.copy_engine = copy_engine
        self.eventbridge = eventbridge
        self.logger = logger

    def handle(self, event, context):
        operation_event = parse_file_mover_event(
            event,
            self.operation,
            self.config.account_id,
            self.config.source_bucket,
        )
        owner = context.aws_request_id
        lease_expires_at = int(time.time()) + max(
            1, (context.get_remaining_time_in_millis() + 999) // 1000
        )
        claim = self.store.claim(
            operation_event,
            self.operation,
            owner,
            lease_expires_at,
            self.config.idempotency_expiry_seconds,
        )
        if claim.state == "COMPLETED":
            return self._result(claim.item)
        if claim.state == "ACTIVE":
            raise OperationInProgress(
                f"{self.operation} is already active for this correlation ID"
            )

        item = claim.item
        try:
            item = self._run(operation_event, item, owner)
            return self._result(item)
        except Exception:
            try:
                self.store.release(item, owner)
            except Exception:
                self.logger.exception(
                    "Failed to release operation lease",
                    extra={
                        "operation": self.operation,
                        "correlation_id": operation_event.correlation_id,
                    },
                )
            raise

    def _run(self, operation_event, item, owner):
        if item["status"] == "PUBLISHED":
            return self._complete(item, owner)

        snapshot = None
        if item["status"] not in {"VERIFIED", "SOURCE_DELETED", "RECEIPT_CREATED"}:
            snapshot = self.copy_engine.inspect_source(operation_event, self.operation)
            if self.operation == "STAGE" and self.copy_engine.is_receipt(
                operation_event, snapshot
            ):
                return self.store.transition(
                    item,
                    owner,
                    [item["status"]],
                    "COMPLETED",
                    {"ignored_receipt": True},
                )

        destination, item = self._destination(operation_event, item, owner)
        token = self.copy_engine.copy_token(
            operation_event, self.operation, destination.bucket
        )
        if item["status"] in {
            "IN_PROGRESS",
            "MULTIPART_CREATED",
            "MULTIPART_ABORTED",
        }:
            item = self.copy_engine.copy(
                item,
                owner,
                self.store,
                snapshot,
                destination,
                token,
                self.operation,
            )
        if item["status"] == "COPIED":
            self.copy_engine.verify(item, snapshot, destination, self.operation)
            item = self.store.transition(item, owner, ["COPIED"], "VERIFIED")
        if item["status"] == "VERIFIED":
            self.copy_engine.delete_source(item)
            item = self.store.transition(item, owner, ["VERIFIED"], "SOURCE_DELETED")
        if (
            self.operation == "STAGE"
            and self.config.receipt_enabled
            and item["status"] == "SOURCE_DELETED"
        ):
            receipt_key, receipt_version_id, receipt_token = (
                self.copy_engine.create_receipt(item, self.config.receipt_kms_key_arn)
            )
            item = self.store.transition(
                item,
                owner,
                ["SOURCE_DELETED"],
                "RECEIPT_CREATED",
                {
                    "receipt_key": receipt_key,
                    "receipt_version_id": receipt_version_id,
                    "receipt_token": receipt_token,
                },
            )
        if item["status"] in {"SOURCE_DELETED", "RECEIPT_CREATED"}:
            detail, detail_type, idempotency_key = self._completion_event(item)
            item = self.store.update_fields(
                item,
                owner,
                {
                    "output_detail": detail,
                    "output_detail_type": detail_type,
                    "output_idempotency_key": idempotency_key,
                },
            )
            event_id = self._publish(item)
            item = self.store.transition(
                item,
                owner,
                [item["status"]],
                "PUBLISHED",
                {"output_event_id": event_id},
            )
        if item["status"] == "PUBLISHED":
            item = self._complete(item, owner)
        return item

    def _destination(self, operation_event, item, owner):
        if self.operation == "STAGE":
            return self.config.destinations["processing"], item
        if "route" in item:
            return self.config.destinations[item["route"]], item
        route = select_route(operation_event.scan_result_status)
        item = self.store.update_fields(
            item,
            owner,
            {"route": route},
        )
        return self.config.destinations[route], item

    def _completion_event(self, item):
        source_object = {
            "bucket": item["source_bucket"],
            "key": item["source_key"],
            "versionId": item["source_version_id"],
            "sizeBytes": item["source_size_bytes"],
        }
        destination_object = {
            "bucket": item["destination_bucket"],
            "key": item["source_key"],
            "versionId": item["destination_version_id"],
            "sizeBytes": item["source_size_bytes"],
        }
        if self.operation == "STAGE":
            idempotency_key = (
                f"{item['destination_bucket']}:{item['source_key']}:"
                f"{item['destination_version_id']}"
            )
            detail_type = "FileStagedForScanning.v1"
            data = {
                "fileId": item["file_id"],
                "sourceObject": source_object,
                "stagedObject": destination_object,
                "metadataPreserved": True,
                "tagsPreserved": True,
                "sourceDeleted": True,
            }
        else:
            idempotency_key = (
                f"route:{item['route']}:{item['destination_bucket']}:"
                f"{item['source_key']}:{item['destination_version_id']}"
            )
            detail_type = "FileRouted.v1"
            data = {
                "fileId": item["file_id"],
                "sourceObject": source_object,
                "destinationObject": destination_object,
                "route": item["route"],
                "scanResultStatus": item["scan_result_status"],
                "scanResultStatusMatchesTag": item[
                    "scan_result_status_matches_tag"
                ],
                "sourceDeleted": True,
            }
        return (
            {
                "metadata": {
                    "correlationId": item["correlation_id"],
                    "causationId": item["event_id"],
                    "idempotencyKey": idempotency_key,
                },
                "data": data,
            },
            detail_type,
            idempotency_key,
        )

    def _publish(self, item):
        response = self.eventbridge.put_events(
            Entries=[
                {
                    "Source": EVENT_SOURCE,
                    "DetailType": item["output_detail_type"],
                    "Detail": json.dumps(
                        item["output_detail"],
                        default=_event_detail_json_default,
                        separators=(",", ":"),
                    ),
                    "EventBusName": self.config.event_bus_arn,
                    "Resources": [
                        f"arn:aws:s3:::{item['destination_bucket']}/{item['source_key']}"
                    ],
                }
            ]
        )
        if response.get("FailedEntryCount", 0) > 0:
            raise RuntimeError(f"Failed to publish completion event: {response['Entries']}")
        event_id = response.get("Entries", [{}])[0].get("EventId")
        if not event_id:
            raise RuntimeError("EventBridge did not return a completion event ID")
        return event_id

    def _complete(self, item, owner):
        fields = {}
        if self.operation == "STAGE":
            fields = {
                "incoming_size_bytes": item["source_size_bytes"],
                "processing_bucket": item["destination_bucket"],
                "processing_key": item["source_key"],
                "processing_version_id": item["destination_version_id"],
                "staged_event_id": item["output_event_id"],
            }
        return self.store.transition(item, owner, ["PUBLISHED"], "COMPLETED", fields)

    @staticmethod
    def _result(item):
        result = {"status": item["status"]}
        if "output_event_id" in item:
            result["eventId"] = item["output_event_id"]
        if item.get("ignored_receipt"):
            result["ignoredReceipt"] = True
        return result


def _event_detail_json_default(value):
    if isinstance(value, Decimal) and value == value.to_integral_value():
        return int(value)
    raise TypeError(f"Object of type {value.__class__.__name__} is not JSON serializable")