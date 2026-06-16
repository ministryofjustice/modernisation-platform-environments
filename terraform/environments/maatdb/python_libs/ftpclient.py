"""
AWS Lambda function for SFTP file transfers between S3 and remote servers.
Supports SSH key authentication, password authentication, and file filtering.
"""

from __future__ import annotations

import io
import json
import logging
import os
import shutil
import tracemalloc
import tempfile
import time
from dataclasses import dataclass
from enum import Enum
from typing import Any, Dict, List, Mapping, Optional, Union, cast

import boto3
import pycurl
from botocore.exceptions import ClientError
from mypy_boto3_s3 import S3Client
from mypy_boto3_secretsmanager import SecretsManagerClient


# Configure structured JSON logging
class JSONFormatter(logging.Formatter):
    """Custom JSON formatter for structured logging."""

    def format(self, record):
        log_entry = {
            "timestamp": self.formatTime(record, self.datefmt),
            "level": record.levelname,
            "logger": record.name,
            "function": record.funcName,
            "line": record.lineno,
            "message": record.getMessage(),
        }

        # Add exception info if present
        if record.exc_info:
            log_entry["exception"] = self.formatException(record.exc_info)

        # Add extra fields if present
        if hasattr(record, "extra_fields"):
            extra_fields = getattr(record, "extra_fields", None)
            if extra_fields and isinstance(extra_fields, dict):
                log_entry.update(extra_fields)

        return json.dumps(log_entry)


# Configure logging with JSON format
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Clear existing handlers to avoid duplicates
logger.handlers.clear()

# Add JSON formatted handler
handler = logging.StreamHandler()
handler.setFormatter(JSONFormatter())
logger.addHandler(handler)


def log_with_context(level, message, **kwargs):
    """Helper function to log with additional context."""
    record = logger.makeRecord(
        logger.name,
        level,
        "",
        0,
        message,
        (),
        None,
        func=log_with_context.__name__,
        extra=None,
    )
    if kwargs:
        record.extra_fields = kwargs
    logger.handle(record)


class CurlOptionsLogger:
    """Collects curl options and formats them as a curl command line."""

    def __init__(self):
        self.options = []

    def add_option(self, option, value, description=""):
        """Add a curl option to the collection."""
        self.options.append((option, value, description))

    def get_curl_command(self, base_url="[URL]"):
        """Generate curl command line equivalent from collected options."""
        # Map pycurl options to curl command line flags (SFTP-specific)
        option_map = {
            pycurl.TIMEOUT: lambda v: f"--max-time {v}",
            pycurl.VERBOSE: lambda v: "-v" if v == 1 else "",
            pycurl.USERPWD: lambda v: "-u [USER:PASS]",
            pycurl.SSH_PRIVATE_KEYFILE: lambda v: "--key [SSH_KEY]",
            pycurl.UPLOAD: lambda v: "-T [FILE]" if v == 1 else "",
            pycurl.DIRLISTONLY: lambda v: ""
            if v == 1
            else "",  # SFTP specific, no direct curl equivalent
        }

        flags = []
        url = base_url

        for option, value, description in self.options:
            if option == pycurl.URL:
                url = (
                    str(value)
                    if not any(x in str(value) for x in ["password", "user"])
                    else "[URL_WITH_CREDENTIALS]"
                )
            elif option in option_map:
                flag = option_map[option](value)
                if flag and flag not in flags:
                    flags.append(flag)

        # Build the command
        command_parts = ["curl"] + flags + [url]
        return " ".join(filter(None, command_parts))

    def log_final_command(self, base_url="[URL]"):
        """Log the final curl command equivalent."""
        command = self.get_curl_command(base_url)
        log_with_context(logging.INFO, "curl execution options", curl_command=command)


def set_curl_option(curl_instance, option, value, description="", logger_instance=None):
    """Wrapper for curl.setopt that includes option collection."""
    if logger_instance:
        logger_instance.add_option(option, value, description)
    curl_instance.setopt(option, value)


