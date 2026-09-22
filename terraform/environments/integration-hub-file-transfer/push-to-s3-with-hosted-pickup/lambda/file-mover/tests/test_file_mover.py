import json

import pytest
from botocore.exceptions import ClientError
from file_mover import (
    AuthorisedDestination,
    FileMover,
    RequestedAction,
    TerminalFailure,
    batch_response,
    copy_version,
    destination_key,
    parse_sqs_record,
)

SECRET_ARN = "arn:aws:secretsmanager:eu-west-2:123456789012:secret:dispatch-AbCdEf"
ROLE_ARN = "arn:aws:iam::123456789012:role/ihft-development-hosted-pickup-entry"
KMS_KEY_ARN = "arn:aws:kms:eu-west-2:123456789012:key/hosted-key"


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
                "action": {"name": "push-to-s3-with-hosted-pickup"},
                "actionExecutionId": "b1d4e7c2-f073-4ed4-9565-a4c31c54bd7f",
                "configurationReference": {
                    "secretArn": SECRET_ARN,
                    "secretVersionId": "configuration-version",
                },
            },
        },
    }


def secret_response(destination_prefix="pickup/", retention_days=30):
    return {
        "ARN": SECRET_ARN,
        "VersionId": "configuration-version",
        "SecretString": json.dumps(
            {
                "action": {
                    "name": "push-to-s3-with-hosted-pickup",
                    "push_to_s3_with_hosted_pickup": {
                        "destination_prefix": destination_prefix,
                        "retention_days": retention_days,
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


class FakeS3:
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
    mover_s3 = FakeS3()
    events = FakeEvents()
    role_calls = []

    def mover_factory(role_arn, region):
        role_calls.append((role_arn, region))
        return mover_s3

    service = FileMover(
        secrets=secrets or FakeSecrets(),
        events=events,
        mover_client_factory=mover_factory,
        authorised_destination_map={
            SECRET_ARN: {
                "bucket": "ihft-development-hosted-pickup-entry",
                "region": "eu-west-2",
                "destination_prefix": "pickup/",
                "retention_days": 30,
                "kms_key_arn": KMS_KEY_ARN,
            }
        },
        mover_role_map={SECRET_ARN: ROLE_ARN},
        source_prefix_map={SECRET_ARN: "identity/"},
        event_bus_name="integration-hub-file-transfer",
        supported_region="eu-west-2",
    )
    return service, mover_s3, events, role_calls


def test_parses_sqs_wrapped_sns_wrapped_event():
    event = requested_event()
    record = {"body": json.dumps({"Type": "Notification", "Message": json.dumps(event)})}

    assert parse_sqs_record(record) == event


def test_replaces_only_the_configured_source_prefix():
    assert destination_key("identity/reports/example.csv", "identity/", "pickup/") == "pickup/reports/example.csv"
    with pytest.raises(TerminalFailure, match="configured prefix"):
        destination_key("other/reports/example.csv", "identity/", "pickup/")


def test_role_and_secret_mapping_are_isolated_by_exact_secret_arn():
    service, mover_s3, events, role_calls = mover()
    event = requested_event()
    event["detail"]["data"]["configurationReference"]["secretArn"] = f"{SECRET_ARN}-other"

    assert service.process(event) == "failed"
    assert role_calls == []
    assert mover_s3.calls == []
    failure = json.loads(events.calls[0]["Entries"][0]["Detail"])["data"]["failure"]
    assert failure == {
        "code": "UNAUTHORISED_CONFIGURATION",
        "message": "The dispatch configuration is not authorised",
        "retryable": False,
    }


def test_copy_uses_exact_version_multipart_transfer_and_kms_arguments():
    request = RequestedAction(
        envelope_id="event-id",
        correlation_id="correlation-id",
        file_id="file-id",
        source_object={"bucket": "clean", "key": "identity/file", "versionId": "v1", "sizeBytes": 8},
        action_execution_id="execution-id",
        secret_arn=SECRET_ARN,
        secret_version_id="configuration-version",
    )
    destination = AuthorisedDestination(
        "ihft-development-hosted-pickup-entry",
        "eu-west-2",
        "pickup/",
        30,
        KMS_KEY_ARN,
    )
    mover_s3 = FakeS3()

    copy_version(mover_s3, request, destination, "pickup/file")

    call = mover_s3.calls[0]
    assert call["CopySource"] == {"Bucket": "clean", "Key": "identity/file", "VersionId": "v1"}
    assert call["Bucket"] == "ihft-development-hosted-pickup-entry"
    assert call["Key"] == "pickup/file"
    assert call["ExtraArgs"] == {
        "ServerSideEncryption": "aws:kms",
        "SSEKMSKeyId": KMS_KEY_ARN,
    }
    assert call["Config"].multipart_threshold == 8 * 1024 * 1024
    assert call["Config"].multipart_chunksize == 32 * 1024 * 1024


@pytest.mark.parametrize(
    ("destination_prefix", "retention_days"),
    [("different/", 30), ("pickup/", 31)],
)
def test_rejects_secret_destination_or_retention_not_authorised_by_terraform(
    destination_prefix, retention_days
):
    service, mover_s3, events, role_calls = mover(
        FakeSecrets(response=secret_response(destination_prefix, retention_days))
    )

    assert service.process(requested_event()) == "failed"
    assert mover_s3.calls == []
    assert role_calls == []
    failure = json.loads(events.calls[0]["Entries"][0]["Detail"])["data"]["failure"]
    assert failure["code"] == "UNAUTHORISED_DESTINATION"


def test_rejects_mismatched_authorisation_maps():
    service, _, events, _ = mover()

    with pytest.raises(ValueError, match="same secret ARNs"):
        FileMover(
            secrets=service.secrets,
            events=events,
            mover_client_factory=lambda **_: None,
            authorised_destination_map={},
            mover_role_map={SECRET_ARN: ROLE_ARN},
            source_prefix_map={SECRET_ARN: "identity/"},
            event_bus_name="integration-hub-file-transfer",
            supported_region="eu-west-2",
        )


def test_success_publishes_parent_completion_schema():
    service, mover_s3, events, role_calls = mover()

    assert service.process(requested_event()) == "succeeded"

    assert role_calls == [(ROLE_ARN, "eu-west-2")]
    assert service.secrets.calls == [
        {"SecretId": SECRET_ARN, "VersionId": "configuration-version"}
    ]
    assert mover_s3.calls[0]["CopySource"]["VersionId"] == "source-version"
    entry = events.calls[0]["Entries"][0]
    detail = json.loads(entry["Detail"])
    assert entry["DetailType"] == "FileActionExecutionCompleted.v1"
    assert entry["EventBusName"] == "integration-hub-file-transfer"
    assert detail["metadata"]["idempotencyKey"] == "action-complete:b1d4e7c2-f073-4ed4-9565-a4c31c54bd7f"
    assert detail["data"]["status"] == "succeeded"
    assert detail["data"]["result"] == {
        "destination": {
            "bucket": "ihft-development-hosted-pickup-entry",
            "key": "pickup/reports/example.csv",
        }
    }


def test_terminal_configuration_failure_emits_failed_completion():
    response = secret_response(retention_days=0)
    service, mover_s3, events, role_calls = mover(FakeSecrets(response=response))

    assert service.process(requested_event()) == "failed"
    assert mover_s3.calls == []
    assert role_calls == []
    detail = json.loads(events.calls[0]["Entries"][0]["Detail"])
    assert detail["data"]["status"] == "failed"
    assert detail["data"]["failure"] == {
        "code": "INVALID_CONFIGURATION",
        "message": "The retention period is invalid",
        "retryable": False,
    }


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
    service, mover_s3, events, _ = mover()
    transient = ClientError(
        {
            "Error": {"Code": "SlowDown", "Message": "retry"},
            "ResponseMetadata": {"HTTPStatusCode": 503},
        },
        "UploadPartCopy",
    )
    try:
        raise RuntimeError("wrapped copy failure") from transient
    except RuntimeError as wrapped:
        mover_s3.copy = lambda wrapped_error=wrapped, **_kwargs: (
            _ for _ in ()
        ).throw(wrapped_error)

    with pytest.raises(RuntimeError, match="wrapped copy failure"):
        service.process(requested_event())
    assert events.calls == []


def test_partial_batch_response_reports_only_retryable_records():
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