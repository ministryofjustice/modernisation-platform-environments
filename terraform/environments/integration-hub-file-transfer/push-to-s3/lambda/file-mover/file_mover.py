import json
import re
from dataclasses import dataclass
from datetime import datetime, timezone

from boto3.s3.transfer import TransferConfig
from botocore.exceptions import BotoCoreError, ClientError

EVENT_SOURCE = "uk.gov.justice.service.managed-file-transfer"
REQUESTED_DETAIL_TYPE = "FileActionExecutionRequested.v1"
COMPLETED_DETAIL_TYPE = "FileActionExecutionCompleted.v1"
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
class DeliveryConfiguration:
    bucket: str
    region: str
    destination_prefix: str
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
    if event.get("detail-type") != REQUESTED_DETAIL_TYPE or action_name != "push-to-s3":
        raise TerminalFailure("INVALID_REQUEST", "The requested action is invalid")

    version_id = _required_string(source_object.get("versionId"), "object.versionId")
    size_bytes = source_object.get("sizeBytes")
    if not isinstance(size_bytes, int) or size_bytes < 0:
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


def parse_configuration(response, supported_region):
    try:
        configuration = json.loads(response["SecretString"])
        action = configuration["action"]
        push_to_s3 = action["push_to_s3"]
    except (KeyError, TypeError, json.JSONDecodeError) as error:
        raise TerminalFailure("INVALID_CONFIGURATION", "The dispatch configuration is invalid") from error

    if set(configuration) != {"action", "notifications"}:
        raise TerminalFailure("INVALID_CONFIGURATION", "The dispatch configuration is invalid")
    if not isinstance(configuration["notifications"], dict):
        raise TerminalFailure("INVALID_CONFIGURATION", "The dispatch configuration is invalid")
    if not isinstance(action, dict) or set(action) != {"name", "push_to_s3"}:
        raise TerminalFailure("INVALID_CONFIGURATION", "The dispatch action is invalid")
    if action.get("name") != "push-to-s3" or not isinstance(push_to_s3, dict):
        raise TerminalFailure("INVALID_CONFIGURATION", "The dispatch action is invalid")
    required_keys = {"bucket_id", "destination_prefix", "kms_key_arn"}
    if not required_keys.issubset(push_to_s3) or not set(push_to_s3).issubset(
        required_keys | {"bucket_region"}
    ):
        raise TerminalFailure("INVALID_CONFIGURATION", "The S3 destination configuration is invalid")

    bucket = _required_string(push_to_s3.get("bucket_id"), "action.push_to_s3.bucket_id")
    region = push_to_s3.get("bucket_region", supported_region)
    destination_prefix = push_to_s3.get("destination_prefix")
    kms_key_arn = _required_string(push_to_s3.get("kms_key_arn"), "action.push_to_s3.kms_key_arn")

    if region != supported_region:
        raise TerminalFailure("UNSUPPORTED_REGION", "The configured destination region is not supported")
    if not isinstance(destination_prefix, str) or destination_prefix.startswith("/"):
        raise TerminalFailure("INVALID_CONFIGURATION", "The destination prefix is invalid")
    if destination_prefix and not destination_prefix.endswith("/"):
        raise TerminalFailure("INVALID_CONFIGURATION", "The destination prefix is invalid")
    if bucket.startswith("arn:") or "/" in bucket:
        raise TerminalFailure("INVALID_CONFIGURATION", "The destination bucket is invalid")
    if not re.fullmatch(
        rf"arn:aws[a-zA-Z-]*:kms:{re.escape(supported_region)}:[0-9]{{12}}:key/[A-Za-z0-9-]+",
        kms_key_arn,
    ):
        raise TerminalFailure("INVALID_CONFIGURATION", "The destination KMS key is invalid")

    return DeliveryConfiguration(bucket, region, destination_prefix, kms_key_arn)


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


def _call_aws(function, terminal_code, terminal_message, **kwargs):
    try:
        return function(**kwargs)
    except Exception as error:
        if _is_transient(error):
            raise
        raise TerminalFailure(terminal_code, terminal_message) from error


def copy_version(delivery_s3, request, configuration, target_key):
    _call_aws(
        delivery_s3.copy,
        "DELIVERY_REJECTED",
        "The destination rejected the file delivery",
        CopySource={
            "Bucket": request.source_object["bucket"],
            "Key": request.source_object["key"],
            "VersionId": request.source_object["versionId"],
        },
        Bucket=configuration.bucket,
        Key=target_key,
        ExtraArgs={
            "ServerSideEncryption": "aws:kms",
            "SSEKMSKeyId": configuration.kms_key_arn,
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
        try:
            process_record(parse_sqs_record(record))
        except Exception:  # noqa: BLE001 - every record failure must be reported to SQS
            failures.append({"itemIdentifier": record["messageId"]})
    return {"batchItemFailures": failures}


class FileMover:
    def __init__(
        self,
        secrets,
        events,
        delivery_client_factory,
        authorised_destination_map,
        delivery_role_map,
        source_prefix_map,
        event_bus_name,
        supported_region,
        outcomes=None,
    ):
        self.secrets = secrets
        self.events = events
        self.delivery_client_factory = delivery_client_factory
        self.authorised_destination_map = authorised_destination_map
        self.delivery_role_map = delivery_role_map
        self.source_prefix_map = source_prefix_map
        self.event_bus_name = event_bus_name
        self.supported_region = supported_region
        self.outcomes = outcomes

        if set(authorised_destination_map) != set(delivery_role_map) or set(
            authorised_destination_map
        ) != set(source_prefix_map):
            raise ValueError("Authorised dispatch maps must contain the same secret ARNs")
        if any(
            not isinstance(prefix, str) or not prefix or not prefix.endswith("/")
            for prefix in source_prefix_map.values()
        ):
            raise ValueError("Source prefixes must be non-empty and end with '/'")

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
        role_arn = self.delivery_role_map.get(secret_prefix)
        source_prefix = self.source_prefix_map.get(secret_prefix)
        if role_arn is None or source_prefix is None:
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

        configuration = parse_configuration(response, self.supported_region)
        authorised_destination = self.authorised_destination_map[secret_prefix]
        if {
            "bucket": configuration.bucket,
            "region": configuration.region,
            "destination_prefix": configuration.destination_prefix,
            "kms_key_arn": configuration.kms_key_arn,
        } != authorised_destination:
            raise TerminalFailure(
                "UNAUTHORISED_DESTINATION",
                "The dispatch destination does not match its authorised role",
            )
        target_key = destination_key(
            request.source_object["key"], source_prefix, configuration.destination_prefix
        )
        destination_s3 = _call_aws(
            self.delivery_client_factory,
            "DELIVERY_ROLE_UNAVAILABLE",
            "The configured delivery role cannot be assumed",
            role_arn=role_arn,
            region=configuration.region,
        )
        copy_version(destination_s3, request, configuration, target_key)
        return {"bucket": configuration.bucket, "key": target_key}

    def _publish(self, request, detail):
        publish_completion(self.events, self.event_bus_name, request, detail)