class ConfigValidator:
    """Validator class for configuration validation."""

    @staticmethod
    def validate_mandatory_fields(config_dict: Dict[str, Any], field_name: str) -> None:
        """Validate that all mandatory fields are present and non-empty."""
        # Always mandatory fields
        mandatory_fields = {
            "host": config_dict.get("host"),
            "transfer_type": config_dict.get("transfer_type"),
            "remote_path": config_dict.get("remote_path"),
            "user": config_dict.get("user"),
            "s3_bucket": config_dict.get("s3_bucket"),
            "local_path": config_dict.get("local_path"),
            "slack_webhook": config_dict.get("slack_webhook"),
        }

        # SFTP requires either password or SSH key
        password = config_dict.get("password")
        ssh_key = config_dict.get("ssh_key")

        if not password and not ssh_key:
            raise ValueError(
                "SFTP requires either password or SSH key for authentication"
            )

        missing_fields = [name for name, value in mandatory_fields.items() if not value]
        if missing_fields:
            raise ValueError(
                f"Missing required {field_name} fields: {', '.join(missing_fields)}"
            )

    @staticmethod
    def validate_port(port_str: Optional[str]) -> Optional[int]:
        """Validate and convert port string to integer."""
        if not port_str:
            return None

        try:
            port = int(port_str)
            if port < 1 or port > 65535:
                raise ValueError(f"Port must be between 1 and 65535, got: {port}")
            return port
        except (ValueError, TypeError) as e:
            raise ValueError(f"PORT must be a valid integer, got: {port_str}") from e

    @staticmethod
    def validate_ssh_key(ssh_key_raw: Any) -> Optional[str]:
        """Validate and process SSH key."""
        if not ssh_key_raw:
            return None

        if not isinstance(ssh_key_raw, str):
            raise ValueError(
                f"SSH_KEY must be a string, got: {type(ssh_key_raw).__name__}"
            )

        # Try to detect if it's already in proper PEM format
        if ssh_key_raw.startswith("-----BEGIN") and ssh_key_raw.endswith("-----"):
            return ssh_key_raw
        else:
            # Ensure the key has reasonable minimum length for processing
            if len(ssh_key_raw) < 50:
                raise ValueError("SSH_KEY appears to be malformed (too short)")

            # Try to reconstruct PEM format from various possible formats
            try:
                # Remove any whitespace and check if it's valid base64
                cleaned_key = ssh_key_raw.replace(" ", "").replace("\n", "")

                # If it looks like base64, try to format it as PEM
                if (
                    len(cleaned_key) > 100
                    and cleaned_key.replace("+", "")
                    .replace("/", "")
                    .replace("=", "")
                    .isalnum()
                ):
                    # Split into 64-character lines for proper PEM format
                    lines = [
                        cleaned_key[i : i + 64] for i in range(0, len(cleaned_key), 64)
                    ]
                    formatted_key = "\n".join(lines)

                    # Detect key type from content or assume RSA
                    if "BEGIN" in ssh_key_raw.upper():
                        # Extract key type from existing headers
                        key_type = "RSA PRIVATE KEY"
                        if "DSA" in ssh_key_raw.upper():
                            key_type = "DSA PRIVATE KEY"
                        elif "EC" in ssh_key_raw.upper():
                            key_type = "EC PRIVATE KEY"
                    else:
                        key_type = "RSA PRIVATE KEY"

                    return f"-----BEGIN {key_type}-----\n{formatted_key}\n-----END {key_type}-----"
                else:
                    raise ValueError("SSH_KEY format not recognized")

            except Exception as e:
                raise ValueError(
                    f"Failed to process SSH_KEY:\n{str(e)}.\nKey must be in PEM format or valid base64."
                )

    @staticmethod
    def validate_transfer_type(transfer_type_str: Optional[str]) -> "TransferType":
        """Validate and convert transfer type string."""
        if not transfer_type_str:
            raise ValueError("TRANSFERTYPE environment variable is required")

        if transfer_type_str == "SFTP_UPLOAD":
            return TransferType.SFTP_UPLOAD
        elif transfer_type_str == "SFTP_DOWNLOAD":
            return TransferType.SFTP_DOWNLOAD
        else:
            raise ValueError(
                f"Invalid transfer type: {transfer_type_str}. Must be SFTP_UPLOAD or SFTP_DOWNLOAD"
            )

    @staticmethod
    def get_mandatory_secret(secrets_data: Dict, key: str) -> str:
        """Extract and validate a mandatory field from secrets."""
        value = secrets_data.get(key)
        if not value or not isinstance(value, str):
            raise ValueError(
                f"{key} must be a non-empty string in secrets, got: {value}"
            )
        return value

    @staticmethod
    def get_optional_secret(secrets_data: Dict, key: str) -> Optional[str]:
        """Extract and validate an optional field from secrets."""
        value = secrets_data.get(key)
        if value is not None and not isinstance(value, str):
            raise ValueError(
                f"{key} must be a string in secrets, got: {type(value).__name__}"
            )
        return value if value else None

    @staticmethod
    def get_mandatory_env(env_data: Dict, key: str) -> str:
        """Extract and validate a mandatory field from environment."""
        value = env_data.get(key)
        if not value:
            raise ValueError(f"{key} environment variable is required")
        return value


class TransferType(Enum):
    """Enumeration of supported transfer types."""

    SFTP_UPLOAD = "SFTP_UPLOAD"
    SFTP_DOWNLOAD = "SFTP_DOWNLOAD"


