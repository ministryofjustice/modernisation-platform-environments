"""Tests for the CloudWatch -> Slack Lambda (`lambda_function.py`).

Mocking seams:
- ``lambda_function._post``        -> capture (webhook_url, slack_payload), no network.
- ``lambda_function.boto3.client`` -> fake Secrets Manager returning SECRETS.
"""

import contextlib
import importlib
import json
import logging
import urllib.error
from email.message import Message
from unittest import mock

import pytest

import lambda_function as lf

# Fixtures / helpers:

SECRETS = {
    "slack_channel_webhook": "https://hooks.test/main",
    "slack_channel_webhook_guardduty": "https://hooks.test/gd",
    "slack_channel_webhook_s3": "https://hooks.test/s3",
}


class FakeContext:
    function_name = "test-fn"


@pytest.fixture(autouse=True)
def _reset_secret_caches():
    # get_credentials / _secretsmanager are @functools.cache; clear between tests so
    # the cached secret value and client don't leak across tests (isolation).
    lf._secretsmanager.cache_clear()
    lf.get_credentials.cache_clear()
    yield
    lf._secretsmanager.cache_clear()
    lf.get_credentials.cache_clear()


@pytest.fixture
def invoke(monkeypatch):
    """Return a callable that invokes ``lambda_handler`` with boto3 + _post mocked.

    Yields ``(response, post_mock)`` where ``post_mock`` records the Slack calls.
    """
    monkeypatch.setenv("SECRET_NAME", "test-secret")

    sm_client = mock.MagicMock()
    sm_client.get_secret_value.return_value = {"SecretString": json.dumps(SECRETS)}
    post = mock.Mock(return_value=200)

    def _invoke(event):
        with mock.patch.object(lf.boto3, "client", return_value=sm_client), mock.patch.object(lf, "_post", post):
            response = lf.lambda_handler(event, FakeContext())
        return response, post

    return _invoke


def sent(post):
    """Assert exactly one Slack call was made; return (url, payload, json_blob)."""
    assert post.call_count == 1, f"expected 1 Slack call, got {post.call_count}"
    url, payload = post.call_args.args
    return url, payload, json.dumps(payload)


# Event builders:


def sns_event(message, *, sns_type="Notification", timestamp="2026-06-22T11:25:23.000Z"):
    """Wrap a message (dict or str) in an SNS->Lambda event envelope."""
    msg = message if isinstance(message, str) else json.dumps(message)
    return {"Records": [{"Sns": {"Type": sns_type, "Timestamp": timestamp, "Message": msg}}]}


def cw_message(state="ALARM", name="my-cw-alarm"):
    return {
        "AlarmName": name,
        "AlarmArn": f"arn:aws:cloudwatch:eu-west-2:111122223333:alarm:{name}",
        "Region": "eu-west-2",
        "NewStateValue": state,
        "NewStateReason": "Threshold Crossed: 1 datapoint",
        "AlarmDescription": "CPU high",
        "Trigger": {
            "Namespace": "AWS/EC2",
            "MetricName": "CPUUtilization",
            "Dimensions": [{"name": "InstanceId", "value": "i-0123456789"}],
        },
    }


def guardduty_message(severity=8.0):
    return {
        "source": "aws.guardduty",
        "time": "2026-06-22T11:25:23Z",  # GuardDuty parse expects no fractional seconds
        "detail": {
            "severity": severity,
            "id": "2ab00f5a1b2c3d4e5f60718293a4b5c6",
            "type": "Recon:EC2/PortProbeUnprotectedPort",
            "region": "eu-west-2",
            "accountId": "111122223333",
            "description": "Unprotected port on EC2 instance i-0123456789",
            "service": {
                "count": 5,
                "eventFirstSeen": "2026-06-20T10:00:00.000Z",
                "eventLastSeen": "2026-06-22T11:00:00.000Z",
            },
        },
    }


def s3_records_message(key="uploads/data.csv"):
    return {
        "Records": [
            {
                "eventSource": "aws:s3",
                "awsRegion": "eu-west-2",
                "eventTime": "2026-06-22T11:25:23.364Z",
                "s3": {
                    "bucket": {"name": "my-bucket"},
                    "object": {"key": key, "size": 456},
                },
                "userIdentity": {"principalId": "AROAEXAMPLE:user"},
            }
        ]
    }


def s3_detail_message(key="incoming/file.txt"):
    return {
        "source": "aws.s3",
        "region": "eu-west-2",
        "time": "2026-06-22T11:25:23.000Z",
        "detail": {
            "bucket": {"name": "my-bucket"},
            "object": {"key": key, "size": 123},
        },
    }


def acm_event():
    """ACM certificate-expiry arrives as a direct EventBridge event (no SNS wrapper)."""
    return {
        "source": "aws.acm",
        "time": "2026-06-22T11:25:23.000Z",
        "detail": {"CommonName": "*.service.gov.uk", "DaysToExpiry": 17.0},
    }


# CloudWatch Alarm:


def test_cloudwatch_alarm_routes_to_main_webhook_with_error_emoji(invoke):
    response, post = invoke(sns_event(cw_message(state="ALARM")))
    url, payload, blob = sent(post)

    assert url == SECRETS["slack_channel_webhook"]
    assert payload["blocks"][0]["text"]["text"] == "ALARM - my-cw-alarm"
    assert ":broken_heart:" in blob
    assert "AWS/EC2" in blob and "CPUUtilization" in blob
    assert "Threshold Crossed" in blob
    assert "InstanceId = i-0123456789" in blob
    assert response["statusCode"] == 200


def test_cloudwatch_alarm_ok_state_uses_success_emoji(invoke):
    _, post = invoke(sns_event(cw_message(state="OK")))
    _, payload, blob = sent(post)
    assert payload["blocks"][0]["text"]["text"] == "OK - my-cw-alarm"
    assert ":white_check_mark:" in blob


