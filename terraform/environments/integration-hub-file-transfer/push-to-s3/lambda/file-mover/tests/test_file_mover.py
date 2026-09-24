import json

import pytest
from botocore.exceptions import ClientError
from file_mover import (
    DeliveryConfiguration,
    FileMover,
    RequestedAction,
    TerminalFailure,
    batch_response,
    copy_version,
    destination_key,
    parse_sqs_record,
)

SECRET_ARN = "arn:aws:secretsmanager:eu-west-2:123456789012:secret:dispatch-AbCdEf"
SECRET_ARN_PREFIX = "arn:aws:secretsmanager:eu-west-2:123456789012:secret:dispatch-"
ROLE_ARN = "arn:aws:iam::123456789012:role/ihft-development-push-to-s3-entry"


def requested_event():
    return {
        "version": "0",
        "id": "2bd32cbb-c3e2-4b62-8b53-90ea0a7a4de5",
        "detail-type": "FileActionExecutionRequested.v1",
        "source": "uk.gov.justice.service.managed-file-transfer",
        "account": "123456789012",
        "detail": {
            "metadata": {"correlationId": "7d9f4e4c-0e0f-4a5b-8b4e-4ab1f28fd1d1"},
            "data": {
                "fileId": "3f4e3d7a-4e2f-4bc2-9c4e-5f1ef2d4c501",
                "object": {
                    "bucket": "integration-hub-file-transfer-development-clean",
                    "key": "identity/reports/example.csv",
                    "versionId": "source-version",
                    "sizeBytes": 4096,
                },
                "action": {"name": "push-to-s3"},
                "actionExecutionId": "b1d4e7c2-f073-4ed4-9565-a4c31c54bd7f",
                "configurationReference": {
                    "secretArn": SECRET_ARN,
                    "secretVersionId": "configuration-version",
                },
            },
        },
    }


def secret_response():
    return {
        "ARN": SECRET_ARN,
        "VersionId": "configuration-version",
        "SecretString": json.dumps(
            {
                "action": {
                    "name": "push-to-s3",
                    "push_to_s3": {
                        "bucket_id": "customer-bucket",
                        "bucket_region": "eu-west-2",
                        "destination_prefix": "bag-end/",
                        "kms_key_arn": "arn:aws:kms:eu-west-2:210987654321:key/key-id",
                    },
                },
                "notifications": {"email": None, "slack": None, "teams": None},
            }
        ),
    }


class FakeSecrets:
    def __init__(self, response=None, error=None):
        self.response = response or secret_response()
        self.error = error
        self.calls = []

    def get_secret_value(self, **kwargs):
        self.calls.append(kwargs)
        if self.error:
            raise self.error
        return self.response


class FakeDestinationS3:
    def __init__(self):
        self.calls = []

    def copy(self, **kwargs):
        self.calls.append(kwargs)


class FakeEvents:
    def __init__(self):
        self.calls = []

    def put_events(self, **kwargs):
        self.calls.append(kwargs)
        return {"FailedEntryCount": 0, "Entries": [{"EventId": "completion-id"}]}


def mover(secrets=None):
    destination = FakeDestinationS3()
    events = FakeEvents()
    role_calls = []

    def delivery_factory(role_arn, region):
        role_calls.append((role_arn, region))
        return destination

    service = FileMover(
        secrets=secrets or FakeSecrets(),
        events=events,
        delivery_client_factory=delivery_factory,
        authorised_destination_map={
            SECRET_ARN_PREFIX: {
                "bucket": "customer-bucket",
                "region": "eu-west-2",
                "destination_prefix": "bag-end/",
                "kms_key_arn": "arn:aws:kms:eu-west-2:210987654321:key/key-id",
            }
        },
        delivery_role_map={SECRET_ARN_PREFIX: ROLE_ARN},
        source_prefix_map={SECRET_ARN_PREFIX: "identity/"},
        event_bus_name="integration-hub-file-transfer",
        supported_region="eu-west-2",
    )
    return service, destination, events, role_calls


