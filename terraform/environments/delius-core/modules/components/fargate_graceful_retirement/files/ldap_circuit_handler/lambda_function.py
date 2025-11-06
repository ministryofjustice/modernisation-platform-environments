# ldap_circuit_handler
import boto3
import time
import json
import os

ecs = boto3.client('ecs')
ssm = boto3.client("ssm")
elbv2 = boto3.client('elbv2', region_name="eu-west-2")
ENV = os.environ.get("ENVIRONMENT")

# Use env to determine
# - SSM circuit breaker path
# - ECS cluster/service
ssm_path = f"/{ENV}/ldap/circuit-breaker"


def lambda_handler(event, context):
    print("Event received:", json.dumps(event))
    action = event.get("action")
    print(f"Action received as {action}")
    
    # Extract the affected entities from the event
    entity_value = event.get("entityValue")

    if not entity_value:
        print("No entity value found in the event.")
        return

    if entity_value is not None:
        # Extract cluster name and service name from the entity value
        cluster_name = entity_value.split("|")[0]
        service_name = entity_value.split("|")[1]
        print(f"Cluster name: {cluster_name}")
        print(f"Service name: {service_name}")

        # This should ideally execute only for ldap services
        # Filter ldap service belonging to the current environment only
        if ENV.lower() not in cluster_name.lower():
            print(f"Skipping cluster {cluster_name} (not {ENV})")
            return

        # only do this for ldap and for ENV!
        print(f"Only starting LDAP services: for {ENV}")
        if "ldap".lower() not in service_name.lower():
            print(f"Service {service_name} not LDAP, so skipping it!")
            return

        target_group_arn = os.environ.get("LDAP_NLB_ARN", None)

        print(f"Action={action}, Service={service_name}, Cluster={cluster_name}")

        if action == "open":
            return open_circuit_breaker(ssm_path, service_name, cluster_name)

        elif action == "close":
            return close_circuit_breaker(ssm_path, service_name, cluster_name)

        elif action == "check_health":
            return check_target_health(target_group_arn, service_name, cluster_name)

        else:
            raise ValueError(f"Unknown action: {action}")


def open_circuit_breaker(ssm_path, service, cluster_name):
    # open circuit and disable NLB registration
    print(f"Opening circuit breaker {ssm_path} for {service} in {cluster_name}")
    ssm.put_parameter(Name=ssm_path, Value="OPEN", Overwrite=True)
    return {"status": "opened"}


def close_circuit_breaker(ssm_path, service, cluster_name):
    # close circuit and re-enable NLB registration
    print(f"Closing circuit breaker {ssm_path} for {service} in {cluster_name}")
    ssm.put_parameter(Name=ssm_path, Value="CLOSED", Overwrite=True)
    return {"status": "closed"}


def check_target_health(target_group_arn, service_name, cluster_name):
    print(f"Checking Target health for {service_name} in {cluster_name}")
    targets = elbv2.describe_target_health(TargetGroupArn=target_group_arn)
    states = [t["TargetHealth"]["State"] for t in targets["TargetHealthDescriptions"]]
    print(f"Target states: {states}")
    if all(s == "healthy" for s in states):
        return {"status": "healthy"}
    else:
        raise TargetsNotReady("Targets are not healthy yet.")


class TargetsNotReady(Exception):
    pass