@dataclass
class TransferConfig:
    """Configuration for SFTP file transfers with validation."""

    # Mandatory fields (no default values)
    host: str
    transfer_type: TransferType
    remote_path: str
    user: str
    s3_bucket: str
    local_path: str
    slack_webhook: str

    # Optional fields (with default values)
    port: Optional[int] = None
    password: Optional[str] = None
    ssh_key: Optional[str] = None
    skip_key_verification: bool = False
    file_types: Optional[List[str]] = None
    file_remove: bool = False

    def __post_init__(self):
        """Validate configuration after initialization."""
        # Validate using the ConfigValidator
        config_dict = {
            "host": self.host,
            "transfer_type": self.transfer_type,
            "remote_path": self.remote_path,
            "user": self.user,
            "password": self.password,
            "ssh_key": self.ssh_key,
            "s3_bucket": self.s3_bucket,
            "local_path": self.local_path,
            "slack_webhook": self.slack_webhook,
        }

        ConfigValidator.validate_mandatory_fields(config_dict, "configuration")

        # Process file types into extensions
        if self.file_types:
            self.file_extensions = [f".{ext}" for ext in self.file_types]
        else:
            self.file_extensions = []

        logger.info(f"Configuration validated for {self.transfer_type.name} using SFTP")


class NotificationService:
    """Service for sending notifications to Slack."""

    def __init__(self, webhook_url: str, function_name: str = "SFTP Transfer Lambda"):
        if not webhook_url:
            raise ValueError("Slack webhook URL is required for notifications")

        self.webhook_url = webhook_url
        self.function_name = function_name
        logger.info("Slack notifications configured")

    def send_notification(
        self, title: str, message: str, is_error: bool = False
    ) -> bool:
        """Send a notification to Slack using the webhook."""
        curl = pycurl.Curl()

        try:
            # Prepare the Slack message with formatting
            emoji = ":x:" if is_error else ":white_check_mark:"
            color = "danger" if is_error else "good"

            payload = {
                "attachments": [
                    {
                        "color": color,
                        "title": f"{emoji} [{self.function_name}] {title}",
                        "text": message,
                        "footer": "SFTP Transfer Lambda",
                        "ts": int(time.time()),
                    }
                ]
            }

            # Convert payload to JSON
            json_payload = json.dumps(payload)

            # Configure curl for HTTP POST with JSON
            curl.setopt(pycurl.URL, self.webhook_url)
            curl.setopt(pycurl.POST, 1)
            curl.setopt(pycurl.POSTFIELDS, json_payload)
            curl.setopt(pycurl.HTTPHEADER, ["Content-Type: application/json"])
            curl.setopt(pycurl.TIMEOUT, 10)

            # Buffer for response (though Slack webhook responses are minimal)
            response_buffer = io.BytesIO()
            curl.setopt(pycurl.WRITEDATA, response_buffer)

            # Send the notification
            curl.perform()

            # Check HTTP status code
            http_code = curl.getinfo(pycurl.RESPONSE_CODE)
            if http_code >= 400:
                raise Exception(f"HTTP error {http_code}")

            logger.info(f"Slack notification sent successfully: {title}")
            return True

        except Exception as e:
            logger.error(f"Failed to send Slack notification: {e}")
            return False
        finally:
            curl.close()


