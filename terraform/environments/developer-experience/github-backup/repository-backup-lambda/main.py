"""Back up GitHub repositories that opt in with the `backup` custom property.

A scheduled invocation discovers opted-in repositories and asynchronously
invokes this function once per repository, so each backup gets its own
timeout, temporary storage and failure handling.
"""

import json
import logging
import os
import re
import shutil
import stat
import tarfile
import time
import urllib.error
import urllib.parse
import urllib.request
import uuid
from base64 import urlsafe_b64encode
from datetime import datetime, timezone

import boto3
import rsa
from dulwich import porcelain
from dulwich.client import get_transport_and_path
from dulwich.objects import S_ISGITLINK, Commit, Tag, Tree
from dulwich.repo import Repo

logger = logging.getLogger()
logger.setLevel(logging.INFO)

GITHUB_API_URL = "https://api.github.com"
GITHUB_ORGANISATION = os.environ["GITHUB_ORGANISATION"]
GITHUB_APP_SECRET_ARN = os.environ["GITHUB_APP_SECRET_ARN"]
BACKUP_BUCKET = os.environ["BACKUP_BUCKET"]
BACKUP_PROPERTY = "backup"
REPOSITORY_NAME_PATTERN = re.compile(r"^[A-Za-z0-9_.-]+$")
WORK_DIR = "/tmp/repository-backup"

secrets_manager = boto3.client("secretsmanager")
s3 = boto3.client("s3")
lambda_client = boto3.client("lambda")


def _b64(data: bytes) -> str:
    return urlsafe_b64encode(data).rstrip(b"=").decode()


def get_installation_token() -> str:
    """Exchange the dedicated GitHub App credentials for a short-lived installation token."""
    secret = json.loads(
        secrets_manager.get_secret_value(SecretId=GITHUB_APP_SECRET_ARN)["SecretString"]
    )

    now = int(time.time())
    # Backdate to tolerate clock drift; GitHub rejects JWTs valid for over 10 minutes.
    header = _b64(json.dumps({"alg": "RS256", "typ": "JWT"}).encode())
    payload = _b64(
        json.dumps({"iat": now - 60, "exp": now + 540, "iss": secret["client_id"]}).encode()
    )
    signing_input = f"{header}.{payload}".encode()
    private_key = rsa.PrivateKey.load_pkcs1(secret["private_key"].encode())
    jwt = f"{header}.{payload}.{_b64(rsa.sign(signing_input, private_key, 'SHA-256'))}"

    response, _ = github_request(
        f"/app/installations/{secret['installation_id']}/access_tokens",
        jwt,
        method="POST",
    )
    return response["token"]


def github_request(path: str, token: str, method: str = "GET"):
    """Call the GitHub API and return the decoded body and the next page URL, if any."""
    url = path if path.startswith(GITHUB_API_URL) else f"{GITHUB_API_URL}{path}"
    request = urllib.request.Request(
        url,
        method=method,
        headers={
            "Accept": "application/vnd.github+json",
            "Authorization": f"Bearer {token}",
            "X-GitHub-Api-Version": "2022-11-28",
        },
    )
    with urllib.request.urlopen(request, timeout=30) as response:  # nosec B310 - fixed https host
        body = json.loads(response.read())
        next_match = re.search(r'<([^>]+)>;\s*rel="next"', response.headers.get("Link", ""))
    return body, next_match.group(1) if next_match else None


def is_backup_enabled(properties: list) -> bool:
    # GitHub returns true_false property values as strings.
    return any(
        item.get("property_name") == BACKUP_PROPERTY and str(item.get("value")).lower() == "true"
        for item in properties
    )


def discover_repositories(token: str) -> list[str]:
    repositories = set()
    next_url = f"/orgs/{GITHUB_ORGANISATION}/properties/values?per_page=100"
    while next_url:
        page, next_url = github_request(next_url, token)
        for record in page:
            if is_backup_enabled(record.get("properties", [])):
                repositories.add(record["repository_full_name"])
    return sorted(repositories)


def validate_repository(repository: str) -> str:
    owner, _, name = repository.partition("/")
    if (
        owner.lower() != GITHUB_ORGANISATION.lower()
        or not REPOSITORY_NAME_PATTERN.match(name)
        or name in {".", ".."}
    ):
        raise ValueError(f"Invalid repository: {repository!r}")
    return name


