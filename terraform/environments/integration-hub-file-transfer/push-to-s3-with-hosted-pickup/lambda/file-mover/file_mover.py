import json
import re
from dataclasses import dataclass
from datetime import datetime, timezone

from aws_lambda_powertools import Logger
from boto3.s3.transfer import TransferConfig
from botocore.exceptions import BotoCoreError, ClientError

logger = Logger()

EVENT_SOURCE = "uk.gov.justice.service.managed-file-transfer"
REQUESTED_DETAIL_TYPE = "FileActionExecutionRequested.v1"
COMPLETED_DETAIL_TYPE = "FileActionExecutionCompleted.v1"
ACTION_NAME = "push-to-s3-with-hosted-pickup"
MULTIPART_THRESHOLD = 8 * 1024 * 1024
MULTIPART_CHUNK_SIZE = 32 * 1024 * 1024
TRANSIENT_ERROR_CODES = {
    "InternalError",
    "InternalFailure",
    "RequestTimeout",
    "ServiceUnavailable",
    "SlowDown",
    "Throttling",
    "ThrottlingException",
}


class TerminalFailure(Exception):
    def __init__(self, code, message):
        super().__init__(message)
        self.code = code
        self.safe_message = message


@dataclass(frozen=True)
class RequestedAction:
    envelope_id: str
    correlation_id: str
    file_id: str
    source_object: dict
    action_execution_id: str
    secret_arn: str
    secret_version_id: str


@dataclass(frozen=True)
class HostedPickupConfiguration:
    destination_prefix: str
    retention_days: int


@dataclass(frozen=True)
class AuthorisedDestination:
    bucket: str
    region: str
    destination_prefix: str
    retention_days: int
    kms_key_arn: str


def _required_string(value, field_name):
    if not isinstance(value, str) or not value:
        raise TerminalFailure("INVALID_REQUEST", f"{field_name} is invalid")
    return value


def parse_sqs_record(record):
    try:
        sns_envelope = json.loads(record["body"])
        event = json.loads(sns_envelope["Message"])
    except (KeyError, TypeError, json.JSONDecodeError) as error:
        raise TerminalFailure("INVALID_MESSAGE", "The queued message is invalid") from error

    if not isinstance(event, dict):
        raise TerminalFailure("INVALID_MESSAGE", "The queued event is invalid")
    return event


def parse_requested_action(event):
    try:
        detail = event["detail"]
        metadata = detail["metadata"]
        data = detail["data"]
        source_object = data["object"]
        action_name = data["action"]["name"]
        reference = data["configurationReference"]
    except (KeyError, TypeError) as error:
        raise TerminalFailure("INVALID_REQUEST", "The action request is incomplete") from error

    if event.get("source") != EVENT_SOURCE:
        raise TerminalFailure("INVALID_REQUEST", "The action request source is invalid")
    if event.get("detail-type") != REQUESTED_DETAIL_TYPE or action_name != ACTION_NAME:
        raise TerminalFailure("INVALID_REQUEST", "The requested action is invalid")

    version_id = _required_string(source_object.get("versionId"), "object.versionId")
    size_bytes = source_object.get("sizeBytes")
    if not isinstance(size_bytes, int) or isinstance(size_bytes, bool) or size_bytes < 0:
        raise TerminalFailure("INVALID_REQUEST", "object.sizeBytes is invalid")

    return RequestedAction(
        envelope_id=_required_string(event.get("id"), "event.id"),
        correlation_id=_required_string(metadata.get("correlationId"), "metadata.correlationId"),
        file_id=_required_string(data.get("fileId"), "data.fileId"),
        source_object={
            "bucket": _required_string(source_object.get("bucket"), "object.bucket"),
            "key": _required_string(source_object.get("key"), "object.key"),
            "versionId": version_id,
            "sizeBytes": size_bytes,
        },
        action_execution_id=_required_string(
            data.get("actionExecutionId"), "data.actionExecutionId"
        ),
        secret_arn=_required_string(reference.get("secretArn"), "configurationReference.secretArn"),
        secret_version_id=_required_string(
            reference.get("secretVersionId"), "configurationReference.secretVersionId"
        ),
    )


