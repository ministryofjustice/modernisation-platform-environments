import json
import uuid
from dataclasses import dataclass
from datetime import datetime, timezone


EVENT_SOURCE = "uk.gov.justice.service.managed-file-transfer"
REQUESTED_DETAIL_TYPE = "FileActionExecutionRequested.v1"


@dataclass(frozen=True)
class Operation:
    operation_id: str
    action: str


@dataclass(frozen=True)
class DispatchConfiguration:
    secret_arn: str
    secret_version_id: str
    operations: tuple[Operation, ...]


@dataclass(frozen=True)
class RoutedFile:
    source_event_id: str
    source_idempotency_key: str
    correlation_id: str
    file_id: str
    destination_object: dict


def _required_string(value, field_name):
    if not isinstance(value, str) or not value:
        raise ValueError(f"{field_name} must be a non-empty string")
    return value


def secret_name_candidates(object_key):
    object_key = _required_string(object_key, "detail.data.destinationObject.key")
    candidates = [object_key]
    parent = object_key.rstrip("/")

    while "/" in parent:
        parent = parent.rsplit("/", 1)[0]
        if parent:
            candidate = f"{parent}/"
            if candidate not in candidates:
                candidates.append(candidate)

    return candidates


def _is_secret_not_found(error):
    response = getattr(error, "response", {})
    return response.get("Error", {}).get("Code") == "ResourceNotFoundException"


def find_dispatch_configuration(secret_client, secret_name_prefix, object_key):
    secret_name_prefix = _required_string(secret_name_prefix, "secretNamePrefix")
    for candidate in secret_name_candidates(object_key):
        try:
            response = secret_client.get_secret_value(
                SecretId=f"{secret_name_prefix}{candidate}"
            )
        except Exception as error:
            if _is_secret_not_found(error):
                continue
            raise

        return parse_dispatch_configuration(response)

    return None


def parse_dispatch_configuration(response):
    secret_arn = _required_string(response.get("ARN"), "secret.ARN")
    secret_version_id = _required_string(
        response.get("VersionId"), "secret.VersionId"
    )
    secret_string = _required_string(response.get("SecretString"), "secret.SecretString")

    try:
        configuration = json.loads(secret_string)
    except json.JSONDecodeError as error:
        raise ValueError("secret.SecretString must contain valid JSON") from error

    if not isinstance(configuration, dict):
        raise ValueError("secret configuration must be an object")

    operations = configuration.get("operations")
    if not isinstance(operations, list):
        raise ValueError("secret.operations must be a list")

    parsed_operations = []
    for index, operation in enumerate(operations):
        if not isinstance(operation, dict):
            raise ValueError(f"secret.operations[{index}] must be an object")

        operation_id = _required_string(
            operation.get("id"), f"secret.operations[{index}].id"
        )
        action = _required_string(
            operation.get("action"), f"secret.operations[{index}].action"
        )
        _required_string(
            operation.get("value"), f"secret.operations[{index}].value"
        )
        parsed_operations.append(Operation(operation_id, action))

    return DispatchConfiguration(
        secret_arn=secret_arn,
        secret_version_id=secret_version_id,
        operations=tuple(parsed_operations),
    )


def parse_file_routed_event(event):
    metadata = event["detail"]["metadata"]
    data = event["detail"]["data"]
    return RoutedFile(
        source_event_id=event["id"],
        source_idempotency_key=metadata["idempotencyKey"],
        correlation_id=metadata["correlationId"],
        file_id=data["fileId"],
        destination_object=data["destinationObject"],
    )


def action_execution_id(routed_file, configuration, operation):
    identity = ":".join(
        [
            routed_file.source_idempotency_key,
            configuration.secret_arn,
            configuration.secret_version_id,
            operation.operation_id,
        ]
    )
    return str(uuid.uuid5(uuid.NAMESPACE_URL, identity))


def build_requested_event_details(routed_file, configuration, requested_at=None):
    requested_at = requested_at or datetime.now(timezone.utc)
    timestamp = requested_at.isoformat().replace("+00:00", "Z")
    details = []

    for operation in configuration.operations:
        execution_id = action_execution_id(routed_file, configuration, operation)
        details.append(
            {
                "metadata": {
                    "correlationId": routed_file.correlation_id,
                    "causationId": routed_file.source_event_id,
                    "idempotencyKey": f"action-request:{execution_id}",
                },
                "data": {
                    "fileId": routed_file.file_id,
                    "object": routed_file.destination_object,
                    "actionDefinitionId": operation.action,
                    "actionExecutionId": execution_id,
                    "requestedAt": timestamp,
                    "parameters": {
                        "secretArn": configuration.secret_arn,
                        "secretVersionId": configuration.secret_version_id,
                        "operationId": operation.operation_id,
                    },
                },
            }
        )

    return details