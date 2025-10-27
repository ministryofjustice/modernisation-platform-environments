import json
import boto3
import os
import logging
from botocore.exceptions import ClientError

logger = logging.getLogger()
logger.setLevel(logging.INFO)

ecs = boto3.client("ecs")
elbv2 = boto3.client("elbv2")
ssm = boto3.client("ssm")

CLUSTER = os.environ["ECS_CLUSTER"]
SERVICE = os.environ["ECS_SERVICE"]
TARGET_GROUP_ARN = os.environ["TARGET_GROUP_ARN"]
TARGET_PORT = int(os.environ.get("TARGET_PORT", 389))
SSM_PARAM = os.environ.get("SSM_PARAM_NAME")

# valid parameter values for ENABLED/OPEN vs CLOSED
OPEN_VALUES = set(["open", "OPEN", "1", "true", "True", "YES", "yes"])
CLOSED_VALUES = set(["closed", "CLOSED", "0", "false", "False", "NO", "no"])


def get_ssm_flag(name):
    try:
        resp = ssm.get_parameter(Name=name, WithDecryption=False)
        val = resp["Parameter"]["Value"].strip()
        logger.info("SSM parameter %s = %s", name, val)
        return val
    except ClientError as e:
        logger.error("Error reading SSM parameter %s: %s", name, e)
        raise


def get_running_task_arns(cluster, service):
    resp = ecs.list_tasks(cluster=cluster, serviceName=service, desiredStatus="RUNNING")
    return resp.get("taskArns", [])


def describe_tasks(cluster, task_arns):
    if not task_arns:
        return []
    resp = ecs.describe_tasks(cluster=cluster, tasks=task_arns)
    return resp.get("tasks", [])


def extract_task_ips(tasks):
    ips = []
    for t in tasks:
        # Fargate network mode: containers[].networkInterfaces[].privateIpv4Address
        for cont in t.get("containers", []):
            for ni in cont.get("networkInterfaces", []):
                ip = ni.get("privateIpv4Address")
                if ip:
                    ips.append(ip)
        # fallback: attachments -> details
        for att in t.get("attachments", []):
            for d in att.get("details", []):
                if d.get("name") in ("privateIPv4Address", "privateIPv4Addresses"):
                    if d.get("value"):
                        ips.append(d.get("value"))
    return list(set(ips))


def deregister_ips_from_tg(ips, port):
    targets = [{"Id": ip, "Port": port} for ip in ips]
    if targets:
        logger.info("Deregistering targets: %s", targets)
        try:
            elbv2.deregister_targets(TargetGroupArn=TARGET_GROUP_ARN, Targets=targets)
        except ClientError as e:
            logger.exception("DeregisterTargets failed: %s", e)


def register_ips_to_tg(ips, port):
    targets = [{"Id": ip, "Port": port} for ip in ips]
    if targets:
        logger.info("Registering targets: %s", targets)
        try:
            elbv2.register_targets(TargetGroupArn=TARGET_GROUP_ARN, Targets=targets)
        except ClientError as e:
            logger.exception("RegisterTargets failed: %s", e)


def lambda_handler(event, context):
    logger.info("Lambda invoked. Event: %s", json.dumps(event))
    # Read desired state from SSM
    val = get_ssm_flag(SSM_PARAM)

    if val in OPEN_VALUES:
        desired = "OPEN"
    elif val in CLOSED_VALUES:
        desired = "CLOSED"
    else:
        # unknown: be conservative - keep circuit closed (allow traffic) but log a warning
        logger.warning("Unknown SSM value '%s'. Treating as CLOSED (allow traffic).", val)
        desired = "CLOSED"

    # find running task IP(s)
    task_arns = get_running_task_arns(CLUSTER, SERVICE)
    if not task_arns:
        logger.info("No running tasks found for cluster=%s service=%s", CLUSTER, SERVICE)
        return {"status": "no_tasks"}

    tasks = describe_tasks(CLUSTER, task_arns)
    ips = extract_task_ips(tasks)
    logger.info("Discovered IPs: %s", ips)

    if desired == "OPEN":
        # Cut traffic: remove from NLB target group
        deregister_ips_from_tg(ips, TARGET_PORT)
        return {"status": "circuit_open", "ips": ips}
    else:
        # Allow traffic: register back into NLB target group
        register_ips_to_tg(ips, TARGET_PORT)
        return {"status": "circuit_closed", "ips": ips}