def _valid_prefix(prefix):
    return (
        isinstance(prefix, str)
        and not prefix.startswith("/")
        and (not prefix or prefix.endswith("/"))
    )


def _valid_retention_days(retention_days):
    return (
        isinstance(retention_days, int)
        and not isinstance(retention_days, bool)
        and retention_days > 0
    )


def parse_configuration(response):
    try:
        configuration = json.loads(response["SecretString"])
        action = configuration["action"]
        hosted_pickup = action["push_to_s3_with_hosted_pickup"]
    except (KeyError, TypeError, json.JSONDecodeError) as error:
        raise TerminalFailure("INVALID_CONFIGURATION", "The dispatch configuration is invalid") from error

    if set(configuration) != {"action", "notifications"}:
        raise TerminalFailure("INVALID_CONFIGURATION", "The dispatch configuration is invalid")
    if not isinstance(configuration["notifications"], dict):
        raise TerminalFailure("INVALID_CONFIGURATION", "The dispatch configuration is invalid")
    if not isinstance(action, dict) or set(action) != {"name", "push_to_s3_with_hosted_pickup"}:
        raise TerminalFailure("INVALID_CONFIGURATION", "The dispatch action is invalid")
    if action.get("name") != ACTION_NAME or not isinstance(hosted_pickup, dict):
        raise TerminalFailure("INVALID_CONFIGURATION", "The dispatch action is invalid")
    if set(hosted_pickup) != {"destination_prefix", "retention_days"}:
        raise TerminalFailure("INVALID_CONFIGURATION", "The hosted pickup configuration is invalid")

    destination_prefix = hosted_pickup.get("destination_prefix")
    retention_days = hosted_pickup.get("retention_days")
    if not _valid_prefix(destination_prefix):
        raise TerminalFailure("INVALID_CONFIGURATION", "The destination prefix is invalid")
    if not _valid_retention_days(retention_days):
        raise TerminalFailure("INVALID_CONFIGURATION", "The retention period is invalid")

    return HostedPickupConfiguration(destination_prefix, retention_days)


def parse_authorised_destination(value, supported_region):
    required_keys = {
        "bucket",
        "region",
        "destination_prefix",
        "retention_days",
        "kms_key_arn",
    }
    if not isinstance(value, dict) or set(value) != required_keys:
        raise ValueError("Authorised destinations must use the expected shape")
    if not isinstance(value["bucket"], str) or not value["bucket"]:
        raise ValueError("Authorised destination buckets must be non-empty")
    if value["region"] != supported_region:
        raise ValueError("Authorised destinations must use the supported region")
    if not _valid_prefix(value["destination_prefix"]):
        raise ValueError("Authorised destination prefixes are invalid")
    if not _valid_retention_days(value["retention_days"]):
        raise ValueError("Authorised destination retention periods are invalid")
    if not isinstance(value["kms_key_arn"], str) or not value["kms_key_arn"]:
        raise ValueError("Authorised destination KMS keys must be non-empty")
    return AuthorisedDestination(**value)


def destination_key(source_key, source_prefix, destination_prefix):
    if not source_key.startswith(source_prefix) or len(source_key) == len(source_prefix):
        raise TerminalFailure("SOURCE_PREFIX_MISMATCH", "The source object does not match its configured prefix")
    return f"{destination_prefix}{source_key[len(source_prefix):]}"


def authorised_secret_prefix(secret_arn, authorised_prefixes):
    matches = [
        prefix
        for prefix in authorised_prefixes
        if re.fullmatch(rf"{re.escape(prefix)}[A-Za-z0-9]{{6}}", secret_arn)
    ]
    return matches[0] if len(matches) == 1 else None


