# This AWS Lambda function toggles a WAF rule between BLOCK and ALLOW modes,
# Display a custom HTML response body when blocking requests and remove it for Allow mode.
import os
import json
import copy
import logging
from typing import Any, Dict, Literal

import boto3
from botocore.exceptions import ClientError, BotoCoreError
from typing import cast
from mypy_boto3_wafv2.type_defs import RuleActionOutputTypeDef



# ---------------------------------------------------------------------------
# Logging setup
# ---------------------------------------------------------------------------

logger = logging.getLogger(__name__)
if not logger.handlers:
    # Lambda already wires stdout to CloudWatch; this just sets level/format
    logging.basicConfig(level=logging.INFO)
logger.setLevel(logging.INFO)

# ---------------------------------------------------------------------------
# Environment / configuration
# ---------------------------------------------------------------------------
# ScopeType = Literal["REGIONAL", "CLOUDFRONT"]
# SCOPE: ScopeType = _raw_scope  # type: ignore[assignment]

# _raw_scope: str = os.environ.get("SCOPE", "REGIONAL").upper()
# if _raw_scope not in ("REGIONAL", "CLOUDFRONT"):
#     msg = f"Unsupported SCOPE '{_raw_scope}'. Must be 'REGIONAL' or 'CLOUDFRONT'."
#     logger.error(msg)
#     raise ValueError(msg)

def _get_required_env(name: str) -> str:
    """Return a required environment variable or raise a clear error."""
    value = os.environ.get(name)
    # if not value:
    if value is None or value == "":
        msg = f"Environment variable '{name}' is required but not set."
        logger.error(msg)
        raise ValueError(msg)
    return value

# Required env vars
WEB_ACL_NAME: str = _get_required_env("WEB_ACL_NAME")
WEB_ACL_ID: str = _get_required_env("WEB_ACL_ID")
RULE_NAME: str = _get_required_env("RULE_NAME")
region: str = os.environ.get("AWS_REGION") or os.environ.get("AWS_DEFAULT_REGION") or "eu-west-2"

# Optional env vars with defaults
# SCOPE: str = os.environ.get("SCOPE", "REGIONAL").upper()
CUSTOM_BODY_NAME: str = os.environ.get("CUSTOM_BODY_NAME", "maintenance_html")
CUSTOM_BODY_HTML: str = os.environ.get("CUSTOM_BODY_HTML", "")


# if SCOPE not in ("REGIONAL", "CLOUDFRONT"):
#     msg = f"Unsupported SCOPE '{SCOPE}'. Must be 'REGIONAL' or 'CLOUDFRONT'."
#     logger.error(msg)
#     raise ValueError(msg)

# Set region (CloudFront uses us-east-1)
# if SCOPE == "CLOUDFRONT":
#     region = "us-east-1"
# else:
#     region = os.environ.get("AWS_REGION")
#     if not region:
#         msg = "AWS_REGION environment variable is required for REGIONAL scope."
#         logger.error(msg)
#         raise ValueError(msg)

waf = boto3.client("wafv2", region_name=region)

WafMode = Literal["BLOCK", "ALLOW"]


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def _desired_action(mode: WafMode) -> RuleActionOutputTypeDef:
    """Return WAF Action structure for direct rules."""
    if mode == "BLOCK":
        if CUSTOM_BODY_HTML.strip():
            return cast(
                RuleActionOutputTypeDef,
                {
                    "Block": {
                        "CustomResponse": {
                            "ResponseCode": 503,
                            "CustomResponseBodyKey": CUSTOM_BODY_NAME,
                        }
                    }
                }
            )
        return cast(RuleActionOutputTypeDef, {"Block": {}})
    if mode == "ALLOW":
        return cast(RuleActionOutputTypeDef, {"Allow": {}})

    # Should not be reachable if we validate mode correctly
    raise ValueError(f"Unsupported mode: {mode}")


