import json
import os

import boto3

ssm = boto3.client("ssm")
ENV = os.environ.get("ENVIRONMENT")
# Use env to determine
# - SSM circuit breaker path
# - ECS cluster/service
# - Logging
ssm_path = f"/{ENV}/ldap/circuit_breaker/state"

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
                if os.environ.get("DEBUG_LOGGING", False):
                    print("[DEBUG] Update service response:", response)
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


def open_circuit_breaker(param_name):
    print(f"Opening circuit breaker {param_name}")
    ssm.put_parameter(Name=param_name, Value="OPEN", Overwrite=True)


def close_circuit_breaker(param_name):
    print(f"Closing circuit breaker {param_name}")
    ssm.put_parameter(Name=param_name, Value="CLOSED", Overwrite=True)


def force_ecs_restart(cluster, service):
    print(f"Forcing new deployment for {service}")
    ecs.update_service(cluster=cluster, service=service, forceNewDeployment=True)