def test_parses_sqs_wrapped_sns_wrapped_event():
    event = requested_event()
    record = {"body": json.dumps({"Type": "Notification", "Message": json.dumps(event)})}

    assert parse_sqs_record(record) == event


def test_replaces_only_the_configured_source_prefix():
    assert destination_key("identity/reports/example.csv", "identity/", "bag-end/") == "bag-end/reports/example.csv"
    with pytest.raises(TerminalFailure, match="configured prefix"):
        destination_key("other/reports/example.csv", "identity/", "bag-end/")


def test_role_mapping_isolated_by_exact_secret_arn():
    service, destination, events, role_calls = mover()
    event = requested_event()
    event["detail"]["data"]["configurationReference"]["secretArn"] = f"{SECRET_ARN}-other"

    assert service.process(event) == "failed"
    assert role_calls == []
    assert destination.calls == []
    failure = json.loads(events.calls[0]["Entries"][0]["Detail"])["data"]["failure"]
    assert failure == {
        "code": "UNAUTHORISED_CONFIGURATION",
        "message": "The dispatch configuration is not authorised",
        "retryable": False,
    }


def test_copy_uses_exact_source_version_and_destination_encryption():
    request = RequestedAction(
        envelope_id="event-id",
        correlation_id="correlation-id",
        file_id="file-id",
        source_object={"bucket": "clean", "key": "identity/file", "versionId": "v1", "sizeBytes": 8},
        action_execution_id="execution-id",
        secret_arn=SECRET_ARN,
        secret_version_id="configuration-version",
    )
    configuration = DeliveryConfiguration(
        "customer-bucket",
        "eu-west-2",
        "target/",
        "arn:aws:kms:eu-west-2:210987654321:key/key-id",
    )
    destination = FakeDestinationS3()

    copy_version(destination, request, configuration, "target/file")

    call = destination.calls[0]
    assert call["CopySource"] == {"Bucket": "clean", "Key": "identity/file", "VersionId": "v1"}
    assert call["Bucket"] == "customer-bucket"
    assert call["Key"] == "target/file"
    assert call["ExtraArgs"] == {
        "ServerSideEncryption": "aws:kms",
        "SSEKMSKeyId": configuration.kms_key_arn,
    }
    assert call["Config"].multipart_threshold == 8 * 1024 * 1024
    assert call["Config"].multipart_chunksize == 32 * 1024 * 1024


def test_rejects_destination_not_authorised_by_terraform():
    response = secret_response()
    configuration = json.loads(response["SecretString"])
    configuration["action"]["push_to_s3"]["bucket_id"] = "different-customer-bucket"
    response["SecretString"] = json.dumps(configuration)
    service, destination, events, role_calls = mover(FakeSecrets(response=response))

    assert service.process(requested_event()) == "failed"

    assert destination.calls == []
    assert role_calls == []
    failure = json.loads(events.calls[0]["Entries"][0]["Detail"])["data"]["failure"]
    assert failure["code"] == "UNAUTHORISED_DESTINATION"


def test_rejects_incomplete_kms_key_arn():
    response = secret_response()
    configuration = json.loads(response["SecretString"])
    configuration["action"]["push_to_s3"]["kms_key_arn"] = "arn:aws:kms:eu-west-2:"
    response["SecretString"] = json.dumps(configuration)
    service, destination, events, role_calls = mover(FakeSecrets(response=response))

    assert service.process(requested_event()) == "failed"

    assert destination.calls == []
    assert role_calls == []
    failure = json.loads(events.calls[0]["Entries"][0]["Detail"])["data"]["failure"]
    assert failure["code"] == "INVALID_CONFIGURATION"