def _parse_mode(event: Any) -> WafMode:
    """
    Extract and validate requested mode from the event.
    Defaults to 'BLOCK' if not present or invalid.
    """
    if not isinstance(event, dict):
        logger.warning(
            "Event is not a dict (type=%s). Using default mode 'BLOCK'.",
            type(event),
        )
        return "BLOCK"

    raw_mode = event.get("mode", "BLOCK")
    if not isinstance(raw_mode, str):
        logger.warning(
            "Event 'mode' is not a string (%r). Using default mode 'BLOCK'.",
            raw_mode,
        )
        return "BLOCK"

    mode_upper = raw_mode.upper()
    if mode_upper not in ("BLOCK", "ALLOW"):
        logger.warning(
            "Invalid mode '%s' in event; expected 'BLOCK' or 'ALLOW'. "
            "Falling back to 'BLOCK'.",
            mode_upper,
        )
        return "BLOCK"

    return mode_upper  # type: ignore[return-value]


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
        # SCOPE,
    )

    # Get current Web ACL
    try:
        # resp = waf.get_web_acl(Name=WEB_ACL_NAME, Scope=SCOPE, Id=WEB_ACL_ID)
        resp = waf.get_web_acl(Name=WEB_ACL_NAME, Id=WEB_ACL_ID)
    except (ClientError, BotoCoreError) as e:
        logger.exception(
            "Failed to get WebACL '%s' (ID=%s, scope=%s): %s",
            WEB_ACL_NAME,
            WEB_ACL_ID,
            # SCOPE,
            e,
        )
        return {
            "ok": False,
            "updated": False,
            "mode": mode,
            "error": "Failed to get WebACL",
            "details": str(e),
        }

    lock_token = resp.get("LockToken")
    web_acl = resp.get("WebACL")

    if not lock_token or not web_acl:
        msg = "get_web_acl response missing LockToken or WebACL."
        logger.error(msg)
        return {
            "ok": False,
            "updated": False,
            "mode": mode,
            "error": msg,
        }

    rules = web_acl.get("Rules", [])
    if not isinstance(rules, list):
        msg = "WebACL Rules is not a list in the response."
        logger.error(msg)
        return {
            "ok": False,
            "updated": False,
            "mode": mode,
            "error": msg,
        }

    custom_response_bodies = web_acl.get("CustomResponseBodies") or {}
    if not isinstance(custom_response_bodies, dict):
        logger.warning(
            "CustomResponseBodies was not a dict; resetting to empty dict."
        )
        custom_response_bodies = {}

    found = False
    changed = False
    new_rules = []

    for r in rules:
        if not isinstance(r, dict) or "Name" not in r:
            logger.warning("Encountered malformed rule entry: %r", r)
            new_rules.append(r)
            continue

        if r["Name"] == RULE_NAME:
            found = True
            rr = copy.deepcopy(r)

            if "Action" not in r:
                msg = (
                    f"Rule '{RULE_NAME}' does not have 'Action'. "
                    "This Lambda only supports direct rules with Action (Allow/Block)."
                )
                logger.error(msg)
                return {
                    "ok": False,
                    "updated": False,
                    "mode": mode,
                    "error": msg,
                }

            current_action = r.get("Action", {})

            try:
                desired_action = _desired_action(mode)
            except ValueError as e:
                logger.error("Invalid mode passed to _desired_action: %s", e)
                return {
                    "ok": False,
                    "updated": False,
                    "mode": mode,
                    "error": str(e),
                }

            if current_action != desired_action:
                rr["Action"] = desired_action 
                changed = True
                logger.info("Updating Action for rule '%s' to: %s", RULE_NAME, desired_action)

                # When BLOCK: ensure the custom response body is present
                if mode == "BLOCK" and CUSTOM_BODY_HTML.strip():
                    custom_response_bodies[CUSTOM_BODY_NAME] = {
                        "Content": CUSTOM_BODY_HTML,
                        "ContentType": "TEXT_HTML",
                    }
                    logger.info(
                        "Registered/updated custom response body '%s' on WebACL '%s'.",
                        CUSTOM_BODY_NAME,
                        WEB_ACL_NAME,
                    )

                # When ALLOW: remove custom body to avoid Terraform drift
                elif mode == "ALLOW":
                    if CUSTOM_BODY_NAME in custom_response_bodies:
                        logger.info(
                            "Removing custom response body '%s' from WebACL '%s'.",
                            CUSTOM_BODY_NAME,
                            WEB_ACL_NAME,
                        )
                        del custom_response_bodies[CUSTOM_BODY_NAME]
                    else:
                        logger.info(
                            "No custom response body '%s' present to remove.",
                            CUSTOM_BODY_NAME,
                        )

            else:
                logger.info("Action already set for rule '%s' — no change needed.", RULE_NAME)

            new_rules.append(rr)
        else:
            new_rules.append(r)

    if not found:
        msg = f"Rule '{RULE_NAME}' not found in WebACL '{WEB_ACL_NAME}'."
        logger.error(msg)
        return {
            "ok": False,
            "updated": False,
            "mode": mode,
            "error": msg,
        }

    if not changed:
        logger.info("No changes needed for WebACL '%s'.", WEB_ACL_NAME)
        return {"ok": True, "updated": False, "mode": mode}

    # Build update body
    updated_web_acl: Dict[str, Any] = {
        "Name": WEB_ACL_NAME,
        # "Scope": SCOPE,
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
        logger.info(
            "CustomResponseBodies now empty — omitting field to satisfy WAF API requirements."
        )

    logger.info(
        "Updating WebACL '%s' (ID=%s, scope=%s) to mode: %s",
        WEB_ACL_NAME,
        WEB_ACL_ID,
        # SCOPE,
        mode,
    )

    try:
        waf.update_web_acl(**updated_web_acl)
        logger.info("WebACL '%s' updated successfully.", WEB_ACL_NAME)
        return {"ok": True, "updated": True, "mode": mode}
    except (ClientError, BotoCoreError) as e:
        logger.exception("Failed to update WebACL '%s': %s", WEB_ACL_NAME, e)
        return {
            "ok": False,
            "updated": False,
            "mode": mode,
            "error": "Failed to update WebACL",
            "details": str(e),
        }