def test_insufficient_data_nonprod_out_of_hours_is_suppressed(invoke):
    # 22:00 UTC, dev- prefix -> suppressed, no notification.
    event = sns_event(
        cw_message(state="INSUFFICIENT_DATA", name="dev-some-alarm"),
        timestamp="2026-06-22T22:00:00.000Z",
    )
    response, post = invoke(event)
    assert post.call_count == 0
    assert response is None


def test_cloudwatch_alarm_without_timestamp_falls_back_to_now(invoke):
    # No SNS Timestamp -> handler falls back to datetime.now(timezone.utc) for
    # alarm_time and still sends a notification (exercises the utcnow->now change).
    event = {"Records": [{"Sns": {"Type": "Notification", "Message": json.dumps(cw_message())}}]}
    response, post = invoke(event)
    assert post.call_count == 1
    assert response["statusCode"] == 200


def test_insufficient_data_prod_out_of_hours_still_notifies(invoke):
    # prod- prefix is never suppressed, even out of hours.
    event = sns_event(
        cw_message(state="INSUFFICIENT_DATA", name="prod-some-alarm"),
        timestamp="2026-06-22T22:00:00.000Z",
    )
    response, post = invoke(event)
    assert post.call_count == 1
    assert response["statusCode"] == 200


# GuardDuty:


def test_guardduty_routes_to_guardduty_webhook(invoke):
    _, post = invoke(sns_event(guardduty_message(severity=8.0)))
    url, payload, blob = sent(post)

    assert url == SECRETS["slack_channel_webhook_guardduty"]
    header = payload["blocks"][0]["text"]["text"]
    assert "GuardDuty Finding" in header
    assert "eu-west-2" in header
    assert "Account: 111122223333" in header
    assert "Recon:EC2/PortProbeUnprotectedPort" in blob
    # severity 8.0 -> High
    assert ":small_red_triangle:" in blob
    assert "High" in blob


@pytest.mark.parametrize(
    "severity, label, emoji",
    [
        (3.0, "Low", ":large_blue_circle:"),
        (5.0, "Medium", ":large_orange_circle:"),
        (8.0, "High", ":small_red_triangle:"),
        (9.5, "Critical", ":broken_heart:"),
        ("n/a", "Unknown", ":grey_question:"),
    ],
)
def test_guardduty_severity_mapping(severity, label, emoji):
    """Direct unit test of the GuardDuty severity -> (label, emoji) mapping."""
    svc = lf.NotificationService(SECRETS["slack_channel_webhook_guardduty"])
    captured = {}
    with mock.patch.object(lf, "_post", side_effect=lambda url, payload: captured.update(p=payload) or 200):
        svc.send_notification("n", {"detail": {"severity": severity}}, "ts", "GuardDuty", True)
    blob = json.dumps(captured["p"])
    assert label in blob
    assert emoji in blob


# S3 events:


def test_s3_records_form_routes_to_s3_webhook_with_principal(invoke):
    _, post = invoke(sns_event(s3_records_message()))
    url, _, blob = sent(post)
    assert url == SECRETS["slack_channel_webhook_s3"]
    assert "my-bucket" in blob
    assert "uploads/data.csv" in blob
    assert "AROAEXAMPLE:user" in blob
    assert ":white_check_mark:" in blob


def test_s3_rejected_object_uses_error_emoji(invoke):
    _, post = invoke(sns_event(s3_records_message(key="uploads/rejected_payment.csv")))
    _, _, blob = sent(post)
    assert ":broken_heart:" in blob


def test_s3_detail_form_routes_to_s3_webhook_without_principal(invoke):
    _, post = invoke(sns_event(s3_detail_message()))
    url, _, blob = sent(post)
    assert url == SECRETS["slack_channel_webhook_s3"]
    assert "my-bucket" in blob
    assert "incoming/file.txt" in blob
    assert "Principal" not in blob  # detail form has no userIdentity


# ACM certificate expiry (EventBridge):


def test_acm_certificate_expiry_routes_to_main_webhook(invoke):
    response, post = invoke(acm_event())
    url, _, blob = sent(post)
    assert url == SECRETS["slack_channel_webhook"]
    assert "*.service.gov.uk" in blob
    assert ":rotating_light:" in blob
    # explicit expiry date in the header (event time 2026-06-22 + 17 days)
    assert "is expiring on Thu, 09 Jul 2026" in blob
    # Days-to-Expiry rendered as an int, not 17.0
    assert "*Days to Expiry:* 17" in blob
    assert "17.0" not in blob
    assert response["statusCode"] == 200


# Skip / control-message paths:


@pytest.mark.parametrize("sns_type", ["SubscriptionConfirmation", "UnsubscribeConfirmation"])
def test_sns_control_messages_are_ignored(invoke, sns_type):
    event = sns_event(cw_message(), sns_type=sns_type)
    response, post = invoke(event)
    assert post.call_count == 0
    assert response is None


def test_unrecognised_message_sends_fallback(invoke):
    # Default NOTIFY_UNRECOGNISED=on: an unclassifiable SNS message is surfaced to
    # Slack as a fallback notification (not silently dropped).
    response, post = invoke(sns_event({"hello": "world"}))
    url, payload, blob = sent(post)
    assert url == SECRETS["slack_channel_webhook"]
    assert payload["blocks"][0]["text"]["text"] == "*Unrecognised event received*"
    assert "hello" in blob and "world" in blob  # the raw event is dumped
    assert response["statusCode"] == 200


def test_unrecognised_message_skipped_when_flag_off(monkeypatch):
    # NOTIFY_UNRECOGNISED=off restores the silent-skip behaviour.
    with env_reload(monkeypatch, NOTIFY_UNRECOGNISED="off"):
        response, post = _run(sns_event({"hello": "world"}))
    assert post.call_count == 0
    assert response is None


