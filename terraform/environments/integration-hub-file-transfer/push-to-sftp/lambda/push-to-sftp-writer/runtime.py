"""Compatibility entry point for the writer and DLQ reporter Lambdas."""

# ruff: noqa: F401

from mft_writer.completion import build_completion_detail, publish_completion
from mft_writer.config import (
    WriterConfig,
    resolve_secret_entry,
    validate_route,
    validate_secret_configuration,
)
from mft_writer.sftp import transfer_versioned_object
from mft_writer.diagnostics import _update_log_fields, logger, structured_record_context
from mft_writer.errors import AwsResponseError, InvalidMessage
from mft_writer.events import extract_requested_action, unwrap_event
from mft_writer.services import AwsServices, _base_aws_clients, create_aws_services
from mft_writer.store import ActionStore
from mft_writer.worker import (
    action_fingerprint,
    action_snapshot,
    metrics,
    process_reporter_event,
    process_reporter_record,
    process_writer_event,
    process_writer_record,
)
