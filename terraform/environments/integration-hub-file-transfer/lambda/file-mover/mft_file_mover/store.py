import time
from dataclasses import dataclass


@dataclass(frozen=True)
class Claim:
    state: str
    item: dict


class OperationStore:
    def __init__(self, table, clock=None):
        self.table = table
        self.clock = clock or (lambda: int(time.time()))

    def claim(self, operation_event, operation, owner, lease_expires_at, retention_seconds):
        now = self.clock()
        item = {
            "concurrencyId": operation_event.correlation_id,
            "operation": operation,
            "status": "IN_PROGRESS",
            "owner": owner,
            "lease_expires_at": lease_expires_at,
            "event_id": operation_event.event_id,
            "file_id": operation_event.file_id,
            "correlation_id": operation_event.correlation_id,
            "source_bucket": operation_event.source_bucket,
            "source_key": operation_event.source_key,
            "source_version_id": operation_event.source_version_id,
            "source_size_bytes": operation_event.source_size_bytes,
            "created_at": now,
            "updated_at": now,
            "expiration": now + retention_seconds,
        }
        if operation_event.scan_result_status is not None:
            item["scan_result_status"] = operation_event.scan_result_status
            item["scan_result_status_matches_tag"] = (
                operation_event.scan_result_status_matches_tag
            )
        try:
            self.table.put_item(
                Item=item,
                ConditionExpression="attribute_not_exists(concurrencyId)",
            )
            return Claim("CLAIMED", item)
        except Exception as error:
            if not _is_conditional_failure(error):
                raise

        key = self._key(operation_event.correlation_id, operation)
        existing = self.table.get_item(Key=key, ConsistentRead=True).get("Item")
        if not existing:
            raise RuntimeError("The operation claim disappeared after a conditional failure")
        self._validate_existing_input(existing, operation_event)
        if existing["status"] == "COMPLETED":
            return Claim("COMPLETED", existing)
        if int(existing.get("lease_expires_at", 0)) >= now:
            return Claim("ACTIVE", existing)

        try:
            response = self.table.update_item(
                Key=key,
                UpdateExpression="SET #owner = :owner, lease_expires_at = :lease, updated_at = :now",
                ConditionExpression=(
                    "#owner = :previous_owner AND lease_expires_at < :now "
                    "AND #status <> :completed"
                ),
                ExpressionAttributeNames={"#owner": "owner", "#status": "status"},
                ExpressionAttributeValues={
                    ":owner": owner,
                    ":previous_owner": existing["owner"],
                    ":lease": lease_expires_at,
                    ":now": now,
                    ":completed": "COMPLETED",
                },
                ReturnValues="ALL_NEW",
            )
            return Claim("RESUMED", response["Attributes"])
        except Exception as error:
            if _is_conditional_failure(error):
                return Claim("ACTIVE", existing)
            raise

    def update_fields(self, item, owner, fields):
        if not fields:
            return item
        names = {"#owner": "owner", "#status": "status"}
        values = {":owner": owner, ":status": item["status"], ":now": self.clock()}
        assignments = ["updated_at = :now"]
        for index, (name, value) in enumerate(fields.items()):
            name_key = f"#field{index}"
            value_key = f":value{index}"
            names[name_key] = name
            values[value_key] = value
            assignments.append(f"{name_key} = {value_key}")
        response = self.table.update_item(
            Key=self._key(item["concurrencyId"], item["operation"]),
            UpdateExpression=f"SET {', '.join(assignments)}",
            ConditionExpression=(
                "#owner = :owner AND #status = :status AND lease_expires_at >= :now"
            ),
            ExpressionAttributeNames=names,
            ExpressionAttributeValues=values,
            ReturnValues="ALL_NEW",
        )
        return response["Attributes"]

    def transition(self, item, owner, expected_statuses, new_status, fields=None, remove=None):
        fields = fields or {}
        remove = remove or []
        names = {"#owner": "owner", "#status": "status"}
        values = {":owner": owner, ":new_status": new_status, ":now": self.clock()}
        expected_keys = []
        for index, status in enumerate(expected_statuses):
            key = f":expected{index}"
            values[key] = status
            expected_keys.append(key)
        assignments = ["#status = :new_status", "updated_at = :now"]
        for index, (name, value) in enumerate(fields.items()):
            name_key = f"#field{index}"
            value_key = f":value{index}"
            names[name_key] = name
            values[value_key] = value
            assignments.append(f"{name_key} = {value_key}")
        update_expression = f"SET {', '.join(assignments)}"
        if remove:
            remove_names = []
            for index, name in enumerate(remove):
                name_key = f"#remove{index}"
                names[name_key] = name
                remove_names.append(name_key)
            update_expression += f" REMOVE {', '.join(remove_names)}"
        response = self.table.update_item(
            Key=self._key(item["concurrencyId"], item["operation"]),
            UpdateExpression=update_expression,
            ConditionExpression=(
                f"#owner = :owner AND #status IN ({', '.join(expected_keys)}) "
                "AND lease_expires_at >= :now"
            ),
            ExpressionAttributeNames=names,
            ExpressionAttributeValues=values,
            ReturnValues="ALL_NEW",
        )
        return response["Attributes"]

    def release(self, item, owner):
        try:
            self.table.update_item(
                Key=self._key(item["concurrencyId"], item["operation"]),
                UpdateExpression="SET lease_expires_at = :now, updated_at = :now",
                ConditionExpression="#owner = :owner AND #status <> :completed",
                ExpressionAttributeNames={"#owner": "owner", "#status": "status"},
                ExpressionAttributeValues={
                    ":owner": owner,
                    ":now": self.clock(),
                    ":completed": "COMPLETED",
                },
            )
        except Exception as error:
            if not _is_conditional_failure(error):
                raise

    @staticmethod
    def _key(correlation_id, operation):
        return {"concurrencyId": correlation_id, "operation": operation}

    @staticmethod
    def _validate_existing_input(item, operation_event):
        expected = {
            "file_id": operation_event.file_id,
            "correlation_id": operation_event.correlation_id,
            "source_bucket": operation_event.source_bucket,
            "source_key": operation_event.source_key,
            "source_version_id": operation_event.source_version_id,
            "source_size_bytes": operation_event.source_size_bytes,
        }
        if operation_event.scan_result_status is not None:
            expected["scan_result_status"] = operation_event.scan_result_status
        conflicts = [name for name, value in expected.items() if item.get(name) != value]
        if conflicts:
            raise RuntimeError(
                "Existing operation input conflicts with the canonical event: "
                f"{', '.join(conflicts)}"
            )


def _is_conditional_failure(error):
    return (
        getattr(error, "response", {}).get("Error", {}).get("Code")
        == "ConditionalCheckFailedException"
    )