def dispatch_backups(context) -> dict:
    token = get_installation_token()
    repositories = discover_repositories(token)
    logger.info("Discovered %d opted-in repositories", len(repositories))

    for repository in repositories:
        lambda_client.invoke(
            FunctionName=context.invoked_function_arn,
            InvocationType="Event",
            Payload=json.dumps({"repository": repository}).encode(),
        )
    return {"dispatched": repositories}


def mirror_repository(repository: str, token: str, mirror_dir: str) -> None:
    """Fetch every ref and its reachable history into a bare repository, like `git clone --mirror`."""
    client, path = get_transport_and_path(
        f"https://github.com/{repository}.git",
        username="x-access-token",
        password=token,
    )
    repo = Repo.init_bare(mirror_dir, mkdir=True)
    try:
        # Protocol v0 advertises all refs, including refs/pull/*, as a mirror clone would.
        result = client.fetch(
            path,
            repo,
            determine_wants=repo.object_store.determine_wants_all,
            protocol_version=0,
        )
        for ref, sha in result.refs.items():
            if ref != b"HEAD" and not ref.endswith(b"^{}") and sha is not None:
                repo.refs[ref] = sha
        head_target = (result.symrefs or {}).get(b"HEAD")
        if head_target:
            repo.refs.set_symbolic_ref(b"HEAD", head_target)
        check_connectivity(repo)
    finally:
        repo.close()

    errors = list(porcelain.fsck(mirror_dir))
    if errors:
        raise RuntimeError(f"Integrity check failed for {repository}: {errors[:5]}")


def check_connectivity(repo: Repo) -> None:
    """Fail if any object reachable from a ref is missing; dulwich's fsck doesn't walk the graph."""
    store = repo.object_store
    pending = list(repo.get_refs().values())
    seen = set()
    while pending:
        sha = pending.pop()
        if sha in seen:
            continue
        seen.add(sha)
        try:
            obj = store[sha]
        except KeyError:
            raise RuntimeError(f"Missing object {sha.decode()}") from None

        if isinstance(obj, Commit):
            pending.append(obj.tree)
            pending.extend(obj.parents)
        elif isinstance(obj, Tag):
            pending.append(obj.object[1])
        elif isinstance(obj, Tree):
            for entry in obj.iteritems():
                if S_ISGITLINK(entry.mode):
                    continue  # Submodule commits live in another repository.
                if stat.S_ISDIR(entry.mode):
                    pending.append(entry.sha)
                elif entry.sha not in seen:
                    # Check blobs exist without reading their contents.
                    if entry.sha not in store:
                        raise RuntimeError(f"Missing object {entry.sha.decode()}")
                    seen.add(entry.sha)


def backup_repository(repository: str) -> dict:
    name = validate_repository(repository)
    token = get_installation_token()

    # Re-check the opt-in in case it changed after discovery.
    properties, _ = github_request(f"/repos/{repository}/properties/values", token)
    if not is_backup_enabled(properties):
        logger.info("Skipping %s: backup is not set to true", repository)
        return {"repository": repository, "skipped": True}

    # A timed-out run skips `finally`, and /tmp persists across warm invocations.
    shutil.rmtree(WORK_DIR, ignore_errors=True)
    os.makedirs(WORK_DIR)
    try:
        mirror_dir = os.path.join(WORK_DIR, f"{name}.git")
        logger.info("Creating repository mirror [ %s ]", repository)
        mirror_repository(repository, token, mirror_dir)

        timestamp = datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%SZ")
        archive_name = f"{name}-{timestamp}-{uuid.uuid4().hex[:8]}.tar.gz"
        archive_path = os.path.join(WORK_DIR, archive_name)
        with tarfile.open(archive_path, "w:gz") as archive:
            archive.add(mirror_dir, arcname=f"{name}.git")

        key = f"{repository}/{timestamp[:8]}/{archive_name}"
        logger.info("Uploading backup [ s3://%s/%s ]", BACKUP_BUCKET, key)
        # Rely on the bucket's default KMS encryption and enforced ownership.
        s3.upload_file(archive_path, BACKUP_BUCKET, key)
    finally:
        shutil.rmtree(WORK_DIR, ignore_errors=True)

    return {"repository": repository, "key": key}


def handler(event, context):
    repository = (event or {}).get("repository")
    try:
        if repository:
            return backup_repository(repository)
        return dispatch_backups(context)
    except urllib.error.HTTPError as error:
        logger.error("GitHub API request failed: %s %s", error.code, error.reason)
        raise
