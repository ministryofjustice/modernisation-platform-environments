import errno
import io
import stat
from types import SimpleNamespace
from unittest.mock import Mock

import pytest

from mft_writer import sftp
from mft_writer.errors import DeadlineExceeded, InvalidMessage


@pytest.fixture
def route():
    return {"relative_key": "nested/file.csv", "destination_path": "incoming/nested/file.csv",
            "credential_arn": "private-key", "destination": {"destination_prefix": "incoming/"}}


@pytest.fixture
def client():
    client = Mock()
    client.normalize.side_effect = lambda path: "/home/delivery" if path == "." else path
    def lstat(path):
        if path.endswith("file.csv"):
            raise FileNotFoundError(errno.ENOENT, "missing")
        return SimpleNamespace(st_mode=stat.S_IFDIR | 0o700)
    client.lstat.side_effect = lstat
    client.stat.return_value.st_size = 3
    remote = Mock()
    remote.__enter__ = Mock(return_value=remote)
    remote.__exit__ = Mock(return_value=False)
    client.open.return_value = remote
    return client


def test_stream_then_atomic_overwrite(client, route):
    assert sftp.upload_stream(client, io.BytesIO(b"abc"), 3, route, None) == 3
    temporary = client.open.call_args.args[0]
    assert temporary.startswith("/home/delivery/incoming/nested/.mft-")
    assert client.open.call_args.args[1] == "wx"
    client.open.return_value.write.assert_called_once_with(b"abc")
    client.posix_rename.assert_called_once_with(temporary, "/home/delivery/incoming/nested/file.csv")
    client.remove.assert_not_called()


@pytest.mark.parametrize("failure", ["write", "size", "rename", "close"])
def test_failed_upload_is_not_success(client, route, failure):
    if failure == "write":
        client.open.return_value.write.side_effect = OSError("write failed")
    elif failure == "size":
        client.stat.return_value.st_size = 2
    elif failure == "rename":
        client.posix_rename.side_effect = OSError("unsupported extension")
    else:
        client.open.return_value.__exit__.side_effect = OSError("close failed")
    with pytest.raises((OSError, InvalidMessage)):
        sftp.upload_stream(client, io.BytesIO(b"abc"), 3, route, None)
    client.remove.assert_called_once()
    if failure != "rename":
        client.posix_rename.assert_not_called()
    client.rename.assert_not_called()


def test_symlink_directory_rejected(client, route):
    client.lstat.return_value = SimpleNamespace(st_mode=stat.S_IFLNK | 0o700)
    client.lstat.side_effect = None
    with pytest.raises(InvalidMessage):
        sftp.upload_stream(client, io.BytesIO(b"abc"), 3, route, None)
    client.open.assert_not_called()


def test_dns_address_allowlist(monkeypatch):
    monkeypatch.setattr(sftp.socket, "getaddrinfo", lambda *args: [(None, None, None, None, ("203.0.113.1", 22))])
    with pytest.raises(InvalidMessage):
        sftp.approved_addresses({"hostname": "example.com", "port": 22, "destination_cidr_blocks": ["192.0.2.0/24"]})


def test_untrusted_host_is_rejected_before_authentication(monkeypatch):
    from contextlib import ExitStack
    connection = Mock()
    connection.getpeername.return_value = ("192.0.2.1", 22)
    transport = Mock()
    transport.get_remote_server_key.return_value.asbytes.return_value = b"wrong-server-key"
    monkeypatch.setattr(sftp, "approved_addresses", lambda destination: ["192.0.2.1"])
    monkeypatch.setattr(sftp, "trusted_host_keys", lambda keys: [SimpleNamespace(asbytes=lambda: b"trusted-server-key")])
    monkeypatch.setattr(sftp.socket, "create_connection", lambda *args, **kwargs: connection)
    monkeypatch.setattr(sftp.paramiko, "Transport", lambda connection: transport)
    with ExitStack() as stack, pytest.raises(InvalidMessage):
        sftp.connect_sftp({"port": 22, "host_public_keys": [], "username": "delivery"}, Mock(), None, stack)
    transport.auth_publickey.assert_not_called()
    transport.close.assert_called_once()
    connection.close.assert_called_once()


