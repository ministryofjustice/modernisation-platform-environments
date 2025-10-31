# ldap_circuit_handler
import boto3
import time
import json
import os
import logging

ecs = boto3.client('ecs')
elbv2 = boto3.client('elbv2', region_name="eu-west-2")
ENV = os.environ.get("ENVIRONMENT")

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
            print("No entity value found in the event.")
            continue
        
        if entity_value is not None:
            # Extract cluster name and service name from the entity value
            cluster_name = entity_value.split("|")[0]
            service_name = entity_value.split("|")[1]
            print("Cluster name:", cluster_name)
            print("Service name:", service_name)

            target_group_arn = os.environ.get("LDAP_NLB_ARN", None)

            logger.info(f"Action={action}, Service={service_name}, Cluster={cluster_name}")

            if action == "open":
                return open_circuit_breaker(cluster_name, service_name)

            elif action == "close":
                return close_circuit_breaker(cluster_name, service_name)

            elif action == "check_health":
                return check_target_health(target_group_arn)

            else:
                raise ValueError(f"Unknown action: {action}")


def open_circuit_breaker(cluster, service):
    # disable NLB registration
    logger.info(f"Opening circuit breaker for {service}")
    ecs.update_service(cluster=cluster, service=service, desiredCount=0)
    return {"status": "opened"}


def close_circuit_breaker(cluster, service):
    # re-enable NLB registration
    logger.info(f"Closing circuit breaker for {service}")
    ecs.update_service(cluster=cluster, service=service, desiredCount=1)
    return {"status": "closed"}


def check_target_health(target_group_arn):
    targets = elbv2.describe_target_health(TargetGroupArn=target_group_arn)
    states = [t["TargetHealth"]["State"] for t in targets["TargetHealthDescriptions"]]
    logger.info(f"Target states: {states}")
    if all(s == "healthy" for s in states):
        return {"status": "healthy"}
    else:
        raise Exception("TargetsNotReady")
