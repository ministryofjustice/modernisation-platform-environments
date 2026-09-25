from __future__ import annotations

import re
from collections.abc import Mapping
from dataclasses import dataclass
from typing import Any

from mft_writer.errors import InvalidMessage
from mft_writer.events import SUPPORTED_REGION, json_object

IDEMPOTENCY_SECONDS = 7 * 24 * 60 * 60
TERMINAL_SECONDS = 7 * 24 * 60 * 60
ALLOWED_ACTIONS = {"push-to-s3", "push-to-s3-with-hosted-pickup"}


def resolve_secret_entry(secret_arn: str, allowlist: Mapping[str, Any]) -> tuple[str, Any]:
    """Match an ARN prefix only when its remaining suffix is exactly six characters."""
    matches = [
        (prefix, value)
        for prefix, value in allowlist.items()
        if isinstance(prefix, str)
        and secret_arn.startswith(prefix)
        and re.fullmatch(r"[A-Za-z0-9]{6}", secret_arn[len(prefix) :])
    ]
    if len(matches) != 1:
        raise InvalidMessage("configuration secret ARN is not uniquely authorised")
    return matches[0]


def load_json_environment(name: str, environ: Mapping[str, str]) -> dict[str, Any]:
    raw = environ.get(name)
    if raw is None:
        raise InvalidMessage(f"required environment variable {name} is missing")
    return json_object(raw, name)


@dataclass(frozen=True)
class WriterConfig:
    action_name: str
    source_bucket: str
    region: str
    table_name: str
    event_bus_name: str
    destinations: dict[str, Any]
    source_prefixes: dict[str, Any]
    role_arns: dict[str, Any]
    idempotency_seconds: int
    terminal_seconds: int
    dlq_arns: dict[str, Any]

    @classmethod
    def from_environment(
        cls, environ: Mapping[str, str], *, reporter: bool = False
    ) -> WriterConfig:
        action_name = environ.get("ACTION_NAME", "")
        if action_name not in ALLOWED_ACTIONS:
            raise InvalidMessage("ACTION_NAME is missing or unsupported")
        source_bucket = environ.get("SOURCE_BUCKET", "")
        if not source_bucket:
            raise InvalidMessage("required environment variable SOURCE_BUCKET is missing")
        region = environ.get("SUPPORTED_REGION", "")
        if region != SUPPORTED_REGION:
            raise InvalidMessage("SUPPORTED_REGION must be eu-west-2")
        table_name = environ.get("IDEMPOTENCY_TABLE", "")
        event_bus_name = environ.get("EVENT_BUS_NAME", "")
        if not table_name or not event_bus_name:
            raise InvalidMessage("IDEMPOTENCY_TABLE and EVENT_BUS_NAME are required")

        role_variable = "DELIVERY_ROLE_MAP" if action_name == "push-to-s3" else "MOVER_ROLE_MAP"
        destinations = load_json_environment("AUTHORISED_DESTINATION_MAP", environ)
        source_prefixes = load_json_environment("SOURCE_PREFIX_MAP", environ)
        role_arns = load_json_environment(role_variable, environ)
        if set(destinations) != set(source_prefixes) or set(destinations) != set(role_arns):
            raise InvalidMessage("dispatch allowlists must have identical ARN-prefix keys")
        if any(not isinstance(key, str) or not key for key in destinations):
            raise InvalidMessage("dispatch allowlist keys must be non-empty strings")

        try:
            idempotency_seconds = int(environ.get("IDEMPOTENCY_EXPIRY_SECONDS", ""))
            terminal_seconds = int(environ.get("TERMINAL_OUTCOME_EXPIRY_SECONDS", ""))
        except ValueError as error:
            raise InvalidMessage("idempotency expiry settings must be integers") from error
        if idempotency_seconds != IDEMPOTENCY_SECONDS or terminal_seconds != TERMINAL_SECONDS:
            raise InvalidMessage("idempotency expiry settings do not match the supported policy")

        dlq_arns: dict[str, Any] = {}
        if reporter:
            dlq_arns = load_json_environment("DLQ_ARNS", environ)
            if not dlq_arns or any(not isinstance(arn, str) or not arn for arn in dlq_arns.values()):
                raise InvalidMessage("DLQ_ARNS must contain queue ARN strings")

        return cls(
            action_name=action_name,
            source_bucket=source_bucket,
            region=region,
            table_name=table_name,
            event_bus_name=event_bus_name,
            destinations=destinations,
            source_prefixes=source_prefixes,
            role_arns=role_arns,
            idempotency_seconds=idempotency_seconds,
            terminal_seconds=terminal_seconds,
            dlq_arns=dlq_arns,
        )


