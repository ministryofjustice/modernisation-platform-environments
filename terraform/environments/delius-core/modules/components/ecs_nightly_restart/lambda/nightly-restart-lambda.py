import os
import boto3

ecs = boto3.client("ecs")
cloudwatch = boto3.client("cloudwatch")


def get_alarm_names():
    return [
        name.strip()
        for name in os.environ.get("ALARM_NAMES", "").split(",")
        if name.strip()
    ]


def disable_alarms():
    names = get_alarm_names()
    if names:
        cloudwatch.disable_alarm_actions(AlarmNames=names)

    return {"disabled": True}


def enable_alarms():
    names = get_alarm_names()
    if names:
        cloudwatch.enable_alarm_actions(AlarmNames=names)

    return {"enabled": True}


def start_deployment():
    ecs.update_service(
        cluster=os.environ["CLUSTER"],
        service=os.environ["SERVICE"],
        desiredCount=int(os.environ["DESIRED_COUNT"]),
        forceNewDeployment=True,
    )

    return {"started": True}


def check_stability(event):
    response = ecs.describe_services(
        cluster=os.environ["CLUSTER"],
        services=[os.environ["SERVICE"]],
    )

    if response.get("failures"):
        raise RuntimeError(
            f"ECS service lookup failed: {response['failures']}"
        )

    services = response.get("services", [])
    if not services:
        raise RuntimeError("ECS service was not found")

    service = services[0]

    stable = (
        len(service.get("deployments", [])) == 1
        and service.get("runningCount", 0)
            == service.get("desiredCount", 0)
        and service.get("pendingCount", 0) == 0
    )

    return {
        "stable": stable,
        "attempt": int(event.get("attempt", 0)),
    }


def handler(event, context):
    action = event.get("action")

    if action == "disable_alarms":
        return disable_alarms()

    if action == "enable_alarms":
        return enable_alarms()

    if action == "start_deployment":
        return start_deployment()

    if action == "check_stability":
        return check_stability(event)

    raise ValueError(f"Unknown action: {action}")