def test_rejects_mismatched_or_invalid_authorisation_maps():
    service, _, events, _ = mover()

    with pytest.raises(ValueError, match="same secret ARNs"):
        FileMover(
            secrets=service.secrets,
            events=events,
            delivery_client_factory=lambda **_: None,
            authorised_destination_map={},
            delivery_role_map={SECRET_ARN_PREFIX: ROLE_ARN},
            source_prefix_map={SECRET_ARN_PREFIX: "identity/"},
            event_bus_name="integration-hub-file-transfer",
            supported_region="eu-west-2",
        )

    with pytest.raises(ValueError, match="end with '/'"):
        FileMover(
            secrets=service.secrets,
            events=events,
            delivery_client_factory=lambda **_: None,
            authorised_destination_map={SECRET_ARN_PREFIX: {}},
            delivery_role_map={SECRET_ARN_PREFIX: ROLE_ARN},
            source_prefix_map={SECRET_ARN_PREFIX: "identity"},
            event_bus_name="integration-hub-file-transfer",
            supported_region="eu-west-2",
        )


def test_success_publishes_completion_with_destination():
    service, destination, events, role_calls = mover()

    assert service.process(requested_event()) == "succeeded"

    assert role_calls == [(ROLE_ARN, "eu-west-2")]
    assert service.secrets.calls == [
        {"SecretId": SECRET_ARN, "VersionId": "configuration-version"}
    ]
    assert destination.calls[0]["CopySource"]["VersionId"] == "source-version"
    assert destination.calls[0]["Key"] == "bag-end/reports/example.csv"
    entry = events.calls[0]["Entries"][0]
    detail = json.loads(entry["Detail"])
    assert entry["DetailType"] == "FileActionExecutionCompleted.v1"
    assert entry["EventBusName"] == "integration-hub-file-transfer"
    assert detail["data"]["status"] == "succeeded"
    assert detail["data"]["result"] == {
        "destination": {"bucket": "customer-bucket", "key": "bag-end/reports/example.csv"}
    }


def test_terminal_configuration_failure_emits_failed_completion():
    response = secret_response()
    response["SecretString"] = "{}"
    service, _, events, _ = mover(FakeSecrets(response=response))

    assert service.process(requested_event()) == "failed"

    detail = json.loads(events.calls[0]["Entries"][0]["Detail"])
    assert detail["data"]["status"] == "failed"
    assert detail["data"]["failure"]["retryable"] is False
    assert detail["data"]["failure"]["code"] == "INVALID_CONFIGURATION"


def test_transient_failure_is_raised_without_completion():
    error = ClientError(
        {
            "Error": {"Code": "ThrottlingException", "Message": "sensitive upstream message"},
            "ResponseMetadata": {"HTTPStatusCode": 429},
        },
        "GetSecretValue",
    )
    service, _, events, _ = mover(FakeSecrets(error=error))

    with pytest.raises(ClientError):
        service.process(requested_event())
    assert events.calls == []


def test_wrapped_transient_copy_failure_is_raised_without_completion():
    service, destination, events, _ = mover()
    transient = ClientError(
        {
            "Error": {"Code": "SlowDown", "Message": "retry"},
            "ResponseMetadata": {"HTTPStatusCode": 503},
        },
        "UploadPartCopy",
    )
    try:
        raise RuntimeError("wrapped upload failure") from transient
    except RuntimeError as wrapped:
        destination.copy = lambda wrapped_error=wrapped, **_kwargs: (
            _ for _ in ()
        ).throw(wrapped_error)

    with pytest.raises(RuntimeError, match="wrapped upload failure"):
        service.process(requested_event())
    assert events.calls == []


def test_partial_batch_response_reports_only_transient_records():
    records = [
        {"messageId": "ok", "body": json.dumps({"Message": json.dumps({"id": "ok"})})},
        {"messageId": "retry", "body": json.dumps({"Message": json.dumps({"id": "retry"})})},
    ]

    def process(event):
        if event["id"] == "retry":
            raise RuntimeError("retry")

    assert batch_response(records, process) == {
        "batchItemFailures": [{"itemIdentifier": "retry"}]
    }