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

        # Extract the affected entity being iterated from the Map
        entity_value = event.get("entityValue")

        if not entity_value:
            print("No entity value found in the event.")
            return
            
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
                return

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
            "restarted_service": entity_value,
        }

    except Exception as e:
        print("Error updating service:", e)
        return {"statusCode": 500, "body": json.dumps("Error updating service")}
