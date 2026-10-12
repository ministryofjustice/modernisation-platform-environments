"""Isolate callers and persist OpenAI prompts before allowing inference or cache access."""

import asyncio
import hashlib
import json
import logging
import os
import re
from collections.abc import Mapping
from datetime import datetime, timezone
from functools import lru_cache
from uuid import uuid4

import boto3
from botocore.config import Config
from botocore.exceptions import BotoCoreError, ClientError
from fastapi import HTTPException
from litellm.integrations.custom_logger import CustomLogger
from litellm.proxy._types import UserAPIKeyAuth


CALLER_HEADER = "x-ai-gateway-caller"
PROMPT_LOG_TIMEOUT_SECONDS = 10
PROMPT_FIELDS = (
    "model", "messages", "prompt", "input", "instructions", "tools", "tool_choice",
    "previous_response_id", "conversation", "reasoning", "text", "response_format",
)
logger = logging.getLogger(__name__)


@lru_cache(maxsize=1)
def prompt_log_client():
    return boto3.session.Session().client(
        "s3",
        region_name=os.environ["OPENAI_PROMPT_LOG_REGION"],
        config=Config(connect_timeout=2, read_timeout=5, retries={"total_max_attempts": 1}),
    )


def put_prompt(key: str, body: bytes) -> dict:
    return prompt_log_client().put_object(
        Bucket=os.environ["OPENAI_PROMPT_LOG_BUCKET"],
        Key=key,
        Body=body,
        ContentType="application/json",
        ServerSideEncryption="aws:kms",
        SSEKMSKeyId=os.environ["OPENAI_PROMPT_LOG_KMS_KEY_ARN"],
        BucketKeyEnabled=True,
        IfNoneMatch="*",
    )


class GatewayPolicy(CustomLogger):
    async def async_pre_call_deployment_hook(self, kwargs, call_type):
        if kwargs.get("api_base") != os.environ["OPENAI_PROXY_API_BASE"]:
            return kwargs

        # Trust the server-created auth object, never a JSON-supplied metadata hash.
        metadata = [kwargs.get(name) or {} for name in ("metadata", "litellm_metadata")]
        authenticated = next(
            (item["user_api_key_auth"] for item in metadata
             if isinstance(item.get("user_api_key_auth"), UserAPIKeyAuth)),
            None,
        )
        caller = authenticated.api_key if authenticated is not None else None
        if caller is None and any(item.get("user_api_key") == "health-check" for item in metadata):
            caller = "health-check"
        if not isinstance(caller, str) or not caller:
            raise HTTPException(403, "OpenAI routing requires an authenticated caller")

        headers = {
            key: value
            for key, value in (kwargs.get("extra_headers") or {}).items()
            if key.lower() != CALLER_HEADER
        }
        headers[CALLER_HEADER] = (
            "health-check" if caller == "health-check" else hashlib.sha256(caller.encode()).hexdigest()
        )
        kwargs["extra_headers"] = headers
        return kwargs


class BackendPolicy(CustomLogger):
    async def async_pre_call_hook(self, user_api_key_dict, cache, data, call_type):
        headers = data.get("proxy_server_request", {}).get("headers", {})
        caller = headers.get(CALLER_HEADER)
        if not isinstance(caller, str) or (
            caller != "health-check" and re.fullmatch(r"[0-9a-f]{64}", caller) is None
        ):
            raise HTTPException(403, "Missing trusted OpenAI caller context")

        requested = data.get("cache") or {}
        if not isinstance(requested, Mapping):
            raise HTTPException(400, "cache must be an object")

        # Never allow a client to select another caller's namespace or extend retention.
        data["cache"] = {
            "namespace": f"openai:{caller}",
            "ttl": 300,
            "s-maxage": 300,
            "no-cache": caller == "health-check" or requested.get("no-cache") is True,
            "no-store": caller == "health-check" or requested.get("no-store") is True,
        }
        data.pop("preset_cache_key", None)
        data.pop("cache_key", None)

        await self.persist_prompt(data, caller, call_type)
        return data

    async def persist_prompt(self, data: dict, caller: str, call_type: str) -> None:
        if not isinstance(data.get("model"), str) or not any(
            field in data for field in ("messages", "prompt", "input", "previous_response_id", "conversation")
        ):
            raise HTTPException(400, "OpenAI prompt logging requires a model and prompt input")

        request_id = str(uuid4())
        recorded_at = datetime.now(timezone.utc)
        key = f"requests/prompts/{recorded_at:%Y/%m/%d}/{request_id}.json"
        record = {
            "schema_version": 1,
            "request_id": request_id,
            "recorded_at": recorded_at.isoformat(),
            "caller": caller,
            "call_type": call_type,
            "litellm_call_id": data.get("litellm_call_id"),
            # Do not serialise proxy internals, headers, credentials or auth objects.
            "request": {field: data[field] for field in PROMPT_FIELDS if field in data},
        }
        try:
            body = json.dumps(record, allow_nan=False).encode("utf-8")
            # Await the write, not a background queue. A timed-out worker may finish later,
            # but its request is rejected and must never continue to inference.
            response = await asyncio.wait_for(
                asyncio.to_thread(put_prompt, key, body),
                timeout=PROMPT_LOG_TIMEOUT_SECONDS,
            )
            if (
                not isinstance(response, Mapping)
                or not isinstance(response.get("ResponseMetadata"), Mapping)
                or response["ResponseMetadata"].get("HTTPStatusCode") != 200
            ):
                raise OSError("S3 did not acknowledge the prompt write")
        except (BotoCoreError, ClientError, TimeoutError, OSError, KeyError, TypeError, ValueError) as error:
            logger.error(
                "OpenAI prompt persistence failed: request_id=%s error_type=%s",
                request_id, type(error).__name__,
            )
            raise HTTPException(503, "OpenAI unavailable: prompt audit logging failed") from error


gateway = GatewayPolicy()
backend = BackendPolicy()
