import json
import re
from typing import Any

from litellm.integrations.custom_logger import CustomLogger
from litellm.proxy.proxy_server import DualCache, UserAPIKeyAuth


class ToonTransformHook(CustomLogger):
    """Convert selected JSON prompt blocks to TOON before provider calls."""

    _json_fence_pattern = re.compile(
        r"```json\s*(?P<payload>\{.*?\}|\[.*?\])\s*```",
        re.IGNORECASE | re.DOTALL,
    )

    async def async_pre_call_hook(
        self,
        user_api_key_dict: UserAPIKeyAuth,
        cache: DualCache,
        data: dict,
        call_type: str,
    ) -> dict:
        if call_type not in {"completion", "text_completion"}:
            return data

        messages = data.get("messages")
        if not isinstance(messages, list):
            return data

        for message in messages:
            content = message.get("content")
            if isinstance(content, str):
                message["content"] = self._transform_prompt_content(content)

        return data

    def _transform_prompt_content(self, text: str) -> str:
        def replace_json_fence(match: re.Match[str]) -> str:
            payload = match.group("payload")
            try:
                parsed = json.loads(payload)
            except json.JSONDecodeError:
                return match.group(0)

            toon = self._json_to_toon(parsed)
            if toon is None:
                return match.group(0)

            return f"Data is in TOON format:\n\n```toon\n{toon}\n```"

        return self._json_fence_pattern.sub(replace_json_fence, text)

    def _json_to_toon(self, payload: Any) -> str | None:
        if isinstance(payload, list):
            return self._render_uniform_array("items", payload)

        if isinstance(payload, dict):
            if len(payload) != 1:
                return None

            key, value = next(iter(payload.items()))
            if not isinstance(value, list):
                return None

            return self._render_uniform_array(str(key), value)

        return None

    def _render_uniform_array(self, name: str, items: list[Any]) -> str | None:
        if not items:
            return None

        if not all(isinstance(item, dict) for item in items):
            return None

        headers = list(items[0].keys())
        if not headers:
            return None

        for item in items:
            if list(item.keys()) != headers:
                return None

        rows: list[str] = []
        for item in items:
            row_values: list[str] = []
            for header in headers:
                scalar = self._to_toon_scalar(item[header])
                if scalar is None:
                    return None
                row_values.append(scalar)
            rows.append("  " + ",".join(row_values))

        header_csv = ",".join(headers)
        lines = [f"{name}[{len(items)}]{{{header_csv}}}:"]
        lines.extend(rows)
        return "\n".join(lines)

    def _to_toon_scalar(self, value: Any) -> str | None:
        if isinstance(value, bool):
            return "true" if value else "false"

        if value is None:
            return "null"

        if isinstance(value, (int, float)):
            return str(value)

        if not isinstance(value, str):
            return None

        needs_quotes = (
            value == ""
            or value != value.strip()
            or any(char in value for char in [",", "\n", '"'])
        )
        if needs_quotes:
            return json.dumps(value, ensure_ascii=True)

        return value


proxy_handler_instance = ToonTransformHook()