def test_metric_unrecognised_event(invoke):
    with mock.patch.object(lf, "_emit_metric") as emit:
        invoke(sns_event({"hello": "world"}))
    assert "UnrecognisedEvents" in _emitted_names(emit)


def test_event_without_sns_or_eventbridge_shape_is_skipped(invoke):
    # Neither an SNS record nor an EventBridge certificate detail -> message_str stays
    # None and the handler skips cleanly (was: NameError -> caught -> confusing 500).
    response, post = invoke({"foo": "bar"})
    assert post.call_count == 0
    assert response is None


def test_empty_records_event_is_skipped(invoke):
    # {"Records": []} must not raise IndexError on event["Records"][0].
    response, post = invoke({"Records": []})
    assert post.call_count == 0
    assert response is None


def test_certificate_event_with_records_uses_fallback_payload(invoke):
    # An ACM cert event that also carries a truthy Records hits the cert branch, which
    # does not set payload -> the default fallback payload is sent (was: UnboundLocalError
    # -> silent failure with no notification).
    event = {
        "source": "aws.acm",
        "time": "2026-06-22T11:25:23.000Z",
        "detail": {"CommonName": "example.service.gov.uk", "DaysToExpiry": 14},
        "Records": [{"something": "unexpected"}],
    }
    response, post = invoke(event)
    _, _, blob = sent(post)
    assert response["statusCode"] == 200
    assert "example.service.gov.uk" in blob  # fallback rendered the raw details


def test_validateconfig_from_secrets(monkeypatch):
    cfg = lf.ValidateConfig.from_secrets(SECRETS)
    assert cfg.slack_channel_webhook == SECRETS["slack_channel_webhook"]
    assert cfg.slack_channel_webhook_guardduty == SECRETS["slack_channel_webhook_guardduty"]
    with pytest.raises(ValueError, match="must be a non-empty string"):
        lf.ValidateConfig.from_secrets({"slack_channel_webhook": "x"})  # missing gd + s3


def test_missing_webhook_secret_raises(monkeypatch):
    # A secret missing one of the three webhooks must raise a clear ValueError.
    monkeypatch.setenv("SECRET_NAME", "test-secret")
    incomplete = {"slack_channel_webhook": "https://hooks.test/main"}  # missing gd + s3
    client = mock.MagicMock()
    client.get_secret_value.return_value = {"SecretString": json.dumps(incomplete)}
    with mock.patch.object(lf.boto3, "client", return_value=client):
        with pytest.raises(ValueError, match="must be a non-empty string"):
            lf.lambda_handler(sns_event(cw_message()), FakeContext())


def test_get_credentials_wraps_clienterror():
    from botocore.exceptions import ClientError

    err = ClientError({"Error": {"Code": "ResourceNotFoundException"}}, "GetSecretValue")
    client = mock.MagicMock()
    client.get_secret_value.side_effect = err
    with mock.patch.object(lf.boto3, "client", return_value=client):
        with pytest.raises(lf.SecretRetrievalError) as exc_info:
            lf.get_credentials("test-secret")
    assert exc_info.value.__cause__ is err  # cause chain preserved


def test_get_credentials_wraps_json_error():
    client = mock.MagicMock()
    client.get_secret_value.return_value = {"SecretString": "not-valid-json{"}
    with mock.patch.object(lf.boto3, "client", return_value=client):
        with pytest.raises(lf.SecretRetrievalError) as exc_info:
            lf.get_credentials("test-secret")
    assert isinstance(exc_info.value.__cause__, json.JSONDecodeError)


def test_slack_http_error_returns_false():
    # HTTP >= 400 raises SlackNotificationError internally, caught -> returns False.
    svc = lf.NotificationService("https://hooks.test/x")
    with mock.patch.object(lf, "_post", mock.Mock(return_value=500)):
        assert svc.send_notification("t", {"k": "v"}, "ts", "Unknown", False) is False


def test_handler_raises_when_delivery_fails(monkeypatch):
    # Delivery failure must fail the invocation (so Lambda dead-letters it), not return 200.
    monkeypatch.setenv("SECRET_NAME", "test-secret")
    client = mock.MagicMock()
    client.get_secret_value.return_value = {"SecretString": json.dumps(SECRETS)}
    with (
        mock.patch.object(lf.boto3, "client", return_value=client),
        mock.patch.object(lf, "_post", mock.Mock(return_value=500)),
    ):
        with pytest.raises(lf.SlackNotificationError):
            lf.lambda_handler(sns_event(cw_message()), FakeContext())


def test_handler_reraises_unexpected_errors(monkeypatch):
    # An unexpected error (invalid JSON message) must propagate, not return a 500 dict.
    monkeypatch.setenv("SECRET_NAME", "test-secret")
    client = mock.MagicMock()
    client.get_secret_value.return_value = {"SecretString": json.dumps(SECRETS)}
    bad = {
        "Records": [
            {"Sns": {"Type": "Notification", "Timestamp": "2026-06-22T11:25:23.000Z", "Message": "{not valid json"}}
        ]
    }
    with (
        mock.patch.object(lf.boto3, "client", return_value=client),
        mock.patch.object(lf, "_post", mock.Mock(return_value=200)),
    ):
        with pytest.raises(json.JSONDecodeError):
            lf.lambda_handler(bad, FakeContext())


