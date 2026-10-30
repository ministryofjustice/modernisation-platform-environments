import json
import logging
import os
import random
import time
import urllib.error
import urllib.parse
import urllib.request

logger = logging.getLogger(__name__)

ENDPOINT_ENV_VAR = "EVENTS_API_URL"
MAX_ATTEMPTS = 3
TIMEOUT_SECONDS = 5
BASE_BACKOFF_SECONDS = 0.5
RETRYABLE_STATUS_CODES = {429, 500, 502, 503, 504}


def send(event_name, payload=None, *, raise_on_failure=False):
    """Publish an event, optionally with a JSON-serialisable dict payload.

    Retries on network errors, 429 and 5xx responses. Returns True when the API
    accepts the event. If delivery fails it logs the error and returns False,
    unless raise_on_failure is set, in which case the last error is raised.
    """
    try:
        _post(event_name, payload)
        return True
    except Exception as error:
        if raise_on_failure:
            raise
        logger.error("Failed to publish event %r: %s", event_name, error)
        return False


def _post(event_name, payload):
    endpoint = os.environ.get(ENDPOINT_ENV_VAR)
    if not endpoint:
        raise RuntimeError(f"{ENDPOINT_ENV_VAR} is not set")
    if not event_name:
        raise ValueError("event_name is required")
    if payload is not None and not isinstance(payload, dict):
        raise TypeError("payload must be a dict")

    url = f"{endpoint.rstrip('/')}/events/{urllib.parse.quote(event_name, safe='')}"
    # The API uses the whole request body as the event detail, so it must always be a JSON object.
    body = json.dumps(payload if payload is not None else {}).encode("utf-8")
    request = urllib.request.Request(
        url, data=body, method="POST", headers={"Content-Type": "application/json"}
    )

    for attempt in range(1, MAX_ATTEMPTS + 1):
        try:
            with urllib.request.urlopen(request, timeout=TIMEOUT_SECONDS):
                return
        except urllib.error.HTTPError as error:
            if error.code not in RETRYABLE_STATUS_CODES or attempt == MAX_ATTEMPTS:
                raise
            error.close()
        except (urllib.error.URLError, TimeoutError, ConnectionError):
            if attempt == MAX_ATTEMPTS:
                raise
        time.sleep(BASE_BACKOFF_SECONDS * 2 ** (attempt - 1) * random.uniform(0.5, 1.5))
