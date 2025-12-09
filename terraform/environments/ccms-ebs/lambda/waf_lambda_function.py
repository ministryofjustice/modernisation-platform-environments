# import os
# import json
# import boto3
# import copy
# from botocore.exceptions import ClientError

# # Get environment variables
# SCOPE = os.environ.get("SCOPE", "REGIONAL")
# # WEB_ACL_NAME = os.environ["WEB_ACL_NAME"]
# WEB_ACL_ID = os.environ["WEB_ACL_ID"]
# RULE_NAME = os.environ["RULE_NAME"]
# CUSTOM_BODY_NAME = os.environ.get("CUSTOM_BODY_NAME", "maintenance_html")
# CUSTOM_BODY_HTML = os.environ.get("CUSTOM_BODY_HTML", "")

# RESOURCE_ARN = os.environ["RESOURCE_ARN"]

# # Set region (CloudFront uses us-east-1)
# region = "us-east-1" if SCOPE.upper() == "CLOUDFRONT" else os.environ.get("AWS_REGION")
# waf = boto3.client("wafv2", region_name=region)

# def _desired_action(mode: str):
#     """Return WAF Action structure for direct rules."""
#     mode = mode.upper()
#     if mode == "BLOCK":
#         # If we have custom body, use CustomResponse
#         if CUSTOM_BODY_HTML.strip():
#             return {
#                 "Block": {
#                     "CustomResponse": {
#                         "ResponseCode": 503,
#                         "CustomResponseBodyKey": CUSTOM_BODY_NAME
#                     }
#                 }
#             }
#         else:
#             return {"Block": {}}
#     elif mode == "ALLOW":
#         return {"Allow": {}}
#     else:
#         raise ValueError(f"Unsupported mode: {mode}")

# def lambda_handler(event, context):
#     mode = (event or {}).get("mode", "BLOCK").upper()
#     print(f"➡️ Requested mode for rule '{RULE_NAME}' in WebACL '{WEB_ACL_NAME}': {mode}")

#     try:
#         # Get current Web ACL
#         resp = waf.get_web_acl(Name=WEB_ACL_NAME, Scope=SCOPE, Id=WEB_ACL_ID)
#     except ClientError as e:
#         print(f"Failed to get WebACL: {e}")
#         raise

#     lock_token = resp["LockToken"]
#     web_acl = resp["WebACL"]
#     rules = web_acl.get("Rules", [])
#     custom_response_bodies = web_acl.get("CustomResponseBodies", {}).copy()  # Preserve existing

#     found = changed = False
#     new_rules = []

#     for r in rules:
#         if r["Name"] == RULE_NAME:
#             found = True
#             rr = copy.deepcopy(r)  # Deep copy to avoid mutation

#             if "Action" not in r:
#                 raise RuntimeError(
#                     f"Rule '{RULE_NAME}' does not have 'Action'. "
#                     "This Lambda only supports direct rules with Action (Allow/Block)."
#                 )

#             desired_action = _desired_action(mode)
#             current_action = r.get("Action", {})

#             if current_action != desired_action:
#                 rr["Action"] = desired_action
#                 changed = True
#                 print(f"Updating Action to: {desired_action}")

#                 # If switching to BLOCK with custom response, ensure body is registered
#                 if mode == "BLOCK" and CUSTOM_BODY_HTML.strip():
#                     custom_response_bodies[CUSTOM_BODY_NAME] = {
#                         "Content": CUSTOM_BODY_HTML,
#                         "ContentType": "TEXT_HTML"
#                     }
#                     print(f"Registered custom response body: {CUSTOM_BODY_NAME}")
#             else:
#                 print("Action already set — no change needed.")

#             new_rules.append(rr)

#         else:
#             # Keep other rules unchanged
#             new_rules.append(r)

#     if not found:
#         raise RuntimeError(f" Rule '{RULE_NAME}' not found in WebACL '{WEB_ACL_NAME}'")

#     if not changed:
#         print("No changes needed.")
#         return {"ok": True, "updated": False, "mode": mode}

