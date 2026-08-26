import json
import uuid
from dataclasses import dataclass
from datetime import datetime, timezone
from typing import Optional


EVENT_SOURCE = "uk.gov.justice.service.managed-file-transfer"
REQUESTED_DETAIL_TYPE = "FileActionExecutionRequested.v1"


@dataclass(frozen=True)
class DispatchConfiguration:
    secret_arn: str
    secret_version_id: str
    action_name: Optional[str]
    notifications: tuple[str, ...]


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

    action = configuration.get("action")
    if action is not None and not isinstance(action, dict):
        raise ValueError("secret.action must be an object or null")
    action_name = (
        _required_string(action.get("name"), "secret.action.name")
        if action is not None
        else None
    )

    notifications = configuration.get("notifications")
    if not isinstance(notifications, dict):
        raise ValueError("secret.notifications must be an object")

    configured_notifications = []
    for notification_name, destination in notifications.items():
        if destination is None:
            continue
        _required_string(notification_name, "secret.notifications key")
        _required_string(destination, f"secret.notifications.{notification_name}")
        configured_notifications.append(notification_name)

    return DispatchConfiguration(
        secret_arn=secret_arn,
        secret_version_id=secret_version_id,
        action_name=action_name,
        notifications=tuple(configured_notifications),
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


def action_execution_id(routed_file, configuration):
    identity = ":".join(
        [
            routed_file.source_idempotency_key,
            configuration.secret_arn,
            configuration.secret_version_id,
        ]
    )
    return str(uuid.uuid5(uuid.NAMESPACE_URL, identity))


def build_requested_event_detail(routed_file, configuration, requested_at=None):
    if configuration.action_name is None and not configuration.notifications:
        return None

    requested_at = requested_at or datetime.now(timezone.utc)
    timestamp = requested_at.isoformat().replace("+00:00", "Z")
    execution_id = action_execution_id(routed_file, configuration)
    data = {
        "fileId": routed_file.file_id,
        "object": routed_file.destination_object,
        "actionExecutionId": execution_id,
        "requestedAt": timestamp,
        "notifications": list(configuration.notifications),
        "configurationReference": {
            "secretArn": configuration.secret_arn,
            "secretVersionId": configuration.secret_version_id,
        },
    }
    if configuration.action_name is not None:
        data["action"] = {"name": configuration.action_name}

    return {
        "metadata": {
            "correlationId": routed_file.correlation_id,
            "causationId": routed_file.source_event_id,
            "idempotencyKey": f"action-request:{execution_id}",
        },
        "data": data,
    }