def test_secret_and_client_cached_across_warm_invocations(monkeypatch):
    # Two invocations in the same "container" reuse the boto3 client and the fetched
    # secret (warm-start optimisation).
    monkeypatch.setenv("SECRET_NAME", "test-secret")
    client = mock.MagicMock()
    client.get_secret_value.return_value = {"SecretString": json.dumps(SECRETS)}
    with (
        mock.patch.object(lf.boto3, "client", return_value=client) as boto_client,
        mock.patch.object(lf, "_post", mock.Mock(return_value=200)),
    ):
        lf.lambda_handler(sns_event(cw_message()), FakeContext())
        lf.lambda_handler(sns_event(cw_message()), FakeContext())  # warm
    assert client.get_secret_value.call_count == 1  # secret fetched once, then cached
    assert boto_client.call_count == 1  # client built once, then reused


def test_non_string_secret_name_raises_clear_valueerror(monkeypatch):
    # A non-string SECRET_NAME must produce a clear ValueError (regression for the
    # shadowed-`type` bug, which previously raised an opaque TypeError here).
    # Env vars are always strings, so the non-string value must come via the event.
    monkeypatch.delenv("SECRET_NAME", raising=False)
    with pytest.raises(ValueError, match="must be a string"):
        lf.lambda_handler({"secret_name": 123}, FakeContext())


# Fallback payload (reached via the error-notification path in production):


def test_fallback_payload_includes_title_and_raw_details():
    svc = lf.NotificationService(SECRETS["slack_channel_webhook"])
    captured = {}
    with mock.patch.object(lf, "_post", side_effect=lambda url, payload: captured.update(p=payload) or 200):
        ok = svc.send_notification("My Title", {"foo": "bar"}, "ts", "Unknown", False)
    assert ok is True
    blob = json.dumps(captured["p"])
    assert "My Title" in blob
    assert "foo" in blob and "bar" in blob


# Timestamp formatting — weekday is mandatory across all event types:


@pytest.mark.parametrize(
    "raw, expected",
    [
        ("2026-06-22T11:25:23.364Z", "Mon, 22 Jun 2026 11:25:23 UTC"),  # fractional seconds
        ("2026-06-22T11:25:23Z", "Mon, 22 Jun 2026 11:25:23 UTC"),  # whole seconds
        ("2026-06-20T10:00:00.000Z", "Sat, 20 Jun 2026 10:00:00 UTC"),
    ],
)
def test_format_event_time_includes_weekday(raw, expected):
    assert lf.format_event_time(raw) == expected


def test_format_event_time_missing_and_na():
    assert lf.format_event_time(None) == "N/A"
    assert lf.format_event_time("N/A") == "N/A"
    assert lf.format_event_time(None, fallback="prior") == "prior"


def test_format_event_time_unparseable_returns_fallback_or_raw():
    assert lf.format_event_time("not-a-date") == "not-a-date"
    assert lf.format_event_time("not-a-date", fallback="prior") == "prior"


def test_format_expiry_date_computes_from_time_plus_days():
    assert lf.format_expiry_date("2026-06-22T11:25:23.000Z", 17) == "Thu, 09 Jul 2026"


def test_format_expiry_date_handles_bad_input():
    assert lf.format_expiry_date(None, 17) is None
    assert lf.format_expiry_date("2026-06-22T11:25:23.000Z", "Unknown") is None


def test_cloudwatch_timestamp_rendered_with_weekday(invoke):
    _, post = invoke(sns_event(cw_message()))  # SNS Timestamp 2026-06-22T11:25:23.000Z
    _, _, blob = sent(post)
    assert "Mon, 22 Jun 2026 11:25:23 UTC" in blob


def test_s3_records_timestamp_rendered_with_weekday(invoke):
    _, post = invoke(sns_event(s3_records_message()))  # eventTime 2026-06-22T11:25:23.364Z
    _, _, blob = sent(post)
    assert "Mon, 22 Jun 2026 11:25:23 UTC" in blob  # was previously missing the weekday


def test_s3_detail_timestamp_rendered_with_weekday(invoke):
    _, post = invoke(sns_event(s3_detail_message()))  # time 2026-06-22T11:25:23.000Z
    _, _, blob = sent(post)
    assert "Mon, 22 Jun 2026 11:25:23 UTC" in blob  # was previously missing the weekday


def test_guardduty_seen_times_rendered_with_weekday(invoke):
    _, post = invoke(sns_event(guardduty_message()))
    _, _, blob = sent(post)
    assert "Sat, 20 Jun 2026 10:00:00 UTC" in blob  # eventFirstSeen
    assert "Mon, 22 Jun 2026 11:00:00 UTC" in blob  # eventLastSeen


# Pure payload builders — direct unit tests:


def test_build_guardduty():
    payload = lf.build_guardduty(guardduty_message())
    blob = json.dumps(payload)
    assert payload["blocks"][0]["text"]["text"].startswith(":small_red_triangle:")  # sev 8.0 -> High
    assert "GuardDuty Finding" in blob
    assert "High" in blob
    assert "Sat, 20 Jun 2026 10:00:00 UTC" in blob  # firstseen via format_event_time


def test_build_cloudwatch():
    payload = lf.build_cloudwatch("CW Notif", cw_message(), "ts", is_error=True)
    assert payload["blocks"][0]["text"]["text"] == "ALARM - my-cw-alarm"
    blob = json.dumps(payload)
    assert ":broken_heart:" in blob
    assert "InstanceId = i-0123456789" in blob


def test_build_s3_records_vs_detail_form():
    records_blob = json.dumps(lf.build_s3(s3_records_message(), "ts"))
    assert "AROAEXAMPLE:user" in records_blob  # principal present in Records form
    detail_blob = json.dumps(lf.build_s3(s3_detail_message(), "ts"))
    assert "Principal" not in detail_blob  # absent in detail form
    assert "my-bucket" in detail_blob


def test_build_cert():
    blob = json.dumps(lf.build_cert(acm_event()))  # DaysToExpiry 17.0
    assert "is expiring on Thu, 09 Jul 2026" in blob
    assert "*Days to Expiry:* 17" in blob
    assert "17.0" not in blob