class SftpPycurlHandler:
    """Handler for SFTP transfers using pycurl."""

    def __init__(self, notification_service: NotificationService):
        self.notification_service = notification_service

    def _create_curl_instance(self, config: TransferConfig) -> pycurl.Curl:
        """Create and configure a pycurl instance with proper settings."""
        curl = pycurl.Curl()
        curl_logger = CurlOptionsLogger()

        # Basic settings
        set_curl_option(curl, pycurl.VERBOSE, 1, "Enable verbose logging", curl_logger)
        set_curl_option(
            curl, pycurl.TIMEOUT, 600, "Set connection timeout", curl_logger
        )

        # SSH key verification
        if config.skip_key_verification:
            set_curl_option(
                curl,
                pycurl.SSL_VERIFYPEER,
                0,
                "Disable SSL peer verification",
                curl_logger,
            )
            set_curl_option(
                curl,
                pycurl.SSL_VERIFYHOST,
                0,
                "Disable SSL host verification",
                curl_logger,
            )
            logger.warning(
                "SSH host key verification disabled - connection is insecure"
            )

        # SFTP-specific settings
        if config.ssh_key:
            # Process SSH key
            with tempfile.NamedTemporaryFile(
                mode="w", delete=False, suffix=".key"
            ) as key_file:
                os.chmod(key_file.name, 0o600)
                # The SSH key is already in PEM format from the original code
                key_file.write(config.ssh_key)
                key_file_path = key_file.name

            set_curl_option(
                curl,
                pycurl.SSH_PRIVATE_KEYFILE,
                key_file_path,
                "Set SSH private key file",
                curl_logger,
            )
            logger.info("Using SSH private key for authentication")

        # Authentication
        if config.password:
            set_curl_option(
                curl,
                pycurl.USERPWD,
                f"{config.user}:{config.password}",
                "Set user credentials",
                curl_logger,
            )
            logger.info(f"Using password authentication for user: {config.user}")
        else:
            # For SFTP with SSH key only, we still need to set the username
            set_curl_option(
                curl,
                pycurl.USERPWD,
                f"{config.user}:",
                "Set username for SSH key auth",
                curl_logger,
            )
            logger.info(f"Using SSH key authentication for user: {config.user}")

        # Log the final curl command equivalent
        curl_logger.log_final_command()

        return curl

    def _build_url(self, config: TransferConfig, filename: str = "") -> str:
        """Build the complete URL for the transfer."""
        port_part = f":{config.port}" if config.port else ""

        # Ensure proper path formatting
        remote_path = config.remote_path
        if not remote_path.endswith("/") and filename:
            remote_path += "/"

        url = f"sftp://{config.host}{port_part}{remote_path}{filename}"
        logger.debug(f"Built URL: {url}")
        return url

    def list_remote_files(self, config: TransferConfig) -> List[str]:
        """List files on the remote server."""
        curl = self._create_curl_instance(config)
        url = self._build_url(config)

        # Buffer to store the listing
        listing_buffer = io.BytesIO()

        try:
            curl.setopt(pycurl.URL, url)
            curl.setopt(pycurl.WRITEDATA, listing_buffer)
            curl.setopt(pycurl.DIRLISTONLY, 1)

            logger.info(f"Listing files at: {url}")
            curl.perform()

            # Parse the file listing with proper error handling
            try:
                listing = listing_buffer.getvalue().decode("utf-8").strip()
            except UnicodeDecodeError as e:
                logger.error(f"Failed to decode SFTP directory listing: {e}")
                raise Exception(f"Invalid directory listing encoding from server: {e}")

            files = listing.split("\n") if listing else []

            # Filter out directory entries (., .., and directories ending with /)
            files = [
                f for f in files if f and f not in (".", "..") and not f.endswith("/")
            ]
            logger.info(f"Filtered out directory entries, {len(files)} files remain")

            # Filter by file types if specified
            if config.file_extensions:
                files = [
                    f
                    for f in files
                    if any(f.endswith(ext) for ext in config.file_extensions)
                ]
                logger.info(
                    f"Filtered files by extensions {config.file_extensions}: {len(files)} files"
                )

            logger.info(f"Found {len(files)} files on remote server")
            return files

        except pycurl.error as e:
            error_msg = f"Failed to list remote files: {e}"
            logger.error(error_msg)
            self.notification_service.send_notification(
                "SFTP List Error",
                f"Failed to list files on {config.host}:\n{str(e)}",
                is_error=True,
            )
            raise Exception(error_msg)
        finally:
            curl.close()
            listing_buffer.close()

    def download_file(
        self, config: TransferConfig, remote_file: str, local_path: str
    ) -> None:
        """Download a single file from the remote server."""
        curl = self._create_curl_instance(config)
        url = self._build_url(config, remote_file)

        try:
            with open(local_path, "wb") as f:
                curl.setopt(pycurl.URL, url)
                curl.setopt(pycurl.WRITEDATA, f)

                logger.info(f"Downloading: {remote_file} -> {local_path}")
                curl.perform()

            logger.info(f"Successfully downloaded: {remote_file}")

        except pycurl.error as e:
            error_msg = f"Failed to download {remote_file}: {e}"
            logger.error(error_msg)
            raise Exception(error_msg)
        finally:
            curl.close()

    def upload_file(
        self, config: TransferConfig, local_path: str, remote_file: str
    ) -> None:
        """Upload a single file to the remote server."""
        curl = self._create_curl_instance(config)
        url = self._build_url(config, remote_file)

        try:
            with open(local_path, "rb") as f:
                curl.setopt(pycurl.URL, url)
                curl.setopt(pycurl.UPLOAD, 1)
                curl.setopt(pycurl.READDATA, f)

                # Get file size for progress tracking
                file_size = os.path.getsize(local_path)
                curl.setopt(pycurl.INFILESIZE, file_size)

                logger.info(
                    f"Uploading: {local_path} -> {remote_file} (size: {file_size} bytes)"
                )
                curl.perform()

            logger.info(f"Successfully uploaded: {remote_file}")

        except pycurl.error as e:
            error_msg = f"Failed to upload {remote_file}: {e}"
            logger.error(error_msg)
            raise Exception(error_msg)
        finally:
            curl.close()

    def delete_remote_file(self, config: TransferConfig, remote_file: str) -> None:
        """Delete a file from the remote SFTP server."""
        curl = self._create_curl_instance(config)
        url = self._build_url(config)

        try:
            curl.setopt(pycurl.URL, url)
            # For SFTP, use POSTQUOTE with the rm command
            # Use the full path for the rm command to ensure correct file location
            full_remote_path = f"{config.remote_path.rstrip('/')}/{remote_file}"
            curl.setopt(pycurl.POSTQUOTE, [f"rm {full_remote_path}"])

            logger.info(f"Deleting remote SFTP file: {full_remote_path}")
            curl.perform()

            logger.info(f"Successfully deleted SFTP file: {full_remote_path}")

        except pycurl.error as e:
            # SFTP may return different error codes than FTP
            logger.warning(f"SFTP delete operation may have failed: {e}")
        except Exception as e:
            logger.error(f"Unexpected error during SFTP file deletion: {e}")
        finally:
            curl.close()

    def download_files(self, config: TransferConfig, s3_client: S3Client) -> List[str]:
        """Download multiple files from remote server to S3."""
        downloaded_files = []
        failed_files = []  # Will store tuples of (filename, error_message)

        try:
            # List remote files
            remote_files = self.list_remote_files(config)

            if not remote_files:
                logger.info("No files to download")
                return downloaded_files

            logger.info(f"Starting download of {len(remote_files)} files")

            # Download each file
            for remote_file in remote_files:
                try:
                    # Create temp file for download
                    with tempfile.NamedTemporaryFile(delete=False) as tmp_file:
                        temp_path = tmp_file.name
                        os.chmod(temp_path, 0o600)

                    # Download file
                    self.download_file(config, remote_file, temp_path)

                    # Upload to S3 with mandatory local_path
                    s3_key = f"{config.local_path}{remote_file}"
                    s3_client.upload_file(temp_path, config.s3_bucket, s3_key)
                    logger.info(f"Uploaded to S3: s3://{config.s3_bucket}/{s3_key}")

                    downloaded_files.append(remote_file)

                    # Clean up temp file
                    os.unlink(temp_path)

                    # Delete from remote if configured
                    if config.file_remove:
                        self.delete_remote_file(config, remote_file)

                except Exception as e:
                    error_msg = str(e)
                    # Truncate very long error messages for readability
                    if len(error_msg) > 100:
                        error_msg = error_msg[:97] + "..."
                    logger.error(f"Failed to process {remote_file}: {e}")
                    failed_files.append((remote_file, error_msg))

            # Send summary notification
            success_count = len(downloaded_files)
            fail_count = len(failed_files)

            if success_count > 0:
                # Create formatted file list for notification
                # files_list = "\n• " + "\n• ".join(downloaded_files)

                 # Limit to first 20 filenames if there are more than 20
                if len(downloaded_files) > 20:
                    displayed_files = downloaded_files[:20]
                    remaining_count = len(downloaded_files) - 20
                    files_list = "\n• " + "\n• ".join(displayed_files)
                    files_list += f"\n• ...and {remaining_count} more files"
                else:
                    files_list = "\n• " + "\n• ".join(downloaded_files)

                self.notification_service.send_notification(
                    "SFTP Download Complete",
                    f"Successfully downloaded {success_count} files from `{config.host}{config.remote_path}` to s3://{config.s3_bucket}/{config.local_path}:{files_list}",
                )

            if fail_count > 0:
                # Create formatted failed files list with error details
                failed_files_display = failed_files[:5]  # Limit to first 5 files
                failed_files_list = "\n• " + "\n• ".join(
                    f"{filename}: {error_msg}"
                    for filename, error_msg in failed_files_display
                )
                ellipsis = "\n• ..." if fail_count > 5 else ""

                self.notification_service.send_notification(
                    "SFTP Download Errors",
                    f"Failed to download {fail_count} files:{failed_files_list}{ellipsis}",
                    is_error=True,
                )

        except Exception as e:
            logger.error(f"Download operation failed:\n{e}")
            self.notification_service.send_notification(
                "SFTP Download Failed",
                f"Download operation failed:\n{str(e)}",
                is_error=True,
            )
            raise

        return downloaded_files

    def upload_files(self, config: TransferConfig, s3_client: S3Client) -> List[str]:
        """Upload multiple files from S3 to remote server."""
        uploaded_files = []
        failed_files = []  # Will store tuples of (s3_key, error_message)

        try:
            # List S3 objects with mandatory local_path prefix
            response = s3_client.list_objects_v2(
                Bucket=config.s3_bucket, Prefix=config.local_path, Delimiter="/"
            )
            # Filter out the prefix directory itself and any directories
            s3_objects = []
            contents = response.get("Contents", [])
            for obj in contents:
                # Skip the prefix directory itself and any directory objects
                obj_key = obj.get("Key", "")
                if (
                    obj_key
                    and obj_key != config.local_path
                    and not obj_key.endswith("/")
                ):
                    s3_objects.append(obj)

            if not s3_objects:
                logger.info("No files to upload")
                return uploaded_files

            logger.info(f"Found {len(s3_objects)} objects in S3")

            # Filter and upload files
            for obj in s3_objects:
                s3_key = obj.get("Key", "")

                # Skip if no key or if it's a directory
                if not s3_key or s3_key.endswith("/"):
                    continue

                # Apply file type filter
                if config.file_extensions:
                    if not any(s3_key.endswith(ext) for ext in config.file_extensions):
                        continue

                try:
                    # Create temp file for upload
                    with tempfile.NamedTemporaryFile(delete=False) as tmp_file:
                        temp_path = tmp_file.name
                        os.chmod(temp_path, 0o600)

                    # Download from S3
                    s3_client.download_file(config.s3_bucket, s3_key, temp_path)

                    # Since local_path is mandatory, always extract basename
                    remote_file = os.path.basename(s3_key)

                    # Upload file
                    self.upload_file(config, temp_path, remote_file)
                    uploaded_files.append(s3_key)

                    # Clean up temp file
                    os.unlink(temp_path)

                    # Delete from S3 if configured
                    if config.file_remove:
                        s3_client.delete_object(Bucket=config.s3_bucket, Key=s3_key)
                        logger.info(f"Deleted from S3: {s3_key}")

                except Exception as e:
                    error_msg = str(e)
                    # Truncate very long error messages for readability
                    if len(error_msg) > 100:
                        error_msg = error_msg[:97] + "..."
                    logger.error(f"Failed to process {s3_key}: {e}")
                    failed_files.append((s3_key, error_msg))

            # Send summary notification
            success_count = len(uploaded_files)
            fail_count = len(failed_files)

            if success_count > 0:
                # Extract just the filenames from the S3 keys for cleaner display
                uploaded_filenames = [
                    os.path.basename(s3_key) for s3_key in uploaded_files
                ]
                # files_list = "\n• " + "\n• ".join(uploaded_filenames)

                # Limit to first 20 filenames if there are more than 20
                if len(uploaded_filenames) > 20:
                    displayed_files = uploaded_filenames[:20]
                    remaining_count = len(uploaded_filenames) - 20
                    files_list = "\n• " + "\n• ".join(displayed_files)
                    files_list += f"\n• ...and {remaining_count} more files"
                else:
                    files_list = "\n• " + "\n• ".join(uploaded_filenames)

                self.notification_service.send_notification(
                    "SFTP Upload Complete",
                    f"Successfully uploaded {success_count} files to `{config.host}{config.remote_path}`:{files_list}",
                )

            if fail_count > 0:
                # Create formatted failed files list with error details
                # Extract just the filenames from S3 keys for cleaner display
                failed_files_display = failed_files[:5]  # Limit to first 5 files
                failed_files_list = "\n• " + "\n• ".join(
                    f"{os.path.basename(s3_key)}: {error_msg}"
                    for s3_key, error_msg in failed_files_display
                )
                ellipsis = "\n• ..." if fail_count > 5 else ""

                self.notification_service.send_notification(
                    "SFTP Upload Errors",
                    f"Failed to upload {fail_count} files:{failed_files_list}{ellipsis}",
                    is_error=True,
                )

        except Exception as e:
            logger.error(f"Upload operation failed:\n{e}")
            self.notification_service.send_notification(
                "SFTP Upload Failed",
                f"Upload operation failed:\n{str(e)}",
                is_error=True,
            )
            raise

        return uploaded_files