def validate_route(action: dict[str, Any], config: WriterConfig) -> dict[str, Any]:
    source_object = action["source_object"]
    if source_object["bucket"] != config.source_bucket:
        raise InvalidMessage("source bucket is not authorised")

    prefix, destination = resolve_secret_entry(action["secret_arn"], config.destinations)
    source_prefix = config.source_prefixes.get(prefix)
    role_arn = config.role_arns.get(prefix)
    if not isinstance(source_prefix, str) or not source_prefix:
        raise InvalidMessage("source prefix is not authorised")
    if source_prefix.startswith("/") or not source_prefix.endswith("/"):
        raise InvalidMessage("authorised source prefix is invalid")
    if not isinstance(role_arn, str) or not re.fullmatch(
        r"arn:aws[a-zA-Z-]*:iam::[0-9]{12}:role/.+", role_arn
    ):
        raise InvalidMessage("delivery role is not authorised")
    if not isinstance(destination, Mapping):
        raise InvalidMessage("destination configuration is invalid")

    key = source_object["key"]
    if not key.startswith(source_prefix):
        raise InvalidMessage("source key is outside the authorised prefix")
    relative_key = key[len(source_prefix) :]
    if not relative_key:
        raise InvalidMessage("source key has no relative filename")

    destination_bucket = destination.get("bucket")
    destination_prefix = destination.get("destination_prefix")
    destination_region = destination.get("region")
    kms_key_arn = destination.get("kms_key_arn")
    if not isinstance(destination_bucket, str) or not destination_bucket:
        raise InvalidMessage("destination bucket is invalid")
    if (
        not isinstance(destination_prefix, str)
        or destination_prefix.startswith("/")
        or (destination_prefix and not destination_prefix.endswith("/"))
    ):
        raise InvalidMessage("destination prefix is invalid")
    if destination_region != config.region:
        raise InvalidMessage("destination region is not supported")
    if not isinstance(kms_key_arn, str) or not re.fullmatch(
        r"arn:aws[a-zA-Z-]*:kms:eu-west-2:[0-9]{12}:key/[A-Za-z0-9-]+", kms_key_arn
    ):
        raise InvalidMessage("destination KMS key is invalid")

    if config.action_name == "push-to-s3-with-hosted-pickup":
        retention = destination.get("retention_days")
        if type(retention) is not int or retention < 1:
            raise InvalidMessage("hosted pickup retention_days is invalid")
    return {
        "destination_bucket": destination_bucket,
        "destination_key": f"{destination_prefix}{relative_key}",
        "kms_key_arn": kms_key_arn,
        "role_arn": role_arn,
        "destination": dict(destination),
    }


def validate_secret_configuration(
    secret_value: str, action_name: str, route: Mapping[str, Any]
) -> None:
    secret = json_object(secret_value, "dispatch secret")
    action = secret.get("action")
    if not isinstance(action, Mapping) or action.get("name") != action_name:
        raise InvalidMessage("dispatch secret action does not match this writer")

    if action_name == "push-to-s3":
        details = action.get("push_to_s3")
        expected = route["destination"]
        expected_values = {
            "bucket_id": expected["bucket"],
            "bucket_region": expected["region"],
            "destination_prefix": expected["destination_prefix"],
            "kms_key_arn": expected["kms_key_arn"],
        }
        actual_values = dict(details) if isinstance(details, Mapping) else {}
        actual_values.setdefault("bucket_region", SUPPORTED_REGION)
    else:
        details = action.get("push_to_s3_with_hosted_pickup")
        expected = route["destination"]
        expected_values = {
            "destination_prefix": expected["destination_prefix"],
            "retention_days": expected["retention_days"],
        }
        actual_values = dict(details) if isinstance(details, Mapping) else {}
    if actual_values != expected_values:
        raise InvalidMessage("dispatch secret action does not match the authorised destination")