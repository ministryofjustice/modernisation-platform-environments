# This AWS Lambda function toggles a WAF rule between BLOCK and ALLOW modes,
# Display a custom HTML response body when blocking requests and remove it for Allow mode.

import os
import re
import copy
import logging
from typing import Any, Dict, Literal, TYPE_CHECKING, TypeAlias, cast

import boto3
from botocore.exceptions import ClientError, BotoCoreError

# --- mypy-only imports (DO NOT run in Lambda runtime) ---
if TYPE_CHECKING:
    from mypy_boto3_wafv2.type_defs import RuleActionOutputTypeDef

    RuleActionType: TypeAlias = RuleActionOutputTypeDef
else:
    RuleActionType: TypeAlias = Dict[str, Any]

# Logging setup
logger = logging.getLogger(__name__)
if not logger.handlers:
    logging.basicConfig(level=logging.INFO)
logger.setLevel(logging.INFO)


# Env helpers
def _get_required_env(name: str) -> str:
    value = os.environ.get(name)
    if not value:
        raise ValueError(f"Environment variable '{name}' is required but not set.")
    return value


# Configuration
WEB_ACL_NAME: str = _get_required_env("WEB_ACL_NAME")
WEB_ACL_ID: str = _get_required_env("WEB_ACL_ID")
RULE_NAME: str = _get_required_env("RULE_NAME")

ScopeLiteral = Literal["REGIONAL", "CLOUDFRONT"]
_raw_scope = os.environ.get("SCOPE", "REGIONAL").upper()
if _raw_scope not in ("REGIONAL", "CLOUDFRONT"):
    raise ValueError(
        f"Unsupported SCOPE '{_raw_scope}'. Must be 'REGIONAL' or 'CLOUDFRONT'."
    )
SCOPE: ScopeLiteral = cast(ScopeLiteral, _raw_scope)

CUSTOM_BODY_NAME: str = os.environ.get("CUSTOM_BODY_NAME", "maintenance_html")
CUSTOM_BODY_HTML: str = os.environ.get("CUSTOM_BODY_HTML", "")

# Time configuration (with defaults)
TIME_FROM: str = os.environ.get("TIME_FROM", "21:30")
TIME_TO: str = os.environ.get("TIME_TO", "07:00")

# HTML template with placeholders (used when CUSTOM_BODY_HTML is not set)
MAINTENANCE_HTML_TEMPLATE: str = """<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<title>Maintenance</title>
<style>
body{{font-family:sans-serif;background:#0b1a2b;color:#fff;text-align:center;padding:4rem;}}
.card{{max-width:600px;margin:auto;background:#12243a;padding:2rem;border-radius:10px;}}
</style>
</head>
<body>
<div class="card">
<h1>Scheduled Maintenance</h1>
<p>The service is unavailable from {time_from} to {time_to} UK time.<br>
It is not available on bank holidays.</p>
</div>
</body>
</html>"""


def _get_maintenance_html(time_from: str, time_to: str) -> str:
    """Return maintenance HTML: CUSTOM_BODY_HTML if set, otherwise rendered template."""
    if CUSTOM_BODY_HTML.strip():
        return CUSTOM_BODY_HTML
    return MAINTENANCE_HTML_TEMPLATE.format(time_from=time_from, time_to=time_to)


# Set region (CloudFront uses us-east-1)
if SCOPE == "CLOUDFRONT":
    region: str = "us-east-1"
else:
    region_env = os.environ.get("AWS_REGION")
    if region_env is None:
        raise ValueError(
            "AWS_REGION environment variable is required for REGIONAL scope."
        )
    region = region_env

waf = boto3.client("wafv2", region_name=region)

WafMode = Literal["BLOCK", "ALLOW"]


# ----------------
# Helper functions
# ----------------


def _desired_action(mode: WafMode) -> RuleActionType:
    """Return WAF Action structure for direct rules."""
    if mode == "BLOCK":
        return {
            "Block": {
                "CustomResponse": {
                    "ResponseCode": 503,
                    "CustomResponseBodyKey": CUSTOM_BODY_NAME,
                }
            }
        }

    if mode == "ALLOW":
        return {"Allow": {}}

    raise ValueError(f"Unsupported mode: {mode}")


