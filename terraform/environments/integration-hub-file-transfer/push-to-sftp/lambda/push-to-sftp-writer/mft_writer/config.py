from __future__ import annotations

import ipaddress
import json
import re
from collections.abc import Mapping
from dataclasses import dataclass
from typing import Any

from mft_writer.errors import InvalidMessage

IDEMPOTENCY_SECONDS = 7 * 24 * 60 * 60
TERMINAL_SECONDS = IDEMPOTENCY_SECONDS


def json_object(raw: str, label: str) -> dict[str, Any]:
    try:
        value = json.loads(raw)
    except (TypeError, ValueError) as error:
        raise InvalidMessage(f"{label} must contain a JSON object") from error
    if not isinstance(value, dict):
        raise InvalidMessage(f"{label} must contain a JSON object")
    return value


def resolve_secret_entry(secret_arn: str, allowlist: Mapping[str, Any]) -> tuple[str, Any]:
    matches = [
        (prefix, value)
        for prefix, value in allowlist.items()
        if secret_arn.startswith(prefix)
        and re.fullmatch(r"[A-Za-z0-9]{6}", secret_arn[len(prefix):])
    ]
    if len(matches) != 1:
        raise InvalidMessage("configuration secret ARN is not uniquely authorised")
    return matches[0]


def safe_relative_path(path: str, *, directory: bool = False) -> str:
    if not isinstance(path, str):
        raise InvalidMessage("remote path must be a string")
    if directory and path == "":
        return path
    parts = path[:-1].split("/") if directory and path.endswith("/") else path.split("/")
    if (
        not path
        or path.startswith("/")
        or "\\" in path
        or any(ord(character) < 32 or ord(character) == 127 for character in path)
        or any(part in {"", ".", ".."} for part in parts)
        or (directory and not path.endswith("/"))
    ):
        raise InvalidMessage("remote path must stay beneath the authorised destination")
    return path


def normalise_destination(value: Mapping[str, Any]) -> dict[str, Any]:
    expected = {"hostname", "port", "username", "destination_prefix", "host_public_keys", "destination_cidr_blocks"}
    destination = dict(value)
    destination.setdefault("port", 22)
    if set(destination) != expected:
        raise InvalidMessage("SFTP destination fields are invalid")
    hostname = destination["hostname"]
    username = destination["username"]
    if not isinstance(hostname, str) or not re.fullmatch(r"[A-Za-z0-9][A-Za-z0-9.-]*", hostname):
        raise InvalidMessage("SFTP hostname is invalid")
    if not isinstance(username, str) or not re.fullmatch(r"[A-Za-z0-9_][A-Za-z0-9_.@-]*", username):
        raise InvalidMessage("SFTP username is invalid")
    if type(destination["port"]) is not int or not 1 <= destination["port"] <= 65535:
        raise InvalidMessage("SFTP port is invalid")
    safe_relative_path(destination["destination_prefix"], directory=True)
    keys = destination["host_public_keys"]
    if not isinstance(keys, list) or not keys or any(not isinstance(key, str) or len(key.split()) != 2 for key in keys):
        raise InvalidMessage("trusted SSH server public keys are required")
    networks = destination["destination_cidr_blocks"]
    if not isinstance(networks, list) or not networks:
        raise InvalidMessage("approved SFTP destination networks are required")
    try:
        for network in networks:
            parsed = ipaddress.ip_network(network)
            if parsed.version != 4 or parsed.prefixlen == 0:
                raise ValueError("a bounded IPv4 network is required")
    except (TypeError, ValueError) as error:
        raise InvalidMessage("approved SFTP destination networks are invalid") from error
    return destination


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
    credential_arns: dict[str, Any]
    idempotency_seconds: int
    terminal_seconds: int
    dlq_arns: dict[str, Any]

    @classmethod
    def from_environment(cls, environ: Mapping[str, str], *, reporter: bool = False) -> WriterConfig:
        if environ.get("ACTION_NAME") != "push-to-sftp" or environ.get("SUPPORTED_REGION") != "eu-west-2":
            raise InvalidMessage("writer action or region is unsupported")
        required = ("SOURCE_BUCKET", "IDEMPOTENCY_TABLE", "EVENT_BUS_NAME")
        if any(not environ.get(name) for name in required):
            raise InvalidMessage("required writer environment variable is missing")
        maps = [json_object(environ.get(name, ""), name) for name in (
            "AUTHORISED_DESTINATION_MAP", "SOURCE_PREFIX_MAP", "DELIVERY_ROLE_MAP", "CREDENTIAL_SECRET_MAP"
        )]
        if any(set(value) != set(maps[0]) for value in maps[1:]):
            raise InvalidMessage("dispatch allowlists must have identical ARN-prefix keys")
        try:
            expiry = int(environ.get("IDEMPOTENCY_EXPIRY_SECONDS", ""))
            terminal = int(environ.get("TERMINAL_OUTCOME_EXPIRY_SECONDS", ""))
        except ValueError as error:
            raise InvalidMessage("idempotency expiry settings must be integers") from error
        if expiry != IDEMPOTENCY_SECONDS or terminal != TERMINAL_SECONDS:
            raise InvalidMessage("idempotency expiry settings do not match the supported policy")
        dlqs = json_object(environ.get("DLQ_ARNS", ""), "DLQ_ARNS") if reporter else {}
        if reporter and (not dlqs or any(not isinstance(arn, str) or not arn for arn in dlqs.values())):
            raise InvalidMessage("DLQ_ARNS must contain queue ARN strings")
        return cls("push-to-sftp", environ["SOURCE_BUCKET"], "eu-west-2", environ["IDEMPOTENCY_TABLE"],
                   environ["EVENT_BUS_NAME"], *maps, expiry, terminal, dlqs)