def test_build_fallback():
    payload = lf.build_fallback("My Title", {"foo": "bar"})
    blob = json.dumps(payload)
    assert payload["blocks"][0]["text"]["text"] == "*My Title*"
    assert "foo" in blob and "bar" in blob


def test_truncate_helper():
    assert lf._truncate("short") == "short"
    out = lf._truncate("a" * 5000, limit=100)
    assert out.endswith("… (truncated)")
    assert len(out) <= 100 + len("\n… (truncated)")


def test_oversized_fallback_still_sends():
    # A huge event must be truncated to fit Slack's block limit and still deliver.
    svc = lf.NotificationService("https://hooks.test/x")
    post = mock.Mock(return_value=200)
    with mock.patch.object(lf, "_post", post):
        ok = svc.send_notification("Big", {"data": "x" * 10000}, "ts", "Unknown", False)
    assert ok is True
    _, payload = post.call_args.args
    text = payload["blocks"][1]["text"]["text"]
    assert len(text) < 3000
    assert "… (truncated)" in text


# Logging hygiene / DEBUG mode:


def test_stdout_is_emf_metrics_only(invoke, capsys):
    # The only thing on stdout is EMF metric JSON (no stray debug prints).
    invoke(sns_event(cw_message()))
    out = capsys.readouterr().out.strip()
    assert out  # at least NotificationsSent was emitted
    for line in out.splitlines():
        record = json.loads(line)  # raises on a stray non-JSON print
        assert "_aws" in record  # ...and it is EMF


def test_verbose_payload_logged_at_debug_not_info(invoke, caplog):
    with caplog.at_level(logging.DEBUG):
        invoke(sns_event(cw_message()))
    # the full alarm details dump is emitted at DEBUG
    debug_msgs = [r.getMessage() for r in caplog.records if r.levelno == logging.DEBUG]
    assert any("alarm_details:" in m for m in debug_msgs)
    # ...and never at INFO or above (no full-payload leak into normal logs)
    info_and_above = [r.getMessage() for r in caplog.records if r.levelno >= logging.INFO]
    assert not any("NewStateReason" in m for m in info_and_above)


def test_debug_mode_end_to_end(monkeypatch):
    # _DEBUG / the logger level are resolved at import; reload with DEBUG set to verify,
    # and run a full invocation so the gated tracemalloc start/stop path is exercised.
    monkeypatch.setenv("DEBUG", "true")
    monkeypatch.setenv("SECRET_NAME", "test-secret")
    try:
        importlib.reload(lf)
        assert lf._DEBUG is True
        assert logging.getLogger().level == logging.DEBUG

        client = mock.MagicMock()
        client.get_secret_value.return_value = {"SecretString": json.dumps(SECRETS)}
        post = mock.Mock(return_value=200)
        with mock.patch.object(lf.boto3, "client", return_value=client), mock.patch.object(lf, "_post", post):
            response = lf.lambda_handler(sns_event(cw_message()), FakeContext())
        assert response["statusCode"] == 200  # DEBUG mode (tracemalloc on) still works
        assert post.call_count == 1
    finally:
        monkeypatch.delenv("DEBUG", raising=False)
        importlib.reload(lf)  # restore INFO for the rest of the suite
    assert lf._DEBUG is False
    assert logging.getLogger().level == logging.INFO


# Transport retries:


class _Resp:
    status = 200

    def __enter__(self):
        return self

    def __exit__(self, *a):
        return False


def _http_error(code, retry_after=None):
    hdrs = Message()
    if retry_after is not None:
        hdrs["Retry-After"] = retry_after
    return urllib.error.HTTPError("http://slack.test", code, "err", hdrs, None)


def test_post_success_no_retry():
    with mock.patch("urllib.request.urlopen", return_value=_Resp()) as u, mock.patch.object(lf.time, "sleep") as sleep:
        assert lf._post("http://x", {"a": 1}) == 200
    assert u.call_count == 1
    sleep.assert_not_called()


def test_post_retries_on_429_then_succeeds():
    with (
        mock.patch("urllib.request.urlopen", side_effect=[_http_error(429, "0"), _Resp()]) as u,
        mock.patch.object(lf.time, "sleep") as sleep,
    ):
        assert lf._post("http://x", {}) == 200
    assert u.call_count == 2
    sleep.assert_called_once_with(0.0)  # Retry-After: 0 honoured


def test_post_retries_on_5xx_then_succeeds():
    with (
        mock.patch("urllib.request.urlopen", side_effect=[_http_error(503), _http_error(503), _Resp()]) as u,
        mock.patch.object(lf.time, "sleep"),
    ):
        assert lf._post("http://x", {}) == 200
    assert u.call_count == 3


def test_post_gives_up_after_max_attempts():
    with (
        mock.patch("urllib.request.urlopen", side_effect=[_http_error(503)] * 10) as u,
        mock.patch.object(lf.time, "sleep"),
    ):
        assert lf._post("http://x", {}) == 503
    assert u.call_count == lf._MAX_POST_ATTEMPTS


def test_post_does_not_retry_on_400():
    with (
        mock.patch("urllib.request.urlopen", side_effect=[_http_error(400)] * 5) as u,
        mock.patch.object(lf.time, "sleep") as sleep,
    ):
        assert lf._post("http://x", {}) == 400
    assert u.call_count == 1
    sleep.assert_not_called()


def test_post_retries_network_error_then_raises():
    err = urllib.error.URLError("connection reset")
    with mock.patch("urllib.request.urlopen", side_effect=[err] * 10) as u, mock.patch.object(lf.time, "sleep"):
        with pytest.raises(urllib.error.URLError):
            lf._post("http://x", {})
    assert u.call_count == lf._MAX_POST_ATTEMPTS