class SecretsManager:
    """Manager for retrieving configuration from AWS Secrets Manager."""

    def __init__(self):
        self.client = cast(SecretsManagerClient, boto3.client("secretsmanager"))
        logger.info("Initialized Secrets Manager client")

    def get_credentials(self, secret_name: str) -> Dict[str, Union[str, int, bool]]:
        """Retrieve and parse credentials from Secrets Manager."""
        try:
            logger.info(f"Retrieving secret: {secret_name}")
            response = self.client.get_secret_value(SecretId=secret_name)

            # Parse the secret string
            secret_data = json.loads(response["SecretString"])
            logger.info(
                f"Successfully retrieved credentials with {len(secret_data)} keys"
            )

            return secret_data

        except ClientError as e:
            error_code = e.response["Error"]["Code"]
            error_msg = f"Failed to retrieve secret {secret_name}: {error_code}"
            logger.error(error_msg)
            raise Exception(error_msg)
        except json.JSONDecodeError as e:
            error_msg = f"Failed to parse secret JSON: {e}"
            logger.error(error_msg)
            raise Exception(error_msg)


def get_env_variable(key: str, required: bool = True) -> Optional[str]:
    """
    Get an environment variable with proper validation.

    Args:
        key: The environment variable name
        required: Whether this variable is mandatory

    Returns:
        The value if found, None if not required and not found

    Raises:
        ValueError if required but not found
    """
    value = os.environ.get(key)

    if required and not value:
        raise ValueError(f"Required environment variable {key} is not set")

    # Log the presence of the variable (but not its value for security)
    if value:
        logger.info(f"Environment variable {key} is configured")
    else:
        logger.info(f"Environment variable {key} is not set")

    return value