def test_handler_imports():
    import handler
    import reporter_handler
    assert callable(handler.lambda_handler)
    assert callable(reporter_handler.lambda_handler)


def test_each_transfer_reads_fresh_current_key_and_exact_source(monkeypatch, route):
    secrets = Mock()
    secrets.get_secret_value.side_effect = [{"key": "first"}, {"key": "rotated"}]
    s3 = Mock()
    s3.get_object.side_effect = [{"VersionId": "v1", "ContentLength": 3, "Body": Mock()} for _ in range(2)]
    loaded = Mock()
    monkeypatch.setattr(sftp, "load_private_key", loaded)
    monkeypatch.setattr(sftp, "connect_sftp", Mock())
    monkeypatch.setattr(sftp, "upload_stream", Mock(return_value=3))
    source = {"bucket": "clean", "key": "identity/file.csv", "versionId": "v1", "sizeBytes": 3}
    for _ in range(2):
        assert sftp.transfer_versioned_object(s3, secrets, source, route, None) == 3
    assert [call.args[0] for call in loaded.call_args_list] == [{"key": "first"}, {"key": "rotated"}]
    assert all(call.kwargs == {"SecretId": "private-key", "VersionStage": "AWSCURRENT"} for call in secrets.get_secret_value.call_args_list)
    assert all(call.kwargs == {"Bucket": "clean", "Key": "identity/file.csv", "VersionId": "v1"} for call in s3.get_object.call_args_list)


def test_mismatched_source_closes_body_before_connecting(monkeypatch, route):
    secrets = Mock()
    s3 = Mock()
    body = Mock()
    s3.get_object.return_value = {"VersionId": "wrong", "ContentLength": 3, "Body": body}
    monkeypatch.setattr(sftp, "load_private_key", Mock())
    connect = Mock()
    monkeypatch.setattr(sftp, "connect_sftp", connect)
    with pytest.raises(InvalidMessage):
        sftp.transfer_versioned_object(s3, secrets, {"bucket": "clean", "key": "file", "versionId": "v1", "sizeBytes": 3}, route, None)
    body.close.assert_called_once()
    connect.assert_not_called()


def test_private_key_loaded_in_memory_with_passphrase():
    import json
    import paramiko
    key = paramiko.RSAKey.generate(2048)
    output = io.StringIO()
    key.write_private_key(output, password="test-passphrase")
    response = {"VersionStages": ["AWSCURRENT"], "SecretString": json.dumps({"private_key": output.getvalue(), "passphrase": "test-passphrase"})}
    assert sftp.load_private_key(response).asbytes() == key.asbytes()
    response["VersionStages"] = ["AWSPREVIOUS"]
    with pytest.raises(InvalidMessage):
        sftp.load_private_key(response)


def test_existing_same_sized_destination_still_uploads_and_overwrites(client, route):
    client.lstat.side_effect = lambda path: SimpleNamespace(
        st_mode=(stat.S_IFREG if path.endswith("file.csv") else stat.S_IFDIR) | 0o700,
        st_size=3,
    )
    assert sftp.upload_stream(client, io.BytesIO(b"new"), 3, route, None) == 3
    client.open.return_value.write.assert_called_once_with(b"new")
    client.posix_rename.assert_called_once()


def test_symlink_final_destination_rejected(client, route):
    client.lstat.side_effect = lambda path: SimpleNamespace(
        st_mode=(stat.S_IFLNK if path.endswith("file.csv") else stat.S_IFDIR) | 0o700
    )
    with pytest.raises(InvalidMessage):
        sftp.upload_stream(client, io.BytesIO(b"abc"), 3, route, None)
    client.open.assert_not_called()


