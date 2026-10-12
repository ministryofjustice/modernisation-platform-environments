import asyncio
import hashlib
import json
import os
import sys
import threading
import unittest
from pathlib import Path
from unittest.mock import AsyncMock, patch

import httpx
import litellm
from botocore.exceptions import ClientError, EndpointConnectionError, NoCredentialsError
from fastapi import HTTPException
from litellm.caching.caching import Cache
from litellm.integrations.s3_v2 import S3Logger
from litellm.llms.custom_httpx.http_handler import AsyncHTTPHandler
from litellm.proxy._types import UserAPIKeyAuth
from litellm.proxy.common_utils.user_api_key_cache import UserApiKeyCache
from litellm.proxy.utils import ProxyLogging
from openai import AsyncOpenAI

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "src"))
from openai_policy import CALLER_HEADER, BackendPolicy, GatewayPolicy, prompt_log_client


API_BASE = "http://litellm-openai.ai-gateway.svc.cluster.local:4000/v1"


class OpenAIPolicyTests(unittest.IsolatedAsyncioTestCase):
    async def asyncSetUp(self):
        self.env = patch.dict(os.environ, {
            "OPENAI_PROXY_API_BASE": API_BASE,
            "OPENAI_PROMPT_LOG_BUCKET": "test-prompt-logs",
            "OPENAI_PROMPT_LOG_REGION": "eu-west-2",
            "OPENAI_PROMPT_LOG_KMS_KEY_ARN": "arn:aws:kms:eu-west-2:123456789012:key/test",
            "AWS_EC2_METADATA_DISABLED": "true",
        })
        self.env.start()
        self.addCleanup(self.env.stop)
        self.gateway = GatewayPolicy()
        self.backend = BackendPolicy()
        self.s3_patch = patch("openai_policy.prompt_log_client")
        self.s3 = self.s3_patch.start().return_value
        self.addCleanup(self.s3_patch.stop)
        self.s3.put_object.return_value = {"ResponseMetadata": {"HTTPStatusCode": 200}}

    async def backend_request(self, caller, **kwargs):
        return await self.backend.async_pre_call_hook(
            None, None, {
                "model": "gpt-5.4", "messages": [{"role": "user", "content": "test prompt"}],
                "proxy_server_request": {"headers": {CALLER_HEADER: caller}}, **kwargs,
            }, "completion"
        )

    async def proxy_request(self, data):
        proxy = ProxyLogging(user_api_key_cache=UserApiKeyCache())
        with patch.object(litellm, "callbacks", [self.backend]):
            return await proxy.pre_call_hook(
                user_api_key_dict=UserAPIKeyAuth(api_key="test-internal-key"),
                data=data, call_type="completion",
            )

    async def test_prompt_write_uses_encryption_unique_keys_and_no_proxy_credentials(self):
        request = {
            "instructions": "system instructions",
            "tools": [{"type": "function", "function": {"name": "test_tool"}}],
            "litellm_call_id": "test-call-id",
            "api_key": "must-not-be-logged",
            "metadata": {"credentials": "must-not-be-logged"},
            "proxy_server_request": {
                "headers": {CALLER_HEADER: "a" * 64, "authorization": "must-not-be-logged"},
            },
            "no-log": True,
        }
        await self.backend_request("a" * 64, **request)
        await self.backend_request("a" * 64, **request)
        first, second = [call.kwargs for call in self.s3.put_object.call_args_list]
        self.assertEqual(first["Bucket"], "test-prompt-logs")
        self.assertEqual(first["ServerSideEncryption"], "aws:kms")
        self.assertEqual(first["SSEKMSKeyId"], os.environ["OPENAI_PROMPT_LOG_KMS_KEY_ARN"])
        self.assertTrue(first["BucketKeyEnabled"])
        self.assertEqual(first["IfNoneMatch"], "*")
        self.assertEqual(first["ContentType"], "application/json")
        self.assertRegex(first["Key"], r"^requests/prompts/\d{4}/\d{2}/\d{2}/[0-9a-f-]+\.json$")
        self.assertNotEqual(first["Key"], second["Key"])
        record = json.loads(first["Body"])
        self.assertEqual(record["caller"], "a" * 64)
        self.assertEqual(record["litellm_call_id"], "test-call-id")
        self.assertEqual(record["request"]["instructions"], request["instructions"])
        self.assertEqual(record["request"]["tools"], request["tools"])
        self.assertEqual(record["request"]["messages"], [{"role": "user", "content": "test prompt"}])
        self.assertNotIn(b"must-not-be-logged", first["Body"])

    async def test_responses_input_and_conversation_references_are_recorded(self):
        data = {
            "model": "gpt-5.4", "input": [{"role": "user", "content": "responses prompt"}],
            "previous_response_id": "resp_previous",
            "proxy_server_request": {"headers": {CALLER_HEADER: "b" * 64}},
        }
        await self.backend.async_pre_call_hook(None, None, data, "aresponses")
        record = json.loads(self.s3.put_object.call_args.kwargs["Body"])
        self.assertEqual(record["call_type"], "aresponses")
        self.assertEqual(record["request"]["input"], data["input"])
        self.assertEqual(record["request"]["previous_response_id"], "resp_previous")

    async def test_s3_errors_propagate_through_native_proxy_hook_before_inference(self):
        failures = [
            ClientError({"Error": {"Code": "AccessDenied", "Message": "test denial"}}, "PutObject"),
            NoCredentialsError(),
            EndpointConnectionError(endpoint_url="https://s3.invalid"),
        ]
        infer = AsyncMock()
        for failure in failures:
            with self.subTest(failure=type(failure).__name__):
                self.s3.put_object.side_effect = failure
                with self.assertLogs("openai_policy", level="ERROR") as logs:
                    with self.assertRaises(HTTPException) as rejected:
                        await self.proxy_request({
                            "model": "gpt-5.4", "messages": [{"role": "user", "content": "private prompt"}],
                            "proxy_server_request": {"headers": {CALLER_HEADER: "a" * 64}},
                            "no-log": True,
                        })
                        await infer()
                self.assertEqual(rejected.exception.status_code, 503)
                self.assertNotIn("private prompt", "\n".join(logs.output))
                infer.assert_not_awaited()

    async def test_missing_configuration_and_unacknowledged_writes_fail_closed(self):
        with patch.dict(os.environ):
            del os.environ["OPENAI_PROMPT_LOG_BUCKET"]
            with self.assertLogs("openai_policy", level="ERROR"), self.assertRaises(HTTPException) as rejected:
                await self.backend_request("a" * 64)
            self.assertEqual(rejected.exception.status_code, 503)
        for response in (None, {}, {"ResponseMetadata": None}, {"ResponseMetadata": {"HTTPStatusCode": 500}}):
            with self.subTest(response=response):
                self.s3.put_object.return_value = response
                with self.assertLogs("openai_policy", level="ERROR"), self.assertRaises(HTTPException) as rejected:
                    await self.backend_request("a" * 64)
                self.assertEqual(rejected.exception.status_code, 503)

    async def test_request_waits_for_acknowledgement_and_times_out_closed(self):
        started = threading.Event()
        release = threading.Event()

        def blocking_write(**kwargs):
            started.set()
            if not release.wait(timeout=2):
                raise TimeoutError("test write was not released")
            return {"ResponseMetadata": {"HTTPStatusCode": 200}}

        self.s3.put_object.side_effect = blocking_write
        pending = asyncio.create_task(self.backend_request("a" * 64))
        try:
            self.assertTrue(await asyncio.to_thread(started.wait, 1))
            self.assertFalse(pending.done())
        finally:
            release.set()
        await pending

        started.clear()
        release.clear()
        try:
            with patch("openai_policy.PROMPT_LOG_TIMEOUT_SECONDS", 0.02):
                with self.assertLogs("openai_policy", level="ERROR"), self.assertRaises(HTTPException) as rejected:
                    await self.backend_request("a" * 64)
            self.assertEqual(rejected.exception.status_code, 503)
        finally:
            release.set()

    async def test_s3_client_has_bounded_network_timeouts_and_retries(self):
        with patch("openai_policy.boto3.session.Session") as session:
            prompt_log_client.__wrapped__()
        arguments = session.return_value.client.call_args
        self.assertEqual(arguments.args, ("s3",))
        self.assertEqual(arguments.kwargs["region_name"], "eu-west-2")
        config = arguments.kwargs["config"]
        self.assertEqual(config.connect_timeout, 2)
        self.assertEqual(config.read_timeout, 5)
        self.assertEqual(config.retries["total_max_attempts"], 1)

    async def test_gateway_overwrites_spoofed_header_for_both_metadata_formats(self):
        for field in ("metadata", "litellm_metadata"):
            with self.subTest(field=field):
                result = await self.gateway.async_pre_call_deployment_hook(
                    {
                        "api_base": API_BASE,
                        field: {"user_api_key_auth": UserAPIKeyAuth(api_key="authenticated-key-hash")},
                        "extra_headers": {"X-AI-Gateway-Caller": "forged", "other-header": "preserved"},
                    },
                    None,
                )
                self.assertEqual(result["extra_headers"], {
                    CALLER_HEADER: hashlib.sha256(b"authenticated-key-hash").hexdigest(),
                    "other-header": "preserved",
                })

    async def test_json_metadata_cannot_spoof_authenticated_caller(self):
        auth = UserAPIKeyAuth(api_key="authenticated-key-hash")
        result = await self.gateway.async_pre_call_deployment_hook({
            "api_base": API_BASE,
            "metadata": {"user_api_key_auth": auth},
            "litellm_metadata": {"user_api_key": "victim", "user_api_key_auth": {"api_key": "victim"}},
        }, None)
        self.assertEqual(result["extra_headers"][CALLER_HEADER],
                         hashlib.sha256(b"authenticated-key-hash").hexdigest())
        with self.assertRaises(HTTPException):
            await self.gateway.async_pre_call_deployment_hook({
                "api_base": API_BASE, "metadata": {"user_api_key": "victim"},
            }, None)

    async def test_other_providers_are_unchanged(self):
        request = {"api_base": "https://foundry.example.com", "metadata": {"user_api_key": "test"}}
        self.assertEqual(await self.gateway.async_pre_call_deployment_hook(request.copy(), None), request)

    async def test_missing_caller_fails_closed(self):
        with self.assertRaises(HTTPException) as error:
            await self.gateway.async_pre_call_deployment_hook({"api_base": API_BASE}, None)
        self.assertEqual(error.exception.status_code, 403)
        for caller in (None, "", "forged", "../other-caller"):
            with self.subTest(caller=caller), self.assertRaises(HTTPException):
                await self.backend_request(caller)

    async def test_cache_is_per_caller_and_retention_cannot_be_overridden(self):
        cache = Cache(type="local")
        common = {"model": "gpt-5.4", "messages": [{"role": "user", "content": "same prompt"}]}
        first = await self.backend_request("a" * 64, cache={"namespace": "shared", "ttl": 9999})
        second = await self.backend_request("b" * 64)
        repeat = await self.backend_request("a" * 64)
        self.assertEqual(first["cache"]["ttl"], 300)
        self.assertEqual(first["cache"]["s-maxage"], 300)
        first_key = cache.get_cache_key(**common, cache=first["cache"])
        self.assertEqual(first_key, cache.get_cache_key(**common, cache=repeat["cache"]))
        self.assertNotEqual(first_key, cache.get_cache_key(**common, cache=second["cache"]))
        self.assertTrue(first_key.startswith(f"openai:{'a' * 64}:"))

    async def test_cache_opt_out_and_health_probes(self):
        result = await self.backend_request("a" * 64, cache={"no-cache": True, "no-store": True})
        self.assertTrue(result["cache"]["no-cache"])
        self.assertTrue(result["cache"]["no-store"])
        health = await self.gateway.async_pre_call_deployment_hook(
            {"api_base": API_BASE, "metadata": {"user_api_key": "health-check"}}, None
        )
        result = await self.backend_request(health["extra_headers"][CALLER_HEADER])
        self.assertTrue(result["cache"]["no-cache"])
        self.assertTrue(result["cache"]["no-store"])

    async def test_invalid_cache_controls_and_preset_keys(self):
        with self.assertRaises(HTTPException):
            await self.backend_request("a" * 64, cache="invalid")
        result = await self.backend_request("a" * 64, preset_cache_key="shared", cache_key="shared")
        self.assertNotIn("preset_cache_key", result)
        self.assertNotIn("cache_key", result)

    async def test_real_litellm_chat_routing_carries_caller_header(self):
        captured = []

        def respond(request):
            captured.append(request)
            return httpx.Response(200, json={
                "id": "chatcmpl-test",
                "object": "chat.completion",
                "created": 1,
                "model": "gpt-5.4",
                "choices": [{"index": 0, "message": {"role": "assistant", "content": "test response"},
                             "finish_reason": "stop"}],
                "usage": {"prompt_tokens": 10, "completion_tokens": 5, "total_tokens": 15},
            })

        async with httpx.AsyncClient(transport=httpx.MockTransport(respond)) as http_client:
            client = AsyncOpenAI(api_key="test-internal-key", base_url=API_BASE, http_client=http_client)
            router = litellm.Router(model_list=[{
                "model_name": "openai-gpt-5.4",
                "litellm_params": {"model": "litellm_proxy/gpt-5.4", "api_base": API_BASE,
                                  "api_key": "test-internal-key"},
            }], num_retries=0)
            with patch.object(litellm, "callbacks", [self.gateway]):
                response = await router.acompletion(
                    model="openai-gpt-5.4",
                    messages=[{"role": "user", "content": "test prompt"}],
                    metadata={"user_api_key_auth": UserAPIKeyAuth(api_key="authenticated-key-hash")},
                    client=client,
                )
            self.assertEqual(response.choices[0].message.content, "test response")
            self.assertEqual(len(captured), 1)
            self.assertEqual(captured[0].headers[CALLER_HEADER],
                             hashlib.sha256(b"authenticated-key-hash").hexdigest())
            self.assertEqual(captured[0].headers["authorization"], "Bearer test-internal-key")
            self.assertEqual(json.loads(captured[0].content)["model"], "gpt-5.4")
            self.assertGreater(litellm.completion_cost(
                completion_response=response, model="litellm_proxy/gpt-5.4"), 0)

    async def test_real_litellm_responses_routing_carries_caller_header(self):
        captured = []

        def respond(request):
            captured.append(request)
            return httpx.Response(200, json={
                "id": "resp_test", "object": "response", "created_at": 1,
                "model": "gpt-5.4", "status": "completed", "output": [],
                "usage": {"input_tokens": 10, "output_tokens": 5, "total_tokens": 15},
            })

        async with httpx.AsyncClient(transport=httpx.MockTransport(respond)) as http_client:
            with patch.object(AsyncHTTPHandler, "create_client", return_value=http_client):
                client = AsyncHTTPHandler()
            with patch.object(litellm, "callbacks", [self.gateway]):
                await litellm.aresponses(
                    model="litellm_proxy/gpt-5.4", api_base=API_BASE, api_key="test-internal-key",
                    input="test prompt",
                    litellm_metadata={"user_api_key_auth": UserAPIKeyAuth(api_key="authenticated-key-hash")},
                    client=client,
                )
        self.assertEqual(len(captured), 1)
        self.assertEqual(captured[0].url.path, "/v1/responses")
        self.assertEqual(captured[0].headers[CALLER_HEADER],
                         hashlib.sha256(b"authenticated-key-hash").hexdigest())

    async def test_streaming_chat_preserves_caller_context(self):
        captured = []

        def respond(request):
            captured.append(request)
            chunk = {
                "id": "chatcmpl-stream", "object": "chat.completion.chunk", "created": 1,
                "model": "gpt-5.4",
                "choices": [{"index": 0, "delta": {"role": "assistant", "content": "streamed response"},
                             "finish_reason": None}],
            }
            return httpx.Response(200, text=f"data: {json.dumps(chunk)}\n\ndata: [DONE]\n\n",
                                  headers={"content-type": "text/event-stream"})

        async with httpx.AsyncClient(transport=httpx.MockTransport(respond)) as http_client:
            client = AsyncOpenAI(api_key="test-key", base_url=API_BASE, http_client=http_client)
            with patch.object(litellm, "callbacks", [self.gateway]):
                stream = await litellm.acompletion(
                    model="litellm_proxy/gpt-5.4", api_base=API_BASE, api_key="test-key",
                    messages=[{"role": "user", "content": "test prompt"}], stream=True,
                    metadata={"user_api_key_auth": UserAPIKeyAuth(api_key="authenticated-key-hash")},
                    client=client,
                )
                chunks = [chunk async for chunk in stream]
        self.assertEqual("".join(chunk.choices[0].delta.content or "" for chunk in chunks if chunk.choices),
                         "streamed response")
        self.assertEqual(captured[0].headers[CALLER_HEADER],
                         hashlib.sha256(b"authenticated-key-hash").hexdigest())

    async def test_backend_cache_hits_and_s3_payloads_without_live_services(self):
        provider_calls = []
        logged = asyncio.Event()

        def respond(request):
            provider_calls.append(request)
            persisted = json.loads(self.s3.put_object.call_args.kwargs["Body"])
            self.assertEqual(persisted["request"]["messages"], json.loads(request.content)["messages"])
            return httpx.Response(200, json={
                "id": f"chatcmpl-{len(provider_calls)}", "object": "chat.completion",
                "created": 1, "model": "gpt-5.4",
                "choices": [{"index": 0, "message": {"role": "assistant", "content": "stored response"},
                             "finish_reason": "stop"}],
                "usage": {"prompt_tokens": 10, "completion_tokens": 5, "total_tokens": 15},
            })

        logger = S3Logger(s3_bucket_name="test-logs", s3_region_name="eu-west-2", s3_path="requests")
        original_log = logger.async_log_success_event

        async def record(*args, **kwargs):
            await original_log(*args, **kwargs)
            logged.set()

        response_cache = Cache(type="local")
        async with httpx.AsyncClient(transport=httpx.MockTransport(respond)) as http_client:
            client = AsyncOpenAI(api_key="test-key", base_url="https://provider.invalid/v1",
                                 http_client=http_client)
            with (
                patch.object(litellm, "cache", response_cache),
                patch.object(litellm, "callbacks", []),
                patch.object(litellm, "success_callback", [logger]),
                patch.object(litellm, "_async_success_callback", [logger]),
                patch.object(logger, "async_log_success_event", side_effect=record),
                patch.object(logger, "async_upload_data_to_s3", new_callable=AsyncMock),
            ):
                for caller in ("a" * 64, "a" * 64, "b" * 64):
                    policy = await self.backend_request(
                        caller, messages=[{"role": "user", "content": "stored prompt"}]
                    )
                    logged.clear()
                    await litellm.acompletion(
                        model="openai/gpt-5.4", messages=[{"role": "user", "content": "stored prompt"}],
                        api_base="https://provider.invalid/v1", api_key="test-key",
                        cache=policy["cache"], client=client,
                    )
                    await asyncio.wait_for(logged.wait(), timeout=5)
                self.s3.put_object.side_effect = NoCredentialsError()
                with patch.object(response_cache, "async_get_cache", wraps=response_cache.async_get_cache) as lookup:
                    with self.assertLogs("openai_policy", level="ERROR"), self.assertRaises(HTTPException) as rejected:
                        policy = await self.proxy_request({
                            "model": "gpt-5.4", "messages": [{"role": "user", "content": "stored prompt"}],
                            "proxy_server_request": {"headers": {CALLER_HEADER: "a" * 64}},
                        })
                        await litellm.acompletion(
                            model="openai/gpt-5.4", messages=policy["messages"],
                            api_base="https://provider.invalid/v1", api_key="test-key",
                            cache=policy["cache"], client=client,
                        )
                    self.assertEqual(rejected.exception.status_code, 503)
                    lookup.assert_not_called()
        self.assertEqual(len(provider_calls), 2)
        self.assertEqual(self.s3.put_object.call_count, 4)
        self.assertEqual(len(logger.log_queue), 3)
        for payload in logger.log_queue:
            serialised = payload.model_dump_json()
            self.assertIn("stored prompt", serialised)
            self.assertIn("stored response", serialised)


if __name__ == "__main__":
    unittest.main()