def _parse_mode(event: Any) -> WafMode:
    if not isinstance(event, dict):
        return "BLOCK"
    raw_mode = event.get("mode", "BLOCK")
    if not isinstance(raw_mode, str):
        return "BLOCK"
    mode_upper = raw_mode.upper()
    if mode_upper not in ("BLOCK", "ALLOW"):
        return "BLOCK"
    return cast(WafMode, mode_upper)


_TIME_RE = re.compile(r"^([01]\d|2[0-3]):[0-5]\d$")


def _validate_time(value: str, label: str) -> str | None:
    """Return an error message if value is not a valid HH:MM time, or None if valid."""
    if not _TIME_RE.match(value):
        return f"Invalid time format for '{label}': '{value}'. Expected HH:MM (00:00–23:59)."
    return None


def _parse_time_value(event: Any, key: str, fallback: str) -> str:
    """Parse a time value from event, falling back to provided default."""
    if isinstance(event, dict):
        value = event.get(key)
        if isinstance(value, str) and value.strip():
            return value.strip()
    return fallback


# --------------
# Lambda handler
# --------------


_VALID_EVENT_KEYS = {"mode", "time_from", "time_to"}


def lambda_handler(event: Any, context: Any) -> Dict[str, Any]:
    if not isinstance(event, dict):
        logger.error("Event must be a JSON object, got %s.", type(event).__name__)
        return {
            "ok": False,
            "updated": False,
            "error": f"Event must be a JSON object, got {type(event).__name__}.",
        }

    unknown_keys = set(event.keys()) - _VALID_EVENT_KEYS
    if unknown_keys:
        logger.error(
            "Unknown event keys: %s. Valid keys: %s", unknown_keys, _VALID_EVENT_KEYS
        )
        return {
            "ok": False,
            "updated": False,
            "error": f"Unknown event keys: {unknown_keys}. Valid keys: {_VALID_EVENT_KEYS}",
        }

    mode: WafMode = _parse_mode(event)
    time_from: str = _parse_time_value(event, "time_from", TIME_FROM)
    time_to: str = _parse_time_value(event, "time_to", TIME_TO)

    for label, value in [("time_from", time_from), ("time_to", time_to)]:
        err = _validate_time(value, label)
        if err:
            logger.error(err)
            return {"ok": False, "updated": False, "mode": mode, "error": err}

    logger.info(
        "Requested mode '%s' for rule '%s' in WebACL '%s' (ID=%s, scope=%s)",
        mode,
        RULE_NAME,
        WEB_ACL_NAME,
        WEB_ACL_ID,
        SCOPE,
    )
    logger.info("Maintenance window: %s to %s", time_from, time_to)

    # Get current Web ACL
    try:
        resp = waf.get_web_acl(Name=WEB_ACL_NAME, Scope=SCOPE, Id=WEB_ACL_ID)
    except (ClientError, BotoCoreError) as e:
        logger.exception("Failed to get WebACL: %s", e)
        return {"ok": False, "updated": False, "mode": mode, "error": str(e)}

    lock_token = resp.get("LockToken")
    web_acl = resp.get("WebACL")
    if not lock_token or not web_acl:
        return {
            "ok": False,
            "updated": False,
            "mode": mode,
            "error": "Missing LockToken or WebACL",
        }

    rules = web_acl.get("Rules", [])
    if not isinstance(rules, list):
        return {
            "ok": False,
            "updated": False,
            "mode": mode,
            "error": "Rules is not a list",
        }

    custom_response_bodies = web_acl.get("CustomResponseBodies") or {}
    if not isinstance(custom_response_bodies, dict):
        custom_response_bodies = {}

    found = False
    changed = False
    new_rules = []

    for r in rules:
        if not isinstance(r, dict) or "Name" not in r:
            new_rules.append(r)
            continue

        if r["Name"] != RULE_NAME:
            new_rules.append(r)
            continue

        found = True
        rr = copy.deepcopy(r)

        if "Action" not in r:
            return {
                "ok": False,
                "updated": False,
                "mode": mode,
                "error": f"Rule '{RULE_NAME}' has no Action",
            }

        current_action = r.get("Action", {})
        desired_action = _desired_action(mode)

        if current_action != desired_action:
            rr["Action"] = desired_action
            changed = True
            logger.info(
                "Updating Action for rule '%s' to: %s", RULE_NAME, desired_action
            )

        # When BLOCK: ensure the custom response body is present and up to date
        if mode == "BLOCK":
            new_body = {
                "Content": _get_maintenance_html(time_from, time_to),
                "ContentType": "TEXT_HTML",
            }
            if custom_response_bodies.get(CUSTOM_BODY_NAME) != new_body:
                custom_response_bodies[CUSTOM_BODY_NAME] = new_body
                changed = True
                logger.info("Updated custom response body HTML.")

        # When ALLOW: remove custom body to avoid Terraform drift
        elif mode == "ALLOW":
            if CUSTOM_BODY_NAME in custom_response_bodies:
                del custom_response_bodies[CUSTOM_BODY_NAME]
                changed = True

        new_rules.append(rr)

    if not found:
        return {
            "ok": False,
            "updated": False,
            "mode": mode,
            "error": f"Rule '{RULE_NAME}' not found",
        }

    if not changed:
        logger.info("No changes needed.")
        return {"ok": True, "updated": False, "mode": mode}

    updated_web_acl: Dict[str, Any] = {
        "Name": WEB_ACL_NAME,
        "Scope": SCOPE,
        "Id": WEB_ACL_ID,
        "LockToken": lock_token,
        "DefaultAction": web_acl.get("DefaultAction", {}),
        "Description": web_acl.get("Description", ""),
        "VisibilityConfig": web_acl.get("VisibilityConfig", {}),
        "Rules": new_rules,
    }

    # Only include CustomResponseBodies if non-empty
    if custom_response_bodies:
        updated_web_acl["CustomResponseBodies"] = custom_response_bodies
    else:
        logger.info("CustomResponseBodies empty — omitting field.")

    try:
        waf.update_web_acl(**updated_web_acl)
        logger.info("WebACL updated successfully.")
        return {"ok": True, "updated": True, "mode": mode}
    except (ClientError, BotoCoreError) as e:
        logger.exception("Failed to update WebACL: %s", e)
        return {"ok": False, "updated": False, "mode": mode, "error": str(e)}