def _is_transient(error):
    if isinstance(error, BotoCoreError):
        return True
    if isinstance(error, ClientError):
        response = error.response
        code = response.get("Error", {}).get("Code")
        status = response.get("ResponseMetadata", {}).get("HTTPStatusCode", 0)
        return code in TRANSIENT_ERROR_CODES or status >= 500
    chained_error = error.__cause__ or error.__context__
    return chained_error is not None and _is_transient(chained_error)


def _aws_error_context(error):
    while error is not None and not isinstance(error, ClientError):
        error = error.__cause__ or error.__context__
    if error is None:
        return {}
    return {
        "aws_error_code": error.response.get("Error", {}).get("Code"),
        "aws_operation": error.operation_name,
        "aws_http_status": error.response.get("ResponseMetadata", {}).get("HTTPStatusCode"),
        "aws_request_id": error.response.get("ResponseMetadata", {}).get("RequestId"),
    }


def _call_aws(function, terminal_code, terminal_message, **kwargs):
    try:
        return function(**kwargs)
    except Exception as error:
        if _is_transient(error):
            raise
        raise TerminalFailure(terminal_code, terminal_message) from error


def copy_version(s3, request, destination, target_key):
    _call_aws(
        s3.copy,
        "DELIVERY_REJECTED",
        "The hosted pickup delivery was rejected",
        CopySource={
            "Bucket": request.source_object["bucket"],
            "Key": request.source_object["key"],
            "VersionId": request.source_object["versionId"],
        },
        Bucket=destination.bucket,
        Key=target_key,
        ExtraArgs={
            "ServerSideEncryption": "aws:kms",
            "SSEKMSKeyId": destination.kms_key_arn,
        },
        Config=TransferConfig(
            multipart_threshold=MULTIPART_THRESHOLD,
            multipart_chunksize=MULTIPART_CHUNK_SIZE,
        ),
    )


def completion_detail(request, status, completed_at, destination=None, failure=None):
    data = {
        "fileId": request.file_id,
        "object": request.source_object,
        "actionDefinitionId": request.secret_arn,
        "actionExecutionId": request.action_execution_id,
        "status": status,
        "completedAt": completed_at.isoformat().replace("+00:00", "Z"),
    }
    if destination is not None:
        data["result"] = {"destination": destination}
    if failure is not None:
        data["failure"] = {
            "code": failure.code,
            "message": failure.safe_message,
            "retryable": False,
        }
    return {
        "metadata": {
            "correlationId": request.correlation_id,
            "causationId": request.envelope_id,
            "idempotencyKey": f"action-complete:{request.action_execution_id}",
        },
        "data": data,
    }


def publish_completion(events, event_bus_name, request, detail):
    response = events.put_events(
        Entries=[
            {
                "Source": EVENT_SOURCE,
                "DetailType": COMPLETED_DETAIL_TYPE,
                "Detail": json.dumps(detail, separators=(",", ":")),
                "EventBusName": event_bus_name,
                "Resources": [
                    f"arn:aws:s3:::{request.source_object['bucket']}/{request.source_object['key']}"
                ],
            }
        ]
    )
    if response.get("FailedEntryCount", 0):
        raise RuntimeError("EventBridge rejected the completion event")


def batch_response(records, process_record):
    failures = []
    for record in records:
        event = None
        try:
            event = parse_sqs_record(record)
            process_record(event)
        except Exception as error:  # noqa: BLE001 - every record failure must be reported to SQS
            log_context = {
                "message_id": record["messageId"],
                "error_type": type(error).__name__,
                **_aws_error_context(error),
            }
            if event is not None:
                detail = event.get("detail")
                data = detail.get("data") if isinstance(detail, dict) else None
                if isinstance(data, dict):
                    log_context["action_execution_id"] = data.get("actionExecutionId")
            logger.warning("Hosted pickup record failed processing", extra=log_context)
            failures.append({"itemIdentifier": record["messageId"]})
    return {"batchItemFailures": failures}