def parse_config_from_env_and_secrets(
    env_data: Dict[str, Optional[str]], secrets_data: Dict[str, Union[str, int, bool]]
) -> TransferConfig:
    """
    Parse configuration from both environment variables and secrets data.

    This function combines non-sensitive configuration from environment variables
    with sensitive credentials from AWS Secrets Manager to create a complete
    TransferConfig object.
    """
    # Process SSH key using validator
    ssh_key = ConfigValidator.validate_ssh_key(secrets_data.get("SSH_KEY"))

    # Parse file types from environment
    file_types = None
    file_types_str = env_data.get("FILETYPES")
    if file_types_str:
        file_types = file_types_str.split(",")

    # Validate transfer type using validator
    transfer_type = ConfigValidator.validate_transfer_type(env_data.get("TRANSFERTYPE"))

    # Parse port using validator
    port = ConfigValidator.validate_port(env_data.get("PORT"))

    # Create config object with properly separated concerns
    config = TransferConfig(
        # Connection settings from mixed sources
        host=ConfigValidator.get_mandatory_secret(
            secrets_data, "HOST"
        ),  # Sensitive - from secrets
        transfer_type=transfer_type,
        remote_path=ConfigValidator.get_mandatory_env(env_data, "REMOTEPATH"),
        # Authentication from secrets only
        user=ConfigValidator.get_mandatory_secret(secrets_data, "USER"),
        password=ConfigValidator.get_optional_secret(secrets_data, "PASSWORD"),
        # AWS settings from environment
        s3_bucket=ConfigValidator.get_mandatory_env(env_data, "S3BUCKET"),
        local_path=ConfigValidator.get_mandatory_env(env_data, "LOCALPATH"),
        # Notification settings from secrets
        slack_webhook=ConfigValidator.get_mandatory_secret(secrets_data, "SLACK_WEBHOOK"),
        # Optional settings from various sources
        port=port,
        ssh_key=ssh_key,  # From secrets if present
        skip_key_verification=str(env_data.get("SKIP_KEY_VERIFICATION", "")).upper()
        == "YES",
        file_types=file_types,
        file_remove=str(env_data.get("FILEREMOVE", "")).upper() == "YES",
    )

    return config

