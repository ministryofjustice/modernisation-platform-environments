import errno
import io
import stat
from contextlib import ExitStack
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
    transport.get_security_options.return_value.key_types = ("ssh-ed25519",)
    monkeypatch.setattr(sftp, "approved_addresses", lambda destination: ["192.0.2.1"])
    monkeypatch.setattr(sftp, "trusted_host_keys", lambda keys: [
        SimpleNamespace(asbytes=lambda: b"trusted-server-key", get_name=lambda: "ssh-ed25519"),
    ])
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
    transport.get_security_options.return_value.key_types = ("ssh-ed25519",)
    monkeypatch.setattr(sftp, "approved_addresses", lambda destination: ["192.0.2.1"])
    monkeypatch.setattr(sftp, "trusted_host_keys", lambda keys: [
        SimpleNamespace(asbytes=lambda: b"trusted", get_name=lambda: "ssh-ed25519"),
    ])
    monkeypatch.setattr(sftp.socket, "create_connection", lambda *args, **kwargs: connection)
    monkeypatch.setattr(sftp.paramiko, "Transport", lambda connection: transport)
    timer_factory = Mock(return_value=timer)
    monkeypatch.setattr(sftp.threading, "Timer", timer_factory)
    open_client = Mock(return_value=client, side_effect=TimeoutError("setup timeout") if setup_fails else None)
    monkeypatch.setattr(sftp.paramiko.SFTPClient, "from_transport", open_client)
    destination = {"port": 22, "host_public_keys": [], "username": "delivery"}
    if setup_fails:
        with ExitStack() as stack, pytest.raises(ConnectionError) as error:
            sftp.connect_sftp(destination, Mock(), None, stack)
        assert isinstance(error.value.__cause__, TimeoutError)
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


@pytest.fixture
def sftp_attempts(monkeypatch):
    addresses = ["192.0.2.1", "192.0.2.2"]
    connections = [Mock() for _ in addresses]
    transports = [Mock() for _ in addresses]
    clients = [Mock() for _ in addresses]
    timers = [Mock() for _ in addresses]
    options = [
        SimpleNamespace(key_types=(
            "ssh-ed25519", "ecdsa-sha2-nistp256", "rsa-sha2-512", "rsa-sha2-256", "ssh-rsa",
        )) for _ in addresses
    ]
    pins = [SimpleNamespace(asbytes=lambda: b"trusted", get_name=lambda: "ssh-ed25519")]
    for index, address in enumerate(addresses):
        connections[index].getpeername.return_value = (address, 22)
        transports[index].get_remote_server_key.return_value.asbytes.return_value = b"trusted"
        transports[index].get_security_options.return_value = options[index]
    monkeypatch.setattr(sftp, "approved_addresses", lambda destination: addresses)
    monkeypatch.setattr(sftp, "trusted_host_keys", lambda keys: pins)
    socket_factory = Mock(side_effect=connections)
    transport_factory = Mock(side_effect=transports)
    client_factory = Mock(side_effect=clients)
    timer_factory = Mock(side_effect=timers)
    warnings = Mock()
    monkeypatch.setattr(sftp.socket, "create_connection", socket_factory)
    monkeypatch.setattr(sftp.paramiko, "Transport", transport_factory)
    monkeypatch.setattr(sftp.paramiko.SFTPClient, "from_transport", client_factory)
    monkeypatch.setattr(sftp.threading, "Timer", timer_factory)
    monkeypatch.setattr(sftp.logger, "warning", warnings)
    return SimpleNamespace(
        addresses=addresses, connections=connections, transports=transports,
        clients=clients, timers=timers, options=options, pins=pins,
        socket_factory=socket_factory, transport_factory=transport_factory,
        client_factory=client_factory, timer_factory=timer_factory, warnings=warnings,
        destination={"port": 22, "host_public_keys": [], "username": "delivery"},
    )


