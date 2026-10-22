
import os
import boto3

ecs = boto3.client("ecs")
cloudwatch = boto3.client("cloudwatch")


def get_alarm_names():
    tag_key = "app"
    tag_value = os.environ["APP_NAME"]

    paginator = cloudwatch.get_paginator("describe_alarms")
    alarm_names = []

    for page in paginator.paginate():
        alarms = (
            page.get("MetricAlarms", [])
            + page.get("CompositeAlarms", [])
        )

        for alarm in alarms:
            alarm_arn = alarm["AlarmArn"]
            response = cloudwatch.list_tags_for_resource(
                ResourceARN=alarm_arn
            )

            tags = {
                tag["Key"]: tag["Value"]
                for tag in response.get("Tags", [])
            }

            if tags.get(tag_key) == tag_value:
                alarm_names.append(alarm["AlarmName"])

    return alarm_names


def disable_alarms():
    names = get_alarm_names()
    print(f"Found {len(names)} alarms to mute: {names}", flush=True)

    if names:
        print("Disabling alarm actions...", flush=True)
        cloudwatch.disable_alarm_actions(AlarmNames=names)
        print("Alarm actions disabled successfully.", flush=True)

    return {
        "disabled": True,
        "count": len(names),
        "alarms": names,
    }


def enable_alarms():
    names = get_alarm_names()
    print(f"Found {len(names)} alarms to unmute: {names}", flush=True)

    if names:
        print("Enabling alarm actions...", flush=True)
        cloudwatch.enable_alarm_actions(AlarmNames=names)
        print("Alarm actions enabled successfully.", flush=True)
    else:
        print("No matching alarms found.", flush=True)

    return {
        "enabled": True,
        "count": len(names),
        "alarms": names,
    }


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
