import json
import os
import time

import boto3

ssm = boto3.client("ssm")
elbv2 = boto3.client("elbv2", region_name="eu-west-2")
ENV = os.environ.get("ENVIRONMENT")

# Use env to determine
# - SSM circuit breaker path
# - ECS cluster/service
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

                # LDAP specific
                if "ldap" in service_name.lower():
                    print("LDAP service detected. Initiating circuit breaker...")
        
                    param_name = f"/{ENV}/ldap/circuit-breaker"
                    target_group_arn = os.environ.get("LDAP_NLB_ARN", None)

                    # open circuit breaker
                    open_circuit_breaker(param_name=param_name)
                    print(f"Circuit breaker opened for {service_name}")

                    # wait for NLB deregistration to complete
                    wait_for_deregistration(target_group_arn)

                    # restart LDAP ECS service
                    print(f"Restart triggered for {service_name}")
                    ecs_client.update_service(
                        cluster=cluster_name,
                        service=service_name,
                        forceNewDeployment=True
                    )

                    # running cache warm up queries

                    # now wait for service and its registration again
                    wait_for_registration(target_group_arn)

                    # finally close circuit breaker
                    close_circuit_breaker(param_name=param_name)
                    print(f"Circuit breaker closed for {service_name}")

                else:
                    # Non-LDAP services – restart immediately
                    print(f"{service_name} is not LDAP. Skipping circuit breaker.")
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


def wait_for_deregistration(target_group_arn):
    """Wait until all targets in the TG are in 'unused' or 'draining' state."""
    if target_group_arn is None:
        print("Empty target group passed.")
        return
    
    print("Waiting for LDAP targets to deregister from NLB...")
    while True:
        resp = elbv2.describe_target_health(TargetGroupArn=target_group_arn)
        active = [
            t for t in resp["TargetHealthDescriptions"]
            if t["TargetHealth"]["State"] not in ("draining", "unused")
        ]
        if not active:
            print("All LDAP targets deregistered from NLB.")
            break
        print("Still draining... waiting 20 seconds")
        time.sleep(20)


def wait_for_registration(target_group_arn):
    while True:
        resp = elbv2.describe_target_health(TargetGroupArn=target_group_arn)
        healthy = [t for t in resp["TargetHealthDescriptions"]
                   if t["TargetHealth"]["State"] == "healthy"]
        if healthy:
            print("LDAP target healthy again.")
            break
        print("Waiting for target to become healthy...")
        time.sleep(20)


def open_circuit_breaker(param_name):
    print(f"Opening circuit breaker {param_name}")
    ssm.put_parameter(Name=param_name, Value="OPEN", Overwrite=True)


def close_circuit_breaker(param_name):
    print(f"Closing circuit breaker {param_name}")
    ssm.put_parameter(Name=param_name, Value="CLOSED", Overwrite=True)