@pytest.mark.parametrize("stage, error", [
    ("connect", ConnectionRefusedError("private endpoint details")),
    ("negotiate", TimeoutError("private endpoint details")),
    ("negotiate", EOFError("private endpoint details")),
    ("negotiate", sftp.paramiko.SSHException("private endpoint details")),
    ("host-key-read", sftp.paramiko.SSHException("private endpoint details")),
    ("authenticate", ConnectionResetError("private endpoint details")),
    ("open-session", TimeoutError("private endpoint details")),
    ("open-session", EOFError("private endpoint details")),
    ("open-session", sftp.paramiko.SSHException("private endpoint details")),
    ("channel-timeout", OSError("private endpoint details")),
])
def test_transient_setup_failure_tries_the_next_address_after_cleanup(sftp_attempts, stage, error):
    setup = sftp_attempts
    if stage == "negotiate":
        setup.transports[0].start_client.side_effect = error
    elif stage == "host-key-read":
        setup.transports[0].get_remote_server_key.side_effect = error
    elif stage == "authenticate":
        setup.transports[0].auth_publickey.side_effect = error
    elif stage == "open-session":
        setup.client_factory.side_effect = [error, setup.clients[1]]
    elif stage == "channel-timeout":
        setup.clients[0].get_channel.return_value.settimeout.side_effect = error
    if stage not in {"open-session", "channel-timeout"}:
        setup.client_factory.side_effect = [setup.clients[1]]

    def connect(address, *, timeout):
        index = setup.addresses.index(address[0])
        assert timeout == sftp.CONNECT_TIMEOUT
        if index == 0 and stage == "connect":
            raise error
        if index == 1 and stage != "connect":
            setup.connections[0].close.assert_called_once()
            setup.transports[0].close.assert_called_once()
            if stage == "channel-timeout":
                setup.clients[0].close.assert_called_once()
        return setup.connections[index]

    setup.socket_factory.side_effect = connect
    if stage == "connect":
        setup.transport_factory.side_effect = [setup.transports[1]]
    with ExitStack() as stack:
        assert sftp.connect_sftp(setup.destination, Mock(), None, stack) is setup.clients[1]
        assert [call.args[0][0] for call in setup.socket_factory.call_args_list] == setup.addresses
        setup.clients[1].close.assert_not_called()
        setup.transports[1].close.assert_not_called()
        setup.connections[1].close.assert_not_called()
    setup.clients[1].close.assert_called_once()
    setup.transports[1].close.assert_called_once()
    setup.connections[1].close.assert_called_once()
    for timer in setup.timers[:setup.timer_factory.call_count]:
        timer.start.assert_called_once()
        timer.cancel.assert_called_once()
    setup.warnings.assert_called_once()
    assert setup.warnings.call_args.kwargs["errorType"] == type(error).__name__
    assert "private endpoint details" not in str(setup.warnings.call_args)


@pytest.mark.parametrize("failure", [
    "host-key", "peer-address", "authentication", "authentication-timeout", "incompatible-algorithms",
    "protocol-order", "deadline-authentication", "deadline-session",
])
def test_fatal_setup_failures_never_try_another_address(sftp_attempts, failure):
    setup = sftp_attempts
    context = SimpleNamespace(get_remaining_time_in_millis=lambda: 900_000)
    if failure == "host-key":
        setup.transports[0].get_remote_server_key.return_value.asbytes.return_value = b"wrong"
        expected = InvalidMessage
    elif failure == "peer-address":
        setup.connections[0].getpeername.return_value = ("203.0.113.1", 22)
        expected = InvalidMessage
    elif failure in {"authentication", "authentication-timeout"}:
        message = "Authentication timeout." if failure == "authentication-timeout" else "rejected"
        setup.transports[0].auth_publickey.side_effect = sftp.paramiko.AuthenticationException(message)
        expected = sftp.paramiko.AuthenticationException
    elif failure == "incompatible-algorithms":
        setup.transports[0].start_client.side_effect = sftp.IncompatiblePeer("no common algorithms")
        expected = sftp.IncompatiblePeer
    elif failure == "protocol-order":
        setup.transports[0].start_client.side_effect = sftp.MessageOrderError("unexpected message")
        expected = sftp.MessageOrderError
    else:
        def exhaust_time(*_args, **_kwargs):
            context.get_remaining_time_in_millis = lambda: 90_000
        operation = (
            setup.transports[0].get_remote_server_key
            if failure == "deadline-authentication" else setup.transports[0].auth_publickey
        )
        if failure == "deadline-authentication":
            def read_key():
                exhaust_time()
                return SimpleNamespace(asbytes=lambda: b"trusted")
            operation.side_effect = read_key
        else:
            operation.side_effect = exhaust_time
        expected = DeadlineExceeded
    with ExitStack() as stack, pytest.raises(expected):
        sftp.connect_sftp(setup.destination, Mock(), context, stack)
    setup.socket_factory.assert_called_once()
    setup.connections[0].close.assert_called_once()
    if failure != "peer-address":
        setup.transports[0].close.assert_called_once()
    setup.client_factory.assert_not_called()
    setup.warnings.assert_not_called()
    if failure in {"host-key", "peer-address", "deadline-authentication"}:
        setup.transports[0].auth_publickey.assert_not_called()