def test_parse_retry_after():
    assert lf._parse_retry_after("2") == 2.0
    assert lf._parse_retry_after("999") == lf._RETRY_AFTER_CAP_SECONDS  # capped
    assert lf._parse_retry_after(None) is None
    assert lf._parse_retry_after("Wed, 21 Oct 2026 07:28:00 GMT") is None  # HTTP-date form


# Suppression window & environments:


@contextlib.contextmanager
def env_reload(monkeypatch, **env):
    """Set env vars and reload lambda_function so its import-time config re-reads them.
    Restores default config (reload with the vars removed) on exit."""
    monkeypatch.setenv("SECRET_NAME", "test-secret")
    for key, value in env.items():
        monkeypatch.setenv(key, value)
    importlib.reload(lf)
    try:
        yield
    finally:
        for key in env:
            monkeypatch.delenv(key, raising=False)
        importlib.reload(lf)


def _run(event, post_status=200):
    """Invoke the handler with boto3 + _post mocked. Returns (response, post_mock)."""
    client = mock.MagicMock()
    client.get_secret_value.return_value = {"SecretString": json.dumps(SECRETS)}
    post = mock.Mock(return_value=post_status)
    with mock.patch.object(lf.boto3, "client", return_value=client), mock.patch.object(lf, "_post", post):
        response = lf.lambda_handler(event, FakeContext())
    return response, post


# _parse_hhmm:


@pytest.mark.parametrize(
    "value, expected",
    [
        ("19:30", 19 * 60 + 30),
        ("6:30", 6 * 60 + 30),
        ("18:00", 18 * 60),
        ("00:00", 0),
        ("23:59", 23 * 60 + 59),
        ("07:00", 7 * 60),
    ],
)
def test_parse_hhmm_valid(value, expected):
    assert lf._parse_hhmm(value) == expected


@pytest.mark.parametrize(
    "value",
    [
        "",
        None,
        "18",
        "6:30:00",
        "aa:bb",
        "06:99",
        "24:00",
        "-1:00",
        "12:60",
        "   ",
        "1830",
    ],
)
def test_parse_hhmm_invalid(value):
    assert lf._parse_hhmm(value) is None


# _in_suppression_window:


@pytest.mark.parametrize(
    "minute, start, end, expected",
    [
        # same-day window 09:00–17:00
        (8 * 60, 9 * 60, 17 * 60, False),
        (9 * 60, 9 * 60, 17 * 60, True),  # inclusive start
        (12 * 60, 9 * 60, 17 * 60, True),
        (17 * 60, 9 * 60, 17 * 60, False),  # exclusive end
        (18 * 60, 9 * 60, 17 * 60, False),
        # overnight window 19:30–06:30
        (19 * 60 + 29, 19 * 60 + 30, 6 * 60 + 30, False),
        (19 * 60 + 30, 19 * 60 + 30, 6 * 60 + 30, True),
        (0, 19 * 60 + 30, 6 * 60 + 30, True),
        (6 * 60 + 29, 19 * 60 + 30, 6 * 60 + 30, True),
        (6 * 60 + 30, 19 * 60 + 30, 6 * 60 + 30, False),  # exclusive end
        (12 * 60, 19 * 60 + 30, 6 * 60 + 30, False),
        # 24h window (start == end)
        (0, 18 * 60, 18 * 60, True),
        (12 * 60, 18 * 60, 18 * 60, True),
        (18 * 60, 18 * 60, 18 * 60, True),
        (23 * 60 + 59, 18 * 60, 18 * 60, True),
    ],
)
def test_in_suppression_window(minute, start, end, expected):
    assert lf._in_suppression_window(minute, start, end) is expected


# default-config behaviour (window 19:00–07:00, envs dev-/tst-/prep-):


def test_suppresses_all_states_for_suppressed_env_overnight(invoke):
    # ALARM (not just INSUFFICIENT_DATA) for a suppressed env at 03:00 -> suppressed.
    event = sns_event(cw_message(state="ALARM", name="dev-web-01"), timestamp="2026-06-22T03:00:00.000Z")
    response, post = invoke(event)
    assert post.call_count == 0
    assert response is None


def test_suppressed_env_within_business_hours_is_delivered(invoke):
    event = sns_event(cw_message(name="dev-web-01"), timestamp="2026-06-22T12:00:00.000Z")
    _, post = invoke(event)
    assert post.call_count == 1


def test_prod_never_suppressed_overnight(invoke):
    event = sns_event(cw_message(name="prod-web-01"), timestamp="2026-06-22T03:00:00.000Z")
    _, post = invoke(event)
    assert post.call_count == 1


# env-configured behaviour (reload):


def test_suppression_minute_precision(monkeypatch):
    with env_reload(monkeypatch, SUPPRESSION_TIME_START="19:30", SUPPRESSION_TIME_END="07:00"):
        _, post_before = _run(sns_event(cw_message(name="dev-x"), timestamp="2026-06-22T19:29:00.000Z"))
        resp_after, post_after = _run(sns_event(cw_message(name="dev-x"), timestamp="2026-06-22T19:31:00.000Z"))
    assert post_before.call_count == 1  # 19:29 — just before the window
    assert post_after.call_count == 0  # 19:31 — inside the window
    assert resp_after is None


def test_24h_suppression_when_start_equals_end(monkeypatch):
    with env_reload(monkeypatch, SUPPRESSION_TIME_START="18:00", SUPPRESSION_TIME_END="18:00"):
        assert lf._SUPPRESSION_WINDOW == (18 * 60, 18 * 60)
        response, post = _run(sns_event(cw_message(name="dev-x"), timestamp="2026-06-22T12:00:00.000Z"))
    assert post.call_count == 0  # midday still suppressed (24h/all-day)
    assert response is None