def test_missing_base_is_not_created(client, route):
    client.lstat.side_effect = FileNotFoundError(errno.ENOENT, "missing base")
    with pytest.raises(FileNotFoundError):
        sftp.upload_stream(client, io.BytesIO(b"abc"), 3, route, None)
    client.mkdir.assert_not_called()


def test_missing_nested_directory_is_created(client, route):
    def lstat(path):
        if path.endswith("/nested") and not client.mkdir.called:
            raise FileNotFoundError(errno.ENOENT, "missing nested directory")
        if path.endswith("file.csv"):
            raise FileNotFoundError(errno.ENOENT, "missing file")
        return SimpleNamespace(st_mode=stat.S_IFDIR | 0o700)

    client.lstat.side_effect = lstat
    assert sftp.upload_stream(client, io.BytesIO(b"abc"), 3, route, None) == 3
    client.mkdir.assert_called_once_with("/home/delivery/incoming/nested", mode=0o700)


def test_remote_canonical_escape_rejected(client, route):
    client.normalize.side_effect = lambda path: "/home/delivery" if path == "." else "/outside"
    with pytest.raises(InvalidMessage):
        sftp.upload_stream(client, io.BytesIO(b"abc"), 3, route, None)
    client.open.assert_not_called()


def test_bounded_streaming(client, route):
    payload = b"a" * (sftp.CHUNK_BYTES + 7)
    body = Mock(wraps=io.BytesIO(payload))
    client.stat.return_value.st_size = len(payload)
    assert sftp.upload_stream(client, body, len(payload), route, None) == len(payload)
    assert all(call.args == (sftp.CHUNK_BYTES,) for call in body.read.call_args_list)
    assert [len(call.args[0]) for call in client.open.return_value.write.call_args_list] == [sftp.CHUNK_BYTES, 7]


@pytest.mark.parametrize("payload", [b"ab", b"abcd"])
def test_short_or_oversized_source_is_not_published(client, route, payload):
    with pytest.raises(InvalidMessage):
        sftp.upload_stream(client, io.BytesIO(payload), 3, route, None)
    client.posix_rename.assert_not_called()
    client.remove.assert_called_once()


def test_stream_deadline_prevents_upload(client, route):
    context = SimpleNamespace(get_remaining_time_in_millis=lambda: 90_000)
    with pytest.raises(TimeoutError):
        sftp.upload_stream(client, io.BytesIO(b"abc"), 3, route, context)
    client.open.assert_not_called()


def test_slow_writes_recheck_the_deadline_between_sftp_requests(client, route):
    remaining = Mock(return_value=91_000)
    context = SimpleNamespace(get_remaining_time_in_millis=remaining)
    payload = b"x" * (256 * 1024)
    body = Mock(wraps=io.BytesIO(payload))
    client.stat.return_value.st_size = len(payload)

    def slow_write(_chunk):
        remaining.return_value -= 14_000

    remote = client.open.return_value
    remote.write.side_effect = slow_write
    assert sftp.CHUNK_BYTES <= sftp.paramiko.SFTPFile.MAX_REQUEST_SIZE
    with pytest.raises(DeadlineExceeded, match="SFTP streaming"):
        sftp.upload_stream(client, body, len(payload), route, context)
    remote.write.assert_called_once_with(payload[:32 * 1024])
    assert body.read.call_count == 1
    assert remaining.return_value == 77_000
    client.posix_rename.assert_not_called()
    client.remove.assert_called_once()


def test_deadline_is_rechecked_after_reading_the_source(client, route):
    remaining = Mock(return_value=91_000)
    context = SimpleNamespace(get_remaining_time_in_millis=remaining)

    def slow_read(_size):
        remaining.return_value = 90_000
        return b"abc"

    body = Mock()
    body.read.side_effect = slow_read
    with pytest.raises(DeadlineExceeded, match="SFTP write"):
        sftp.upload_stream(client, body, 3, route, context)
    client.open.return_value.write.assert_not_called()
    client.posix_rename.assert_not_called()
    client.remove.assert_called_once()