def test_fallback_stops_when_the_remaining_time_is_exhausted(sftp_attempts):
    setup = sftp_attempts
    context = SimpleNamespace(get_remaining_time_in_millis=lambda: 91_000)

    def fail_handshake(*_args, **_kwargs):
        context.get_remaining_time_in_millis = lambda: 90_000
        raise TimeoutError("negotiation timeout")

    setup.transports[0].start_client.side_effect = fail_handshake
    with ExitStack() as stack, pytest.raises(DeadlineExceeded):
        sftp.connect_sftp(setup.destination, Mock(), context, stack)
    setup.socket_factory.assert_called_once()
    setup.transports[0].close.assert_called_once()
    setup.connections[0].close.assert_called_once()


def test_exhausted_approved_addresses_raise_with_the_last_error(sftp_attempts):
    setup = sftp_attempts
    errors = [TimeoutError("timeout"), EOFError("disconnected")]
    for transport, error in zip(setup.transports, errors):
        transport.start_client.side_effect = error
    with ExitStack() as stack, pytest.raises(ConnectionError) as error:
        sftp.connect_sftp(setup.destination, Mock(), None, stack)
    assert error.value.__cause__ is errors[-1]
    assert setup.socket_factory.call_count == 2
    assert setup.warnings.call_count == 2
    setup.client_factory.assert_not_called()
    for connection, transport in zip(setup.connections, setup.transports):
        connection.close.assert_called_once()
        transport.close.assert_called_once()


@pytest.mark.parametrize("pinned_types, expected", [
    (["ssh-rsa"], ("rsa-sha2-512", "rsa-sha2-256", "ssh-rsa")),
    (["ssh-ed25519"], ("ssh-ed25519",)),
    (["ecdsa-sha2-nistp256"], ("ecdsa-sha2-nistp256",)),
    (["ssh-rsa", "ssh-ed25519"], ("ssh-ed25519", "rsa-sha2-512", "rsa-sha2-256", "ssh-rsa")),
])
def test_host_key_negotiation_uses_only_pinned_types(sftp_attempts, pinned_types, expected):
    setup = sftp_attempts
    setup.pins[:] = [
        SimpleNamespace(asbytes=lambda: b"trusted", get_name=lambda name=name: name)
        for name in pinned_types
    ]

    def negotiate(*, timeout):
        assert setup.options[0].key_types == expected
        assert timeout == sftp.CONNECT_TIMEOUT

    setup.transports[0].start_client.side_effect = negotiate
    with ExitStack() as stack:
        assert sftp.connect_sftp(setup.destination, Mock(), None, stack) is setup.clients[0]
    setup.transports[0].get_remote_server_key.assert_called_once()
    setup.transports[0].auth_publickey.assert_called_once()
    setup.socket_factory.assert_called_once()


def test_unsupported_pin_type_fails_before_negotiation(sftp_attempts):
    setup = sftp_attempts
    setup.pins[:] = [SimpleNamespace(get_name=lambda: "unsupported-key-type")]
    with ExitStack() as stack, pytest.raises(InvalidMessage, match="no supported"):
        sftp.connect_sftp(setup.destination, Mock(), None, stack)
    setup.socket_factory.assert_called_once()
    setup.transports[0].start_client.assert_not_called()
    setup.transports[0].auth_publickey.assert_not_called()
    setup.transports[0].close.assert_called_once()
    setup.connections[0].close.assert_called_once()