class FileMover:
    def __init__(
        self,
        secrets,
        events,
        mover_client_factory,
        authorised_destination_map,
        mover_role_map,
        source_prefix_map,
        event_bus_name,
        supported_region,
        outcomes=None,
    ):
        self.secrets = secrets
        self.events = events
        self.mover_client_factory = mover_client_factory
        self.mover_role_map = mover_role_map
        self.source_prefix_map = source_prefix_map
        self.event_bus_name = event_bus_name
        self.supported_region = supported_region
        self.outcomes = outcomes

        map_keys = set(authorised_destination_map)
        if map_keys != set(mover_role_map) or map_keys != set(source_prefix_map):
            raise ValueError("Authorised dispatch maps must contain the same secret ARNs")
        if any(
            not isinstance(prefix, str) or not prefix or not prefix.endswith("/")
            for prefix in source_prefix_map.values()
        ):
            raise ValueError("Source prefixes must be non-empty and end with '/'")
        self.authorised_destination_map = {
            secret_arn: parse_authorised_destination(destination, supported_region)
            for secret_arn, destination in authorised_destination_map.items()
        }

    def process(self, event):
        request = parse_requested_action(event)
        if self.outcomes is not None:
            existing = self.outcomes.get(request)
            if existing is not None:
                self.outcomes.publish(request, existing, self._publish)
                return json.loads(existing["detail"])["data"]["status"]
        try:
            destination = self._deliver(request)
            detail = completion_detail(
                request,
                "succeeded",
                datetime.now(timezone.utc),
                destination=destination,
            )
        except TerminalFailure as failure:
            log_context = {
                "action_execution_id": request.action_execution_id,
                "correlation_id": request.correlation_id,
                "failure_code": failure.code,
            }
            log_context.update(_aws_error_context(failure))
            logger.warning("Hosted pickup action failed", extra=log_context)
            detail = completion_detail(
                request,
                "failed",
                datetime.now(timezone.utc),
                failure=failure,
            )
        if self.outcomes is not None:
            item = self.outcomes.record(request, detail)
            self.outcomes.publish(request, item, self._publish)
            return json.loads(item["detail"])["data"]["status"]
        self._publish(request, detail)
        return detail["data"]["status"]

    def _deliver(self, request):
        secret_prefix = authorised_secret_prefix(
            request.secret_arn, self.authorised_destination_map
        )
        role_arn = self.mover_role_map.get(secret_prefix)
        source_prefix = self.source_prefix_map.get(secret_prefix)
        authorised_destination = self.authorised_destination_map.get(secret_prefix)
        if role_arn is None or source_prefix is None or authorised_destination is None:
            raise TerminalFailure("UNAUTHORISED_CONFIGURATION", "The dispatch configuration is not authorised")

        response = _call_aws(
            self.secrets.get_secret_value,
            "CONFIGURATION_UNAVAILABLE",
            "The dispatch configuration is unavailable",
            SecretId=request.secret_arn,
            VersionId=request.secret_version_id,
        )
        if response.get("ARN") != request.secret_arn or response.get("VersionId") != request.secret_version_id:
            raise TerminalFailure("CONFIGURATION_MISMATCH", "The dispatch configuration version did not match")

        configuration = parse_configuration(response)
        if (
            configuration.destination_prefix != authorised_destination.destination_prefix
            or configuration.retention_days != authorised_destination.retention_days
        ):
            raise TerminalFailure(
                "UNAUTHORISED_DESTINATION",
                "The hosted pickup configuration does not match Terraform",
            )
        target_key = destination_key(
            request.source_object["key"], source_prefix, configuration.destination_prefix
        )
        mover_s3 = _call_aws(
            self.mover_client_factory,
            "MOVER_ROLE_UNAVAILABLE",
            "The configured mover role cannot be assumed",
            role_arn=role_arn,
            region=authorised_destination.region,
        )
        copy_version(mover_s3, request, authorised_destination, target_key)
        return {"bucket": authorised_destination.bucket, "key": target_key}

    def _publish(self, request, detail):
        publish_completion(self.events, self.event_bus_name, request, detail)