def validate_route(action: Mapping[str, Any], config: WriterConfig) -> dict[str, Any]:
    source = action["source_object"]
    if source["bucket"] != config.source_bucket:
        raise InvalidMessage("source bucket is not authorised")
    prefix, destination = resolve_secret_entry(action["secret_arn"], config.destinations)
    source_prefix = config.source_prefixes[prefix]
    role_arn = config.role_arns[prefix]
    credential_arn = config.credential_arns[prefix]
    if not isinstance(source_prefix, str) or not source_prefix.endswith("/") or source_prefix.startswith("/"):
        raise InvalidMessage("authorised source prefix is invalid")
    if not isinstance(role_arn, str) or not re.fullmatch(r"arn:aws:iam::[0-9]{12}:role/.+", role_arn):
        raise InvalidMessage("delivery role is not authorised")
    if not isinstance(credential_arn, str) or not re.fullmatch(r"arn:aws:secretsmanager:eu-west-2:[0-9]{12}:secret:.+", credential_arn):
        raise InvalidMessage("credential secret is not authorised")
    if not isinstance(destination, Mapping):
        raise InvalidMessage("destination configuration is invalid")
    destination = normalise_destination(destination)
    if not source["key"].startswith(source_prefix):
        raise InvalidMessage("source key is outside the authorised prefix")
    relative_key = safe_relative_path(source["key"][len(source_prefix):])
    return {
        "destination_path": f"{destination['destination_prefix']}{relative_key}",
        "relative_key": relative_key,
        "role_arn": role_arn,
        "credential_arn": credential_arn,
        "destination": destination,
    }


def validate_secret_configuration(secret_value: str, action_name: str, route: Mapping[str, Any]) -> None:
    action = json_object(secret_value, "dispatch secret").get("action")
    if not isinstance(action, Mapping) or action.get("name") != action_name or set(action) != {"name", "push_to_sftp"}:
        raise InvalidMessage("dispatch secret action does not match this writer")
    details = action["push_to_sftp"]
    if not isinstance(details, Mapping) or normalise_destination(details) != route["destination"]:
        raise InvalidMessage("dispatch secret action does not match the authorised destination")