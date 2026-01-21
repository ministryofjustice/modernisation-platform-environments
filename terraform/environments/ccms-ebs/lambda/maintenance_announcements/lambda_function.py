# This AWS Lambda function toggles a WAF rule between BLOCK and ALLOW modes,
# Display a custom HTML response body when blocking requests and remove it for Allow mode.
import os
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

# ---------------------------------------------------------------------------
# Logging setup
# ---------------------------------------------------------------------------

logger = logging.getLogger(__name__)
if not logger.handlers:
    logging.basicConfig(level=logging.INFO)
logger.setLevel(logging.INFO)

# ---------------------------------------------------------------------------
# Env helpers
# ---------------------------------------------------------------------------

def _get_required_env(name: str) -> str:
    value = os.environ.get(name)
    if not value:
        raise ValueError(f"Environment variable '{name}' is required but not set.")
    return value


# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------

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


def _get_maintenance_html() -> str:
    """Return maintenance HTML: CUSTOM_BODY_HTML if set, otherwise rendered template."""
    if CUSTOM_BODY_HTML.strip():
        return CUSTOM_BODY_HTML
    return MAINTENANCE_HTML_TEMPLATE.format(time_from=TIME_FROM, time_to=TIME_TO)


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

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

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


# ---------------------------------------------------------------------------
# Lambda handler
# ---------------------------------------------------------------------------

def lambda_handler(event: Any, context: Any) -> Dict[str, Any]:
    mode: WafMode = _parse_mode(event)

    logger.info(
        "Requested mode '%s' for rule '%s' in WebACL '%s' (ID=%s, scope=%s)",
        mode,
        RULE_NAME,
        WEB_ACL_NAME,
        WEB_ACL_ID,
        SCOPE,
    )

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

            # When BLOCK: ensure the custom response body is present
            if mode == "BLOCK":
                custom_response_bodies[CUSTOM_BODY_NAME] = {
                    "Content": _get_maintenance_html(),
                    "ContentType": "TEXT_HTML",
                }

            # When ALLOW: remove custom body to avoid Terraform drift
            elif mode == "ALLOW":
                if CUSTOM_BODY_NAME in custom_response_bodies:
                    del custom_response_bodies[CUSTOM_BODY_NAME]

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
