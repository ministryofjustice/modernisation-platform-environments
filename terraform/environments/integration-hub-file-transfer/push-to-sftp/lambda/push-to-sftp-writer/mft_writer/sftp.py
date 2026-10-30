from __future__ import annotations

import base64
import errno
import hmac
import io
import ipaddress
import logging
import posixpath
import socket
import stat
import threading
import uuid
from collections.abc import Mapping
from contextlib import ExitStack
from typing import Any

import paramiko

from mft_writer.config import json_object
from mft_writer.diagnostics import ensure_time
from mft_writer.errors import InvalidMessage

CHUNK_BYTES = 256 * 1024
CONNECT_TIMEOUT = 10
IO_TIMEOUT = 15


def load_private_key(response: Mapping[str, Any]) -> paramiko.PKey:
    if "AWSCURRENT" not in response.get("VersionStages", []):
        raise InvalidMessage("credential secret is not the current version")
    payload = json_object(response.get("SecretString"), "credential secret")
    if set(payload) - {"private_key", "passphrase"} or not isinstance(payload.get("private_key"), str):
        raise InvalidMessage("credential secret fields are invalid")
    passphrase = payload.get("passphrase")
    if passphrase is not None and not isinstance(passphrase, str):
        raise InvalidMessage("credential passphrase is invalid")
    for key_type in (paramiko.Ed25519Key, paramiko.RSAKey, paramiko.ECDSAKey):
        try:
            return key_type.from_private_key(io.StringIO(payload["private_key"]), password=passphrase)
        except (paramiko.SSHException, ValueError, TypeError):
            continue
    raise InvalidMessage("credential secret does not contain a supported SSH private key")


def trusted_host_keys(keys: list[str]) -> list[paramiko.PKey]:
    try:
        return [paramiko.PKey.from_type_string(parts[0], base64.b64decode(parts[1], validate=True))
                for parts in (key.split() for key in keys)]
    except (ValueError, TypeError, IndexError, paramiko.SSHException) as error:
        raise InvalidMessage("trusted SSH server public key is invalid") from error


def approved_addresses(destination: Mapping[str, Any]) -> list[str]:
    networks = [ipaddress.ip_network(value) for value in destination["destination_cidr_blocks"]]
    addresses = sorted({result[4][0] for result in socket.getaddrinfo(
        destination["hostname"], destination["port"], socket.AF_INET, socket.SOCK_STREAM
    )})
    if not addresses or any(not any(ipaddress.ip_address(address) in network for network in networks) for address in addresses):
        raise InvalidMessage("SFTP DNS resolved outside the approved destination networks")
    return addresses


def connect_sftp(destination: Mapping[str, Any], private_key: paramiko.PKey, context: Any, stack: ExitStack) -> Any:
    for logger_name in ("paramiko", "paramiko.transport", "paramiko.transport.sftp"):
        ssh_logger = logging.getLogger(logger_name)
        if not any(isinstance(handler, logging.NullHandler) for handler in ssh_logger.handlers):
            ssh_logger.addHandler(logging.NullHandler())
        ssh_logger.propagate = False
    pins = trusted_host_keys(destination["host_public_keys"])
    addresses = approved_addresses(destination)
    for address in addresses:
        ensure_time(context, "SFTP connection")
        try:
            connection = socket.create_connection((address, destination["port"]), timeout=CONNECT_TIMEOUT)
        except OSError:
            continue
        break
    else:
        raise ConnectionError("no approved SFTP address is reachable")
    stack.callback(connection.close)
    if connection.getpeername()[0] != address:
        raise InvalidMessage("SFTP peer address does not match the approved destination")
    transport = paramiko.Transport(connection)
    stack.callback(transport.close)
    transport.banner_timeout = CONNECT_TIMEOUT
    transport.auth_timeout = CONNECT_TIMEOUT
    transport.channel_timeout = IO_TIMEOUT
    transport.start_client(timeout=CONNECT_TIMEOUT)
    remote_key = transport.get_remote_server_key()
    if not any(hmac.compare_digest(remote_key.asbytes(), pin.asbytes()) for pin in pins):
        raise InvalidMessage("SFTP server host key is not trusted")
    ensure_time(context, "SFTP authentication")
    transport.auth_publickey(destination["username"], private_key)
    ensure_time(context, "SFTP session setup")
    setup_deadline = threading.Timer(IO_TIMEOUT, transport.close)
    setup_deadline.daemon = True
    setup_deadline.start()
    try:
        client = paramiko.SFTPClient.from_transport(transport)
    finally:
        setup_deadline.cancel()
    stack.callback(client.close)
    client.get_channel().settimeout(IO_TIMEOUT)
    return client


