import json
import os

import boto3


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
            if entity_value is not None:
                # Extract cluster name and service name from the entity value
                cluster_name = entity_value.split("|")[0]
                service_name = entity_value.split("|")[1]
                print("Cluster name:", cluster_name)
                print("Service name:", service_name)

                print("Forcing new deployment for service:", service_name)

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
