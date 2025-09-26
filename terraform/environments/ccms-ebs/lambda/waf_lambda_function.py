import os
import json
import boto3
import copy
from botocore.exceptions import ClientError

# Get environment variables
SCOPE = os.environ.get("SCOPE", "REGIONAL")
WEB_ACL_NAME = os.environ["WEB_ACL_NAME"]
WEB_ACL_ID = os.environ["WEB_ACL_ID"]
RULE_NAME = os.environ["RULE_NAME"]
CUSTOM_BODY_NAME = os.environ.get("CUSTOM_BODY_NAME", "maintenance_html")
CUSTOM_BODY_HTML = os.environ.get("CUSTOM_BODY_HTML", "")

# Set region (CloudFront uses us-east-1)
region = "us-east-1" if SCOPE.upper() == "CLOUDFRONT" else os.environ.get("AWS_REGION")
waf = boto3.client("wafv2", region_name=region)

def _desired_action(mode: str):
    """Return WAF Action structure for direct rules."""
    mode = mode.upper()
    if mode == "BLOCK":
        # If we have custom body, use CustomResponse
        if CUSTOM_BODY_HTML.strip():
            return {
                "Block": {
                    "CustomResponse": {
                        "ResponseCode": 503,
                        "CustomResponseBodyKey": CUSTOM_BODY_NAME
                    }
                }
            }
        else:
            return {"Block": {}}
    elif mode == "ALLOW":
        return {"Allow": {}}
    else:
        raise ValueError(f"Unsupported mode: {mode}")

def lambda_handler(event, context):
    mode = (event or {}).get("mode", "BLOCK").upper()
    print(f"➡️ Requested mode for rule '{RULE_NAME}' in WebACL '{WEB_ACL_NAME}': {mode}")

    try:
        # Get current Web ACL
        resp = waf.get_web_acl(Name=WEB_ACL_NAME, Scope=SCOPE, Id=WEB_ACL_ID)
    except ClientError as e:
        print(f"Failed to get WebACL: {e}")
        raise

    lock_token = resp["LockToken"]
    web_acl = resp["WebACL"]
    rules = web_acl.get("Rules", [])
    custom_response_bodies = web_acl.get("CustomResponseBodies", {}).copy()  # Preserve existing

    found = changed = False
    new_rules = []

    for r in rules:
        if r["Name"] == RULE_NAME:
            found = True
            rr = copy.deepcopy(r)  # Deep copy to avoid mutation

            if "Action" not in r:
                raise RuntimeError(
                    f"Rule '{RULE_NAME}' does not have 'Action'. "
                    "This Lambda only supports direct rules with Action (Allow/Block)."
                )

            desired_action = _desired_action(mode)
            current_action = r.get("Action", {})

            if current_action != desired_action:
                rr["Action"] = desired_action
                changed = True
                print(f"Updating Action to: {desired_action}")

                # If switching to BLOCK with custom response, ensure body is registered
                if mode == "BLOCK" and CUSTOM_BODY_HTML.strip():
                    custom_response_bodies[CUSTOM_BODY_NAME] = {
                        "Content": CUSTOM_BODY_HTML,
                        "ContentType": "TEXT_HTML"
                    }
                    print(f"Registered custom response body: {CUSTOM_BODY_NAME}")
            else:
                print("Action already set — no change needed.")

            new_rules.append(rr)

        else:
            # Keep other rules unchanged
            new_rules.append(r)

    if not found:
        raise RuntimeError(f" Rule '{RULE_NAME}' not found in WebACL '{WEB_ACL_NAME}'")

    if not changed:
        print("No changes needed.")
        return {"ok": True, "updated": False, "mode": mode}

    # Update Web ACL
    updated_web_acl = {
        "Name": WEB_ACL_NAME,
        "Scope": SCOPE,
        "Id": WEB_ACL_ID,
        "LockToken": lock_token,
        "DefaultAction": web_acl["DefaultAction"],
        "Description": web_acl.get("Description", ""),
        "VisibilityConfig": web_acl["VisibilityConfig"],
        "Rules": new_rules,
        "CustomResponseBodies": custom_response_bodies  # Critical: preserve or update custom bodies
    }
    # print(f"Attempting to update WebACL: {updated_web_acl}...")
    print(f"Updating WebACL '{WEB_ACL_NAME}' (ID: {WEB_ACL_ID}) in scope {SCOPE} to mode: {mode}")
    try:
        update_resp = waf.update_web_acl(**updated_web_acl)
        print("WebACL updated successfully.")
        return {"ok": True, "updated": True, "mode": mode, "lockToken": lock_token}

    except ClientError as e:
        print(f"Failed to update WebACL: {e}")
        raise