# ---------------------------------------------------------------------------
# Test suite
#
# Run tests with required environment variables:
#
#   WEB_ACL_NAME=test WEB_ACL_ID=test RULE_NAME=test AWS_REGION=eu-west-2 uv run lambda_function.py
# ---------------------------------------------------------------------------


def main() -> None:
    """Run simple tests for parsing functions."""
    passed = 0
    failed = 0

    def assert_eq(actual: object, expected: object, test_name: str) -> None:
        nonlocal passed, failed
        if actual == expected:
            print(f"  PASS: {test_name}")
            passed += 1
        else:
            print(f"  FAIL: {test_name}")
            print(f"        Expected: {expected!r}")
            print(f"        Actual:   {actual!r}")
            failed += 1

    print("Testing _parse_mode()...")
    assert_eq(_parse_mode({"mode": "BLOCK"}), "BLOCK", "mode=BLOCK")
    assert_eq(_parse_mode({"mode": "block"}), "BLOCK", "mode=block (lowercase)")
    assert_eq(_parse_mode({"mode": "ALLOW"}), "ALLOW", "mode=ALLOW")
    assert_eq(_parse_mode({"mode": "allow"}), "ALLOW", "mode=allow (lowercase)")
    assert_eq(
        _parse_mode({"mode": "invalid"}), "BLOCK", "mode=invalid defaults to BLOCK"
    )
    assert_eq(_parse_mode({}), "BLOCK", "empty event defaults to BLOCK")
    assert_eq(_parse_mode(None), "BLOCK", "None event defaults to BLOCK")
    assert_eq(_parse_mode("not a dict"), "BLOCK", "non-dict event defaults to BLOCK")

    print("\nTesting _parse_time_value() with event values...")
    assert_eq(
        _parse_time_value({"time_from": "22:00"}, "time_from", "default"),
        "22:00",
        "time_from from event",
    )
    assert_eq(
        _parse_time_value({"time_to": "06:00"}, "time_to", "default"),
        "06:00",
        "time_to from event",
    )
    assert_eq(
        _parse_time_value({"time_from": "  23:00  "}, "time_from", "default"),
        "23:00",
        "time_from with whitespace is trimmed",
    )

    print("\nTesting _parse_time_value() fallback to default...")
    assert_eq(
        _parse_time_value({}, "time_from", "21:30"),
        "21:30",
        "missing key falls back to default",
    )
    assert_eq(
        _parse_time_value({"time_from": ""}, "time_from", "21:30"),
        "21:30",
        "empty string falls back to default",
    )
    assert_eq(
        _parse_time_value({"time_from": "   "}, "time_from", "21:30"),
        "21:30",
        "whitespace-only falls back to default",
    )
    assert_eq(
        _parse_time_value({"time_from": 123}, "time_from", "21:30"),
        "21:30",
        "non-string value falls back to default",
    )
    assert_eq(
        _parse_time_value(None, "time_from", "21:30"),
        "21:30",
        "None event falls back to default",
    )

    print("\nTesting _parse_time_value() with env var fallbacks (TIME_FROM/TIME_TO)...")
    assert_eq(
        _parse_time_value({}, "time_from", TIME_FROM),
        TIME_FROM,
        f"missing time_from uses TIME_FROM env var ({TIME_FROM})",
    )
    assert_eq(
        _parse_time_value({}, "time_to", TIME_TO),
        TIME_TO,
        f"missing time_to uses TIME_TO env var ({TIME_TO})",
    )

    print("\nTesting event type validation (via lambda_handler)...")
    result = lambda_handler(None, None)
    assert_eq(result["ok"], False, "None event is rejected")
    assert_eq("JSON object" in result.get("error", ""), True, "None error mentions JSON object")

    result = lambda_handler("not a dict", None)
    assert_eq(result["ok"], False, "string event is rejected")

    result = lambda_handler(42, None)
    assert_eq(result["ok"], False, "int event is rejected")

    result = lambda_handler(["a", "list"], None)
    assert_eq(result["ok"], False, "list event is rejected")

    print("\nTesting event key validation (via lambda_handler)...")
    # Unknown key "mod" (typo for "mode") should be rejected
    result = lambda_handler({"mod": "block", "time_from": "19:00", "time_to": "22:00"}, None)
    assert_eq(result["ok"], False, "typo 'mod' is rejected")
    assert_eq("Unknown event keys" in result.get("error", ""), True, "error mentions unknown keys")
    assert_eq("mode" not in result, True, "no 'mode' field in validation error response")

    # Multiple unknown keys
    result = lambda_handler({"action": "block", "foo": "bar"}, None)
    assert_eq(result["ok"], False, "multiple unknown keys rejected")

    # Mix of valid and unknown keys
    result = lambda_handler({"mode": "BLOCK", "typo_key": "value"}, None)
    assert_eq(result["ok"], False, "mix of valid and unknown keys rejected")

    # Valid keys should not be flagged as unknown
    assert_eq(set({"mode": "BLOCK", "time_from": "19:00", "time_to": "22:00"}.keys()) - _VALID_EVENT_KEYS, set(), "all valid keys pass validation")
    assert_eq(set({}.keys()) - _VALID_EVENT_KEYS, set(), "empty event passes validation")
    assert_eq(set({"mode": "ALLOW"}.keys()) - _VALID_EVENT_KEYS, set(), "single valid key passes validation")

    print("\nTesting _validate_time()...")
    assert_eq(_validate_time("00:00", "t"), None, "00:00 is valid")
    assert_eq(_validate_time("23:59", "t"), None, "23:59 is valid")
    assert_eq(_validate_time("07:30", "t"), None, "07:30 is valid")
    assert_eq(_validate_time("24:00", "t") is not None, True, "24:00 is invalid")
    assert_eq(_validate_time("12:60", "t") is not None, True, "12:60 is invalid")
    assert_eq(_validate_time("banana", "t") is not None, True, "banana is invalid")
    assert_eq(_validate_time("7:30", "t") is not None, True, "7:30 missing leading zero is invalid")
    assert_eq(_validate_time("", "t") is not None, True, "empty string is invalid")
    assert_eq(_validate_time("12:00:00", "t") is not None, True, "HH:MM:SS is invalid")

    print("\nTesting _get_maintenance_html()...")
    html = _get_maintenance_html("20:00", "08:00")
    assert_eq("20:00" in html, True, "time_from appears in HTML")
    assert_eq("08:00" in html, True, "time_to appears in HTML")

    print(f"\n{'='*50}")
    print(f"Results: {passed} passed, {failed} failed")
    if failed > 0:
        raise SystemExit(1)


if __name__ == "__main__":
    main()
