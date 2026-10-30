"""
Logs prompts and responses to S3 for allowlisted models only.

LiteLLM's S3 logger is all-or-nothing, so this wraps it and drops every event whose
provider model isn't listed in `litellm_settings.s3_callback_params.prompt_logging_models`.
"""

from __future__ import annotations

import asyncio
from typing import Any

import litellm
from litellm._logging import verbose_logger
from litellm.integrations.custom_logger import CustomLogger
from litellm.integrations.s3_v2 import S3Logger

PROVIDER = "openai"


class PromptLogger(CustomLogger):
    def __init__(self) -> None:
        super().__init__()
        self._s3_logger: S3Logger | None = None
        self._models: frozenset[str] | None = None
        self._init_lock = asyncio.Lock()

    def _allowed_models(self) -> frozenset[str]:
        if self._models is None:
            params = litellm.s3_callback_params or {}
            self._models = frozenset(params.get("prompt_logging_models") or [])
        return self._models

    def _should_log(self, kwargs: dict[str, Any]) -> bool:
        payload = kwargs.get("standard_logging_object") or {}
        if payload.get("custom_llm_provider") != PROVIDER:
            return False
        model = payload.get("model") or ""
        
        return model.removeprefix(f"{PROVIDER}/") in self._allowed_models()

    async def _get_s3_logger(self) -> S3Logger:
        async with self._init_lock:
            if self._s3_logger is None:
                self._s3_logger = S3Logger()
        return self._s3_logger

    async def async_log_success_event(self, kwargs, response_obj, start_time, end_time):
        if self._should_log(kwargs):
            s3_logger = await self._get_s3_logger()
            await s3_logger.async_log_success_event(kwargs, response_obj, start_time, end_time)

    async def async_log_failure_event(self, kwargs, response_obj, start_time, end_time):
        if self._should_log(kwargs):
            s3_logger = await self._get_s3_logger()
            await s3_logger.async_log_failure_event(kwargs, response_obj, start_time, end_time)


prompt_logger = PromptLogger()