def test_missing_sftp_client_tries_the_next_address(sftp_attempts):
    setup = sftp_attempts
    setup.client_factory.side_effect = [None, setup.clients[1]]
    with ExitStack() as stack:
        assert sftp.connect_sftp(setup.destination, Mock(), None, stack) is setup.clients[1]
        setup.transports[0].close.assert_called_once()
        setup.connections[0].close.assert_called_once()
        setup.clients[0].close.assert_not_called()
    assert setup.socket_factory.call_count == 2
    for timer in setup.timers:
        timer.cancel.assert_called_once()


def test_upload_error_does_not_trigger_address_fallback(sftp_attempts, monkeypatch):
    setup = sftp_attempts
    body = io.BytesIO(b"abc")
    s3, secrets = Mock(), Mock()
    s3.get_object.return_value = {"VersionId": "v1", "ContentLength": 3, "Body": body}
    monkeypatch.setattr(sftp, "load_private_key", Mock())
    monkeypatch.setattr(sftp, "upload_stream", Mock(side_effect=OSError("upload failed")))
    route = {"credential_arn": "test-key", "destination": setup.destination}
    source = {"bucket": "clean", "key": "identity/file.csv", "versionId": "v1", "sizeBytes": 3}
    with pytest.raises(OSError, match="upload failed"):
        sftp.transfer_versioned_object(s3, secrets, source, route, None)
    setup.socket_factory.assert_called_once()
    setup.clients[0].close.assert_called_once()
    setup.transports[0].close.assert_called_once()
    setup.connections[0].close.assert_called_once()
    assert body.closed


@pytest.mark.parametrize("algorithm", ["rsa-sha2-512", "rsa-sha2-256", "ssh-ed25519"])
def test_real_ssh_negotiation_selects_a_pinned_key_from_multiple_server_keys(monkeypatch, algorithm):
    from cryptography.hazmat.primitives import serialization
    from cryptography.hazmat.primitives.asymmetric.ed25519 import Ed25519PrivateKey

    rsa = sftp.paramiko.RSAKey.generate(2048)
    ed25519 = sftp.paramiko.Ed25519Key.from_private_key(io.StringIO(
        Ed25519PrivateKey.generate().private_bytes(
            serialization.Encoding.PEM,
            serialization.PrivateFormat.OpenSSH,
            serialization.NoEncryption(),
        ).decode()
    ))
    pin = ed25519 if algorithm == "ssh-ed25519" else rsa
    with ExitStack() as stack:
        client_socket, server_socket = sftp.socket.socketpair()
        stack.callback(client_socket.close)
        stack.callback(server_socket.close)
        server = sftp.paramiko.Transport(server_socket)
        transport = sftp.paramiko.Transport(client_socket)
        stack.callback(server.close)
        stack.callback(transport.close)
        server.add_server_key(rsa)
        server.add_server_key(ed25519)
        server.get_security_options().key_types = (
            ("ssh-ed25519",) if algorithm == "ssh-ed25519" else ("ssh-ed25519", algorithm)
        )
        server.start_server(event=sftp.threading.Event())
        connection = Mock()
        connection.getpeername.return_value = ("192.0.2.1", 22)
        connection.close.side_effect = client_socket.close
        client = Mock()
        monkeypatch.setattr(sftp.socket, "create_connection", Mock(return_value=connection))
        monkeypatch.setattr(sftp.paramiko, "Transport", Mock(return_value=transport))
        monkeypatch.setattr(sftp.paramiko.SFTPClient, "from_transport", Mock(return_value=client))
        authenticate = Mock()
        monkeypatch.setattr(transport, "auth_publickey", authenticate)
        monkeypatch.setattr(sftp, "approved_addresses", lambda destination: ["192.0.2.1"])
        destination = {
            "port": 22, "username": "delivery",
            "host_public_keys": [f"{pin.get_name()} {pin.get_base64()}"],
        }
        assert sftp.connect_sftp(destination, Mock(), None, stack) is client
        assert transport.host_key_type == algorithm
        assert transport.get_remote_server_key().asbytes() == pin.asbytes()
        authenticate.assert_called_once()
    transport.join(timeout=5)
    server.join(timeout=5)
    assert not transport.is_alive()
    assert not server.is_alive()