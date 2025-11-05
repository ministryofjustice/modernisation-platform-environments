# ldap_circuit_handler
import boto3
import time
import json
import os
import logging

ecs = boto3.client('ecs')
ssm = boto3.client("ssm")
elbv2 = boto3.client('elbv2', region_name="eu-west-2")
ENV = os.environ.get("ENVIRONMENT")

# Use env to determine
# - SSM circuit breaker path
# - ECS cluster/service
ssm_path = f"/{ENV}/ldap/circuit_breaker"

logger = logging.getLogger()
logger.setLevel(logging.INFO)


def lambda_handler(event, context):
    print("Event received:", json.dumps(event))
    action = event.get("action")
    print(f"Action received as {action}")
    # Create an ECS client using boto3
    ecs_client = boto3.client("ecs")

    # Extract the affected entities from the event
    affected_entities = event["detail"]["affectedEntities"]

    # Iterate over each affected entity
    for entity in affected_entities:
        # Get the entity value
        entity_value = entity.get("entityValue")

        if not entity_value:
            logger.info("No entity value found in the event.")
            continue

        if entity_value is not None:
            # Extract cluster name and service name from the entity value
            cluster_name = entity_value.split("|")[0]
            service_name = entity_value.split("|")[1]
            logger.info("Cluster name:", cluster_name)
            logger.info("Service name:", service_name)

            # Filter ldap service belonging to the current environment only
            if ENV.lower() not in cluster_name.lower():
                logger.info(f"Skipping service {service_name} in cluster {cluster_name} (not {ENV})")
                continue

            # only do this for ldap and for ENV!
            logger.info(f"Only starting LDAP services: for {ENV}")
            if "ldap".lower() not in service_name.lower():
                logger.info(f"Service {service_name} not LDAP, so skipping it!")
                continue

            target_group_arn = os.environ.get("LDAP_NLB_ARN", None)

            logger.info(f"Action={action}, Service={service_name}, Cluster={cluster_name}")

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
    logger.info(f"Opening circuit breaker {ssm_path} for {service} in {cluster_name}")
    ssm.put_parameter(Name=ssm_path, Value="OPEN", Overwrite=True)
    return {"status": "opened"}


def close_circuit_breaker(ssm_path, service, cluster_name):
    # close circuit and re-enable NLB registration
    logger.info(f"Closing circuit breaker {ssm_path} for {service} in {cluster_name}")
    ssm.put_parameter(Name=ssm_path, Value="CLOSED", Overwrite=True)
    return {"status": "closed"}


def check_target_health(target_group_arn, service_name, cluster_name):
    logger.info(f"Checking Target health for {service_name} in {cluster_name}")
    targets = elbv2.describe_target_health(TargetGroupArn=target_group_arn)
    states = [t["TargetHealth"]["State"] for t in targets["TargetHealthDescriptions"]]
    logger.info(f"Target states: {states}")
    if all(s == "healthy" for s in states):
        return {"status": "healthy"}
    else:
        raise Exception("TargetsNotReady")