@pytest.mark.parametrize("exhaust_after", ["close", "stat"])
def test_sftp_finalisation_preserves_the_deadline_reserve(client, route, exhaust_after):
    remaining = Mock(return_value=91_000)
    context = SimpleNamespace(get_remaining_time_in_millis=remaining)

    def exhaust_time(*_args):
        remaining.return_value = 90_000
        return SimpleNamespace(st_size=3) if exhaust_after == "stat" else None

    if exhaust_after == "close":
        client.open.return_value.__exit__.side_effect = exhaust_time
    else:
        client.stat.side_effect = exhaust_time
    with pytest.raises(DeadlineExceeded):
        sftp.upload_stream(client, io.BytesIO(b"abc"), 3, route, context)
    if exhaust_after == "close":
        client.stat.assert_not_called()
    client.posix_rename.assert_not_called()
    client.remove.assert_called_once()


def test_raw_paramiko_logs_do_not_propagate(monkeypatch):
    import logging
    from contextlib import ExitStack

    output = io.StringIO()
    root_logger = logging.getLogger()
    capture = logging.StreamHandler(output)
    monkeypatch.setattr(sftp, "trusted_host_keys", Mock(side_effect=InvalidMessage("missing host key")))
    root_logger.addHandler(capture)
    try:
        root_logger.error("ROOT-LOGGING-CONTROL")
        with ExitStack() as stack, pytest.raises(InvalidMessage):
            sftp.connect_sftp({"host_public_keys": []}, Mock(), None, stack)
        logging.getLogger("paramiko.transport").error("PRIVATE-AUTHENTICATION-MATERIAL")
    finally:
        root_logger.removeHandler(capture)
        capture.close()
    assert "ROOT-LOGGING-CONTROL" in output.getvalue()
    assert "PRIVATE-AUTHENTICATION-MATERIAL" not in output.getvalue()


@pytest.mark.parametrize("setup_fails", [False, True])
def test_session_setup_is_time_bounded_and_resources_close(monkeypatch, setup_fails):
    from contextlib import ExitStack

    connection, transport, client, timer = Mock(), Mock(), Mock(), Mock()
    connection.getpeername.return_value = ("192.0.2.1", 22)
    transport.get_remote_server_key.return_value.asbytes.return_value = b"trusted"
    monkeypatch.setattr(sftp, "approved_addresses", lambda destination: ["192.0.2.1"])
    monkeypatch.setattr(sftp, "trusted_host_keys", lambda keys: [SimpleNamespace(asbytes=lambda: b"trusted")])
    monkeypatch.setattr(sftp.socket, "create_connection", lambda *args, **kwargs: connection)
    monkeypatch.setattr(sftp.paramiko, "Transport", lambda connection: transport)
    timer_factory = Mock(return_value=timer)
    monkeypatch.setattr(sftp.threading, "Timer", timer_factory)
    open_client = Mock(return_value=client, side_effect=TimeoutError("setup timeout") if setup_fails else None)
    monkeypatch.setattr(sftp.paramiko.SFTPClient, "from_transport", open_client)
    destination = {"port": 22, "host_public_keys": [], "username": "delivery"}
    if setup_fails:
        with ExitStack() as stack, pytest.raises(TimeoutError):
            sftp.connect_sftp(destination, Mock(), None, stack)
    else:
        with ExitStack() as stack:
            assert sftp.connect_sftp(destination, Mock(), None, stack) is client
        client.close.assert_called_once()
        client.get_channel.return_value.settimeout.assert_called_once_with(sftp.IO_TIMEOUT)
    timer_factory.assert_called_once_with(sftp.IO_TIMEOUT, transport.close)
    timer.start.assert_called_once()
    timer.cancel.assert_called_once()
    transport.close.assert_called_once()
    connection.close.assert_called_once()