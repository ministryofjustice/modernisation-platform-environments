import json
import os

import boto3

ssm = boto3.client("ssm")
ENV = os.environ.get("ENVIRONMENT")

def lambda_handler(event, context):
    print("Event received:", json.dumps(event))

    try:
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

                # only restart services for ENV
                print(f"Only starting services: for {ENV}")

                # Filter only services belonging to the current environment
                if ENV.lower() not in cluster_name.lower():
                    print(f"Skipping service {service_name} in cluster {cluster_name} (not {ENV})")
                    continue

                print(f"Restarting service {service_name} in cluster {cluster_name} for ENV={ENV}")

                # Force a new deployment for the specified service in the specified cluster
                response = ecs_client.update_service(
                    cluster=cluster_name,
                    service=service_name,
                    forceNewDeployment=True,
                )
                # if os.environ.get("DEBUG_LOGGING", False):
                #     print("[DEBUG] Update service response:", response)
            else:
                print("No entity value found in the event")

        return {
            "statusCode": 200,
            "body": json.dumps("Handled ECS Task Patching Retirement"),
            "restarted_services": affected_entities,
        }

    except Exception as e:
        print("Error updating service:", e)
        return {"statusCode": 500, "body": json.dumps("Error updating service")}


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
        raise Exception("TargetsNotReady")