#     # Update Web ACL
#     updated_web_acl = {
#         "Name": WEB_ACL_NAME,
#         "Scope": SCOPE,
#         "Id": WEB_ACL_ID,
#         "LockToken": lock_token,
#         "DefaultAction": web_acl["DefaultAction"],
#         "Description": web_acl.get("Description", ""),
#         "VisibilityConfig": web_acl["VisibilityConfig"],
#         "Rules": new_rules,
#         "CustomResponseBodies": custom_response_bodies  # Critical: preserve or update custom bodies
#     }
#     # print(f"Attempting to update WebACL: {updated_web_acl}...")
#     print(f"Updating WebACL '{WEB_ACL_NAME}' (ID: {WEB_ACL_ID}) in scope {SCOPE} to mode: {mode}")
#     try:
#         update_resp = waf.update_web_acl(**updated_web_acl)
#         print("WebACL updated successfully.")
#         return {"ok": True, "updated": True, "mode": mode, "lockToken": lock_token}

#     except ClientError as e:
#         print(f"Failed to update WebACL: {e}")
#         raise
####################################
import os
import json
import boto3
from botocore.exceptions import ClientError

# Environment variables
SCOPE = os.environ.get("SCOPE", "REGIONAL").upper()

RESOURCE_ARN = os.environ["RESOURCE_ARN"]               # ALB ARN
NORMAL_WEB_ACL_ARN = os.environ["NORMAL_WEB_ACL_ARN"]   # Normal ACL ARN
MAINTENANCE_WEB_ACL_ARN = os.environ["MAINTENANCE_WEB_ACL_ARN"]  # Maintenance ACL ARN

region = os.environ.get("AWS_REGION")
waf = boto3.client("wafv2", region_name=region)


def get_current_web_acl_arn() -> str | None:
    """Return the ARN of the ACL currently associated with the resource, or None."""
    try:
        resp = waf.get_web_acl_for_resource(
            ResourceArn=RESOURCE_ARN,
        )
        web_acl = resp.get("WebACL")
        return web_acl.get("ARN") if web_acl else None
    except ClientError as e:
        # If there is no ACL associated, WAF may raise an error in some cases.
        print(f"get_web_acl_for_resource error (can be benign if none associated): {e}")
        return None


def associate_web_acl(web_acl_arn: str):
    """Associate the given WebACL with the resource."""
    print(f"Associating WebACL '{web_acl_arn}' with resource '{RESOURCE_ARN}'")
    waf.associate_web_acl(
        Scope=SCOPE,
        WebACLArn=web_acl_arn,
        ResourceArn=RESOURCE_ARN,
    )


def disassociate_web_acl():
    """Disassociate any WebACL from the resource."""
    print(f"Disassociating any WebACL from resource '{RESOURCE_ARN}'")
    waf.disassociate_web_acl(
        Scope=SCOPE,
        ResourceArn=RESOURCE_ARN,
    )


def lambda_handler(event, context):
    """
    Expected event format:

      { "mode": "BLOCK" }   -> maintenance mode (maintenance ACL)
      { "mode": "ALLOW" }   -> normal mode      (normal ACL)

    If 'mode' is missing, default is "BLOCK" (maintenance).
    """
    mode = (event or {}).get("mode", "BLOCK").upper()
    print(f"➡️ Requested mode for resource '{RESOURCE_ARN}': {mode}")

    if mode == "BLOCK":
        target_acl_arn = MAINTENANCE_WEB_ACL_ARN
        logical_mode = "MAINTENANCE"
    elif mode == "ALLOW":
        target_acl_arn = NORMAL_WEB_ACL_ARN
        logical_mode = "NORMAL"
    else:
        raise ValueError(f"Unsupported mode: {mode} (expected 'BLOCK' or 'ALLOW')")

    current_acl_arn = get_current_web_acl_arn()
    print(f"Current associated WebACL ARN: {current_acl_arn}")

    if current_acl_arn == target_acl_arn:
        print("Already in desired mode; no change needed.")
        return {
            "ok": True,
            "updated": False,
            "mode": logical_mode,
            "currentAclArn": current_acl_arn,
        }

    try:
        associate_web_acl(target_acl_arn)
        print(f"Switched to {logical_mode} mode using WebACL: {target_acl_arn}")
        return {
            "ok": True,
            "updated": True,
            "mode": logical_mode,
            "newAclArn": target_acl_arn,
        }
    except ClientError as e:
        print(f"Failed to associate WebACL: {e}")
        raise
