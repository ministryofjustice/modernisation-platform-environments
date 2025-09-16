# file: lambda_function.py
import os
import json
import boto3
from botocore.exceptions import ClientError

SCOPE        = os.environ.get("SCOPE", "REGIONAL")
WEB_ACL_NAME = os.environ["WEB_ACL_NAME"]
WEB_ACL_ID   = os.environ["WEB_ACL_ID"]
RULE_NAME    = os.environ["RULE_NAME"]

region = "us-east-1" if SCOPE.upper() == "CLOUDFRONT" else os.environ.get("AWS_REGION")
waf = boto3.client("wafv2", region_name=region)

def _desired_action(mode: str):
    mode = mode.upper()
    if mode == "BLOCK":
        return {"Block": {}}
    elif mode == "ALLOW":
        return {"Allow": {}}
    else:
        raise ValueError(f"Unsupported mode: {mode}")

def lambda_handler(event, context):
    mode = (event or {}).get("mode", "BLOCK").upper()
    print(f"Requested mode for rule '{RULE_NAME}' in WebACL '{WEB_ACL_NAME}': {mode}")

    resp = waf.get_web_acl(Name=WEB_ACL_NAME, Scope=SCOPE, Id=WEB_ACL_ID)
    lock_token = resp["LockToken"]
    web_acl    = resp["WebACL"]
    rules      = web_acl.get("Rules", [])

    desired = _desired_action(mode)
    found = changed = False
    new_rules = []

    for r in rules:
        if r["Name"] == RULE_NAME:
            found = True
            if "Action" not in r:
                raise RuntimeError(
                    f"Rule '{RULE_NAME}' does not have 'Action'. "
                    "It may be a managed rule group (needs OverrideAction)."
                )
            current = r.get("Action", {})
            if current != desired:
                rr = r.copy()
                rr["Action"] = desired
                new_rules.append(rr)
                changed = True
            else:
                new_rules.append(r)
        else:
            new_rules.append(r)

    if not found:
        raise RuntimeError(f"Rule '{RULE_NAME}' not found in WebACL '{WEB_ACL_NAME}'")

    if not changed:
        return {"ok": True, "updated": False, "mode": mode}

    waf.update_web_acl(
        Name=WEB_ACL_NAME,
        Scope=SCOPE,
        Id=WEB_ACL_ID,
        LockToken=lock_token,
        DefaultAction=web_acl["DefaultAction"],
        Description=web_acl.get("Description", ""),
        VisibilityConfig=web_acl["VisibilityConfig"],
        Rules=new_rules
    )
    return {"ok": True, "updated": True, "mode": mode}