def test_empty_suppressed_environments_disables_suppression(monkeypatch):
    with env_reload(monkeypatch, SUPPRESSED_ENVIRONMENTS=""):
        assert lf._SUPPRESSED_ENVIRONMENTS == ()
        _, post = _run(sns_event(cw_message(name="dev-x"), timestamp="2026-06-22T03:00:00.000Z"))
    assert post.call_count == 1  # off-switch: delivered


def test_custom_suppressed_environments(monkeypatch):
    with env_reload(monkeypatch, SUPPRESSED_ENVIRONMENTS="staging-"):
        _, post_staging = _run(sns_event(cw_message(name="staging-x"), timestamp="2026-06-22T03:00:00.000Z"))
        _, post_dev = _run(sns_event(cw_message(name="dev-x"), timestamp="2026-06-22T03:00:00.000Z"))
    assert post_staging.call_count == 0  # now suppressed
    assert post_dev.call_count == 1  # no longer in the list -> delivered


# Invalid config: fail-safe + in-notification note:


def test_invalid_suppression_time_disables_and_annotates(monkeypatch):
    event = sns_event(cw_message(state="ALARM", name="dev-web-01"), timestamp="2026-06-22T03:00:00.000Z")
    with env_reload(monkeypatch, SUPPRESSION_TIME_END="06:99"):
        assert lf._SUPPRESSION_WINDOW is None  # suppression disabled
        assert "SUPPRESSION_TIME_END" in lf._SUPPRESSION_CONFIG_ERROR
        assert "suppression mechanism inactive" in lf._SUPPRESSION_CONFIG_ERROR
        response, post = _run(event)
    assert post.call_count == 1  # fail-safe: still delivered
    _, payload = post.call_args.args
    blob = json.dumps(payload)
    assert "Suppression config error" in blob
    assert "SUPPRESSION_TIME_END" in blob


def test_invalid_suppression_config_no_note_on_non_suppressed_env(monkeypatch):
    event = sns_event(cw_message(name="prod-web-01"), timestamp="2026-06-22T03:00:00.000Z")
    with env_reload(monkeypatch, SUPPRESSION_TIME_END="06:99"):
        _, post = _run(event)
    assert post.call_count == 1
    _, payload = post.call_args.args
    assert "Suppression config error" not in json.dumps(payload)  # prod- carries no note


def test_both_suppression_times_invalid_single_note_names_both(monkeypatch):
    event = sns_event(cw_message(name="dev-web-01"), timestamp="2026-06-22T03:00:00.000Z")
    with env_reload(monkeypatch, SUPPRESSION_TIME_START="7am", SUPPRESSION_TIME_END="06:99"):
        _, post = _run(event)
    _, payload = post.call_args.args
    error_blocks = [b for b in payload["blocks"] if "Suppression config error" in json.dumps(b)]
    assert len(error_blocks) == 1  # exactly one note, not two
    blob = json.dumps(error_blocks[0])
    assert "SUPPRESSION_TIME_START" in blob and "SUPPRESSION_TIME_END" in blob


# Console deep-link buttons:


def _action_blocks(payload):
    return [b for b in payload["blocks"] if b.get("type") == "actions"]


def _button_url(payload):
    return _action_blocks(payload)[0]["elements"][0]["url"]


# URL helpers:


def test_region_from_arn():
    assert lf._region_from_arn("arn:aws:cloudwatch:eu-west-2:111122223333:alarm:x") == "eu-west-2"
    assert lf._region_from_arn("arn:aws:s3:::bucket") is None  # S3 ARN has no region
    assert lf._region_from_arn("not-an-arn") is None
    assert lf._region_from_arn("") is None


def test_cloudwatch_alarm_url():
    url = lf._cloudwatch_alarm_url("eu-west-2", "my alarm/x")
    assert url is not None
    assert "eu-west-2.console.aws.amazon.com/cloudwatch" in url
    assert "region=eu-west-2" in url
    assert "my%20alarm%2Fx" in url  # url-encoded name
    assert lf._cloudwatch_alarm_url(None, "x") is None
    assert lf._cloudwatch_alarm_url("eu-west-2", "") is None


def test_guardduty_finding_url():
    url = lf._guardduty_finding_url("eu-west-2", "abc123")
    assert url is not None and "guardduty" in url and "fId=abc123" in url
    assert lf._guardduty_finding_url("", "abc") is None
    assert lf._guardduty_finding_url("eu-west-2", "") is None


def test_s3_object_url():
    url = lf._s3_object_url("eu-west-2", "my-bucket", "a/b.csv")
    assert url is not None
    assert "s3/object/my-bucket" in url
    assert "prefix=a%2Fb.csv" in url  # key url-encoded
    assert lf._s3_object_url("", "b", "k") is None
    assert lf._s3_object_url("eu-west-2", "b", "") is None


# Buttons appear on the right builders:


def test_build_cloudwatch_has_console_button():
    payload = lf.build_cloudwatch("CW", cw_message(), "ts", is_error=True)
    assert len(_action_blocks(payload)) == 1
    url = _button_url(payload)
    assert "cloudwatch" in url and "eu-west-2" in url and "my-cw-alarm" in url


def test_build_guardduty_has_console_button():
    payload = lf.build_guardduty(guardduty_message())
    assert len(_action_blocks(payload)) == 1
    url = _button_url(payload)
    assert "guardduty" in url and "2ab00f5a1b2c3d4e5f60718293a4b5c6" in url


def test_build_s3_records_has_console_button():
    payload = lf.build_s3(s3_records_message(), "ts")
    assert len(_action_blocks(payload)) == 1
    url = _button_url(payload)
    assert "s3/object/my-bucket" in url and "uploads%2Fdata.csv" in url


def test_build_s3_detail_has_console_button():
    payload = lf.build_s3(s3_detail_message(), "ts")
    assert len(_action_blocks(payload)) == 1
    assert "s3/object/my-bucket" in _button_url(payload)


# Graceful omission when identifiers are missing:


def test_no_button_when_alarm_arn_missing():
    details = cw_message()
    del details["AlarmArn"]
    payload = lf.build_cloudwatch("CW", details, "ts", is_error=True)
    assert _action_blocks(payload) == []


def test_no_button_when_guardduty_id_missing():
    msg = guardduty_message()
    del msg["detail"]["id"]
    assert _action_blocks(lf.build_guardduty(msg)) == []


def test_no_button_when_s3_region_missing():
    msg = s3_records_message()
    del msg["Records"][0]["awsRegion"]
    assert _action_blocks(lf.build_s3(msg, "ts")) == []


def test_cert_and_fallback_have_no_button():
    assert _action_blocks(lf.build_cert(acm_event())) == []
    assert _action_blocks(lf.build_fallback("T", {"x": 1})) == []


# Handler helper unit:


def test_extract_message_sns_notification():
    msg, sns = lf._extract_message(sns_event(cw_message()))
    assert json.loads(msg)["AlarmName"] == "my-cw-alarm"
    assert sns["Type"] == "Notification"


def test_extract_message_control_message_returns_none():
    assert lf._extract_message(sns_event(cw_message(), sns_type="SubscriptionConfirmation")) is None
    assert lf._extract_message(sns_event(cw_message(), sns_type="UnsubscribeConfirmation")) is None


def test_extract_message_eventbridge_cert():
    result = lf._extract_message(acm_event())
    assert result is not None
    msg, sns = result
    assert json.loads(msg)["source"] == "aws.acm"
    assert sns == {}  # EventBridge has no SNS envelope


def test_extract_message_unknown_shape_returns_none():
    assert lf._extract_message({"foo": "bar"}) is None
    assert lf._extract_message({"Records": []}) is None


def test_detect_source():
    assert lf._detect_source({"source": "aws.guardduty"}) == lf.Source.GUARDDUTY
    assert lf._detect_source(s3_records_message()) == lf.Source.S3  # via Records[0].eventSource
    assert lf._detect_source(cw_message()) == lf.Source.CLOUDWATCH  # by AlarmName/NewStateValue shape
    assert lf._detect_source({"hello": "world"}) is None


def test_looks_like_cloudwatch_alarm():
    assert lf._looks_like_cloudwatch_alarm({"AlarmName": "x", "NewStateValue": "ALARM"}) is True
    assert lf._looks_like_cloudwatch_alarm({"AlarmName": "x"}) is False
    assert lf._looks_like_cloudwatch_alarm({}) is False


def test_s3_event_timestamp():
    assert lf._s3_event_timestamp(s3_records_message()) == "2026-06-22T11:25:23.364Z"  # from record
    assert lf._s3_event_timestamp(s3_detail_message()) == "2026-06-22T11:25:23.000Z"  # top-level time


def test_should_suppress():
    # default config: suppressed envs dev-/tst-/prep-, window 19:00–07:00 UTC
    at_0300 = lf.datetime(2026, 6, 22, 3, 0, tzinfo=lf.timezone.utc)
    at_noon = lf.datetime(2026, 6, 22, 12, 0, tzinfo=lf.timezone.utc)
    assert lf._should_suppress("dev-web", at_0300) is True  # suppressed env, in window
    assert lf._should_suppress("dev-web", at_noon) is False  # out of window
    assert lf._should_suppress("prod-web", at_0300) is False  # not a suppressed env


# EMF metrics:


def test_emit_metric_emf_format(capsys):
    lf._emit_metric("NotificationsSent", "CloudWatch Alarm")
    record = json.loads(capsys.readouterr().out.strip())
    directive = record["_aws"]["CloudWatchMetrics"][0]
    assert directive["Namespace"] == lf._METRICS_NAMESPACE
    assert directive["Metrics"][0] == {"Name": "NotificationsSent", "Unit": "Count"}
    assert directive["Dimensions"] == [["EventType"]]
    assert record["EventType"] == "CloudWatch Alarm"
    assert record["NotificationsSent"] == 1
    assert isinstance(record["_aws"]["Timestamp"], int)


def test_emit_metric_respects_disabled_flag(capsys, monkeypatch):
    monkeypatch.setattr(lf, "_METRICS_ENABLED", False)
    lf._emit_metric("NotificationsSent", "X")
    assert capsys.readouterr().out == ""


def _emitted_names(emit_mock):
    return [call.args[0] for call in emit_mock.call_args_list]


def test_metric_notifications_sent(invoke):
    with mock.patch.object(lf, "_emit_metric") as emit:
        invoke(sns_event(cw_message()))
    assert "NotificationsSent" in _emitted_names(emit)


def test_metric_notifications_failed(monkeypatch):
    monkeypatch.setenv("SECRET_NAME", "test-secret")
    client = mock.MagicMock()
    client.get_secret_value.return_value = {"SecretString": json.dumps(SECRETS)}
    with (
        mock.patch.object(lf.boto3, "client", return_value=client),
        mock.patch.object(lf, "_post", mock.Mock(return_value=500)),
        mock.patch.object(lf, "_emit_metric") as emit,
    ):
        with pytest.raises(lf.SlackNotificationError):
            lf.lambda_handler(sns_event(cw_message()), FakeContext())
    assert "NotificationsFailed" in _emitted_names(emit)


def test_metric_alarms_suppressed(invoke):
    event = sns_event(cw_message(name="dev-x"), timestamp="2026-06-22T03:00:00.000Z")
    with mock.patch.object(lf, "_emit_metric") as emit:
        invoke(event)
    assert "AlarmsSuppressed" in _emitted_names(emit)


def test_metric_events_skipped(invoke):
    with mock.patch.object(lf, "_emit_metric") as emit:
        invoke({"foo": "bar"})  # unrecognised shape -> skipped
    assert "EventsSkipped" in _emitted_names(emit)