def cleanup_tmp_folder():
    logger.info("Starting /tmp folder deletion")
    # logger.info(f"Free space before:", shutil.disk_usage("/tmp").free)
    logger.info(f"Disk usage: {shutil.disk_usage('/tmp')}")
    
    folder = '/tmp'
    stats = os.statvfs('/tmp')
    free_inodes = stats.f_favail
    total_inodes = stats.f_files
    logger.info(f"/tmp inode usage: free={free_inodes}, total={total_inodes}")
    for filename in os.listdir(folder):
        file_path = os.path.join(folder, filename)
        try:
            if os.path.isfile(file_path) or os.path.islink(file_path):
                os.unlink(file_path)
            elif os.path.isdir(file_path):
                shutil.rmtree(file_path)
        except Exception as e:
            logger.error(f'Failed to delete {file_path}. Reason: {e}')

def lambda_handler(
    event: Mapping[str, Union[str, int, bool]], context: Any
) -> Dict[str, Union[str, int, Dict]]:
    """
    Main Lambda handler function.

    This function orchestrates the SFTP file transfer process by:
    1. Loading configuration from both environment variables and AWS Secrets Manager
    2. Initializing the SFTP transfer handler
    3. Executing the file transfer operation
    4. Sending notifications about the results

    Args:
        event: Lambda event data (can override SECRET_NAME via 'secret_name' key)
        context: Lambda context object

    Returns:
        Response dictionary with status and results
    """

    tracemalloc.start()
    logger.info("Starting SFTP Transfer Lambda execution")
    logger.info(f"Event: {json.dumps(event, default=str)}")

    # Initialize notification service early with None as default
    notification_service: Optional[NotificationService] = None

    try:
        # Load environment variables first (non-sensitive configuration)
        logger.info("Loading configuration from environment variables")
        env_config = {
            # Mandatory environment variables
            "TRANSFERTYPE": get_env_variable("TRANSFERTYPE", required=True),
            "REMOTEPATH": get_env_variable("REMOTEPATH", required=True),
            "LOCALPATH": get_env_variable("LOCALPATH", required=True),
            "S3BUCKET": get_env_variable("S3BUCKET", required=True),
            # Optional environment variables
            "PORT": get_env_variable("PORT", required=False),
            "SKIP_KEY_VERIFICATION": get_env_variable(
                "SKIP_KEY_VERIFICATION", required=False
            ),
            "FILETYPES": get_env_variable("FILETYPES", required=False),
            "FILEREMOVE": get_env_variable("FILEREMOVE", required=False),
        }
        #cleanup the lambda temp folder before starting the upload and download operation(bug fix for no space left on device error)
        cleanup_tmp_folder()

        # Get secret name from environment or event
        secret_name = os.environ.get("SECRET_NAME", event.get("secret_name"))
        if not secret_name:
            raise ValueError("SECRET_NAME not found in environment or event")
        if not isinstance(secret_name, str):
            raise ValueError(
                f"SECRET_NAME must be a string, got: {type(secret_name).__name__}"
            )

        # Retrieve sensitive credentials from Secrets Manager
        logger.info("Retrieving credentials from AWS Secrets Manager")
        secrets_manager = SecretsManager()
        secrets_data = secrets_manager.get_credentials(secret_name)

        # Validate that required credentials are present
        # Always require USER, HOST, and SLACK_WEBHOOK
        required_secrets = ["USER", "HOST", "SLACK_WEBHOOK"]
        missing_secrets = [key for key in required_secrets if key not in secrets_data]
        if missing_secrets:
            raise ValueError(f"Missing required secrets: {', '.join(missing_secrets)}")

        # For authentication, require either PASSWORD or SSH_KEY
        has_password = "PASSWORD" in secrets_data and secrets_data.get("PASSWORD")
        has_ssh_key = "SSH_KEY" in secrets_data and secrets_data.get("SSH_KEY")
        if not has_password and not has_ssh_key:
            raise ValueError(
                "Missing authentication credentials: either PASSWORD or SSH_KEY must be provided"
            )

        # Parse combined configuration
        logger.info("Parsing configuration from environment and secrets")
        config = parse_config_from_env_and_secrets(env_config, secrets_data)

        # Initialize services
        notification_service = NotificationService(
            config.slack_webhook, context.function_name
        )
        s3_client = cast(S3Client, boto3.client("s3"))

        # Create SFTP transfer handler
        handler = SftpPycurlHandler(notification_service)

        # Execute transfer based on type
        if config.transfer_type == TransferType.SFTP_DOWNLOAD:
            logger.info(f"Starting {config.transfer_type.name} operation")
            transferred_files = handler.download_files(config, s3_client)
        else:
            logger.info(f"Starting {config.transfer_type.name} operation")
            transferred_files = handler.upload_files(config, s3_client)

        # Prepare response
        response = {
            "statusCode": 200,
            "body": {
                "message": f"Successfully completed {config.transfer_type.name}",
                "transferred_files": transferred_files,
                "count": len(transferred_files),
            },
        }

        logger.info(f"Lambda execution completed successfully: {response}")
        return response

    except Exception as e:
        error_msg = f"Lambda execution failed:\n{str(e)}"
        logger.error(error_msg, exc_info=True)

        # Send error notification if notification service is available
        if notification_service is not None:
            try:
                notification_service.send_notification(
                    "Lambda Execution Failed", error_msg, is_error=True
                )
            except Exception as notification_error:
                logger.error(f"Failed to send error notification: {notification_error}")

        # Return error response
        return {"statusCode": 500, "body": {"error": error_msg}}
    finally:
        cleanup_tmp_folder()  # Clean at end
        current, peak = tracemalloc.get_traced_memory()
        logger.info(f"Current memory usage: {current / 1024 / 1024:.2f} MB; Peak: {peak / 1024 / 1024:.2f} MB")
        tracemalloc.stop()

# For local testing
if __name__ == "__main__":
    # Example test event
    test_event = {"secret_name": "sftp-transfer-credentials"}

    # Mock context
    class MockContext:
        function_name = "sftp-transfer-lambda"
        request_id = "test-request-id"

    # Set up test environment variables
    test_env = {
        "TRANSFERTYPE": "SFTP_DOWNLOAD",
        "REMOTEPATH": "/data/incoming/",
        "LOCALPATH": "downloads/",
        "S3BUCKET": "my-transfer-bucket",
        "PORT": "22",
        "SKIP_KEY_VERIFICATION": "NO",
        "FILETYPES": "csv,txt",
        "FILEREMOVE": "YES",
    }

    # Apply test environment
    for key, value in test_env.items():
        os.environ[key] = value

    result = lambda_handler(test_event, MockContext())
    print(json.dumps(result, indent=2))