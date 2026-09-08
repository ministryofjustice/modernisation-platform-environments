import os
from dataclasses import dataclass


@dataclass(frozen=True)
class Destination:
    bucket: str
    kms_key_arn: str


@dataclass(frozen=True)
class Configuration:
    account_id: str
    event_bus_arn: str
    idempotency_expiry_seconds: int
    operation_table_name: str
    part_size_bytes: int
    maximum_parts: int
    multipart_workers: int
    source_bucket: str
    destinations: dict
    receipt_enabled: bool = False
    receipt_kms_key_arn: str = None

    @classmethod
    def for_stage(cls):
        return cls(
            account_id=os.environ["AWS_ACCOUNT_ID"],
            event_bus_arn=os.environ["EVENT_BUS_ARN"],
            idempotency_expiry_seconds=int(os.environ["IDEMPOTENCY_EXPIRY_SECONDS"]),
            operation_table_name=os.environ["WORKFLOW_IDEMPOTENCY_TABLE"],
            part_size_bytes=int(os.environ.get("MULTIPART_PART_SIZE_BYTES", str(1024**3))),
            maximum_parts=int(os.environ.get("MULTIPART_MAX_PARTS", "1000")),
            multipart_workers=int(os.environ.get("MULTIPART_WORKERS", "4")),
            source_bucket=os.environ["INCOMING_BUCKET_NAME"],
            destinations={
                "processing": Destination(
                    bucket=os.environ["PROCESSING_BUCKET_NAME"],
                    kms_key_arn=os.environ["PROCESSING_KMS_KEY_ARN"],
                )
            },
            receipt_enabled=_boolean_environment_value("RECEIPT", False),
            receipt_kms_key_arn=os.environ["INCOMING_KMS_KEY_ARN"],
        )

    @classmethod
    def for_route(cls):
        return cls(
            account_id=os.environ["AWS_ACCOUNT_ID"],
            event_bus_arn=os.environ["EVENT_BUS_ARN"],
            idempotency_expiry_seconds=int(os.environ["IDEMPOTENCY_EXPIRY_SECONDS"]),
            operation_table_name=os.environ["WORKFLOW_IDEMPOTENCY_TABLE"],
            part_size_bytes=int(os.environ.get("MULTIPART_PART_SIZE_BYTES", str(1024**3))),
            maximum_parts=int(os.environ.get("MULTIPART_MAX_PARTS", "1000")),
            multipart_workers=int(os.environ.get("MULTIPART_WORKERS", "4")),
            source_bucket=os.environ["PROCESSING_BUCKET_NAME"],
            destinations={
                route: Destination(
                    bucket=os.environ[f"{route.upper()}_BUCKET_NAME"],
                    kms_key_arn=os.environ[f"{route.upper()}_KMS_KEY_ARN"],
                )
                for route in ["clean", "quarantine", "investigation"]
            },
        )


def _boolean_environment_value(name, default):
    value = os.environ.get(name)
    if value is None:
        return default
    if value.lower() not in {"true", "false"}:
        raise ValueError(f"{name} must be true or false")
    return value.lower() == "true"