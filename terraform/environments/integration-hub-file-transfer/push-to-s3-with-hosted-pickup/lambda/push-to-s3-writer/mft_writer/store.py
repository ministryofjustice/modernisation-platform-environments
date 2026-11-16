import uuid
from collections.abc import Mapping
from typing import Any

from botocore.exceptions import ClientError

from mft_writer.errors import InvalidMessage


def _conditional_failure(error: Exception) -> bool:
    return (
        isinstance(error, ClientError)
        and error.response.get("Error", {}).get("Code") == "ConditionalCheckFailedException"
    )


class ActionStore:
    """Atomic action claims and durable copy/terminal markers in the shared table."""

    def __init__(self, table: Any):
        self.table = table

    def get(self, action_id: str) -> dict[str, Any] | None:
        return self.table.get_item(Key={"id": action_id}, ConsistentRead=True).get("Item")

    def claim(
        self,
        item: Mapping[str, Any],
        *,
        now: int,
        lease_seconds: int,
        idempotency_seconds: int,
        terminal_seconds: int,
        allow_expired: bool = False,
    ) -> tuple[str, dict[str, Any] | None, str | None]:
        owner_token = str(uuid.uuid4())
        new_item = dict(item)
        new_item.update(
            {
                "state": "IN_PROGRESS",
                "ownerToken": owner_token,
                "leaseUntil": now + lease_seconds,
                "deduplicationExpiresAt": now + idempotency_seconds,
                "expiration": now + idempotency_seconds,
            }
        )
        try:
            self.table.put_item(Item=new_item, ConditionExpression="attribute_not_exists(id)")
            return "claimed", new_item, owner_token
        except Exception as error:
            if not _conditional_failure(error):
                raise

        existing = self.get(new_item["id"])
        if existing is None:
            raise RuntimeError("action claim changed during contention; retry the record")
        if existing.get("fingerprint") != item["fingerprint"]:
            raise InvalidMessage("action execution ID is already bound to different file details")
        state = existing.get("state")
        if state in {"SUCCEEDED", "FAILED"}:
            return "terminal", existing, None
        if state not in {"IN_PROGRESS", "COPIED"}:
            raise InvalidMessage("stored action state is invalid")
        expired_in_progress = (
            state == "IN_PROGRESS"
            and int(existing.get("deduplicationExpiresAt", existing.get("expiration", 0))) <= now
        )
        if expired_in_progress and not allow_expired:
            return "expired", existing, None
        if int(existing.get("leaseUntil", 0)) > now:
            return "active", existing, None

        expiry = (
            now + terminal_seconds
            if state == "COPIED"
            else max(int(existing.get("deduplicationExpiresAt", existing.get("expiration", 0))), now + lease_seconds)
        )
        try:
            result = self.table.update_item(
                Key={"id": new_item["id"]},
                UpdateExpression="SET ownerToken = :owner, leaseUntil = :lease, expiration = :expiry",
                ConditionExpression=(
                    "fingerprint = :fingerprint AND #state = :state "
                    "AND leaseUntil <= :now"
                ),
                ExpressionAttributeNames={"#state": "state"},
                ExpressionAttributeValues={
                    ":owner": owner_token,
                    ":lease": now + lease_seconds,
                    ":expiry": expiry,
                    ":fingerprint": item["fingerprint"],
                    ":state": state,
                    ":now": now,
                },
                ReturnValues="ALL_NEW",
            )
            return ("claimed-expired" if expired_in_progress else "claimed"), result["Attributes"], owner_token
        except Exception as error:
            if not _conditional_failure(error):
                raise
            latest = self.get(new_item["id"])
            if (
                latest
                and latest.get("fingerprint") == item["fingerprint"]
                and latest.get("state") in {"SUCCEEDED", "FAILED"}
            ):
                return "terminal", latest, None
            return "active", latest, None

    def mark_copied(
        self,
        item: Mapping[str, Any],
        owner_token: str,
        version_id: str | None,
        completed_at: str,
        deduplication_expiry: int,
        expiry: int,
        lease_until: int,
    ) -> dict[str, Any]:
        values: dict[str, Any] = {
            ":copied": "COPIED",
            ":owner": owner_token,
            ":fingerprint": item["fingerprint"],
            ":expiry": expiry,
            ":lease": lease_until,
            ":completed": completed_at,
            ":dedupe": deduplication_expiry,
        }
        update = (
            "SET #state = :copied, completedAt = :completed, deduplicationExpiresAt = :dedupe, "
            "expiration = :expiry, leaseUntil = :lease"
        )
        if version_id:
            update += ", destinationVersionId = :version"
            values[":version"] = version_id
        response = self.table.update_item(
            Key={"id": item["id"]},
            UpdateExpression=update,
            ConditionExpression="#state = :progress AND ownerToken = :owner AND fingerprint = :fingerprint",
            ExpressionAttributeNames={"#state": "state"},
            ExpressionAttributeValues={**values, ":progress": "IN_PROGRESS"},
            ReturnValues="ALL_NEW",
        )
        return response["Attributes"]

    def mark_succeeded(self, item: Mapping[str, Any], owner_token: str, expiry: int) -> dict[str, Any]:
        response = self.table.update_item(
            Key={"id": item["id"]},
            UpdateExpression="SET #state = :success, expiration = :expiry REMOVE ownerToken, leaseUntil",
            ConditionExpression="#state = :copied AND ownerToken = :owner AND fingerprint = :fingerprint",
            ExpressionAttributeNames={"#state": "state"},
            ExpressionAttributeValues={
                ":success": "SUCCEEDED",
                ":copied": "COPIED",
                ":owner": owner_token,
                ":fingerprint": item["fingerprint"],
                ":expiry": expiry,
            },
            ReturnValues="ALL_NEW",
        )
        return response["Attributes"]

    def mark_failed(
        self,
        item: Mapping[str, Any],
        owner_token: str,
        completed_at: str,
        expiry: int,
        failure_message: str = "Delivery attempts exhausted; destination outcome is uncertain.",
    ) -> dict[str, Any]:
        response = self.table.update_item(
            Key={"id": item["id"]},
            UpdateExpression=(
                "SET #state = :failed, completedAt = :completed, failureCode = :code, "
                "failureMessage = :message, expiration = :expiry REMOVE ownerToken, leaseUntil"
            ),
            ConditionExpression="#state = :progress AND ownerToken = :owner AND fingerprint = :fingerprint",
            ExpressionAttributeNames={"#state": "state"},
            ExpressionAttributeValues={
                ":failed": "FAILED",
                ":progress": "IN_PROGRESS",
                ":owner": owner_token,
                ":fingerprint": item["fingerprint"],
                ":completed": completed_at,
                ":code": "DeliveryAttemptsExhausted",
                ":message": failure_message,
                ":expiry": expiry,
            },
            ReturnValues="ALL_NEW",
        )
        return response["Attributes"]