def checked_directory(client: Any, root: str, relative: str, context: Any, *, create: bool) -> str:
    current = root
    for component in relative.split("/") if relative else []:
        ensure_time(context, "SFTP directory verification")
        current = posixpath.join(current, component)
        try:
            attributes = client.lstat(current)
        except OSError as error:
            if not create or error.errno != errno.ENOENT:
                raise
            try:
                client.mkdir(current, mode=0o700)
            except OSError as mkdir_error:
                if mkdir_error.errno != errno.EEXIST:
                    raise
            attributes = client.lstat(current)
        if not stat.S_ISDIR(attributes.st_mode) or client.normalize(current) != current:
            raise InvalidMessage("remote directory is not a canonical, non-symlink directory")
    return current


def upload_stream(client: Any, body: Any, source_size: int, route: Mapping[str, Any], context: Any) -> int:
    root = client.normalize(".")
    if not isinstance(root, str) or not root.startswith("/") or posixpath.normpath(root) != root:
        raise InvalidMessage("remote home directory is not canonical")
    base = checked_directory(client, root, route["destination"]["destination_prefix"].rstrip("/"), context, create=False)
    directory = checked_directory(client, base, posixpath.dirname(route["relative_key"]), context, create=True)
    final = posixpath.join(directory, posixpath.basename(route["relative_key"]))
    try:
        attributes = client.lstat(final)
    except OSError as error:
        if error.errno != errno.ENOENT:
            raise
    else:
        if not stat.S_ISREG(attributes.st_mode):
            raise InvalidMessage("remote destination is not a regular, non-symlink file")
    temporary = posixpath.join(directory, f".mft-{uuid.uuid4().hex}.part")
    created = False
    renamed = False
    try:
        ensure_time(context, "SFTP temporary upload")
        remote_file = client.open(temporary, "wx")
        created = True
        size = 0
        with remote_file:
            while True:
                ensure_time(context, "SFTP streaming")
                chunk = body.read(CHUNK_BYTES)
                if not chunk:
                    break
                size += len(chunk)
                if size > source_size:
                    raise InvalidMessage("source object exceeds its recorded size")
                remote_file.write(chunk)
        if size != source_size or client.stat(temporary).st_size != source_size:
            raise InvalidMessage("uploaded file size does not match the exact source version")
        ensure_time(context, "SFTP overwrite rename")
        client.posix_rename(temporary, final)
        renamed = True
        return size
    finally:
        if created and not renamed:
            try:
                client.remove(temporary)
            except OSError:
                pass


def transfer_versioned_object(s3: Any, secrets: Any, source: Mapping[str, Any], route: Mapping[str, Any], context: Any) -> int:
    ensure_time(context, "read-current-credential")
    private_key = load_private_key(secrets.get_secret_value(SecretId=route["credential_arn"], VersionStage="AWSCURRENT"))
    ensure_time(context, "read-source-version")
    response = s3.get_object(Bucket=source["bucket"], Key=source["key"], VersionId=source["versionId"])
    with ExitStack() as stack:
        body = response["Body"]
        stack.callback(body.close)
        if response.get("VersionId") != source["versionId"] or response.get("ContentLength") != source["sizeBytes"]:
            raise InvalidMessage("S3 response does not match the exact source version and size")
        client = connect_sftp(route["destination"], private_key, context, stack)
        return upload_stream(client, body, source["sizeBytes"], route, context)