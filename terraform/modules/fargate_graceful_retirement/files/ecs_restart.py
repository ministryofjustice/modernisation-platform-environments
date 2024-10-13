import json
import boto3

def lambda_handler(event, context):
    print("Event received:", json.dumps(event))

    try:
        ecs_client = boto3.client('ecs')

        affected_entities = event['detail']['affectedEntities']

        for entity in affected_entities:
            entity_value = entity.get('entityValue')
            if entity_value is not None:
                cluster_name = entity_value.split('|')[0]
                service_name = entity_value.split('|')[1]
                print("Cluster name:", cluster_name)
                print("Service name:", service_name)

                print("Forcing new deployment for service:", service_name) 
                
                response = ecs_client.update_service(
                    cluster=cluster_name,
                    service=service_name,
                    forceNewDeployment=True
                )

                print("Update service response:", json.dumps(response))
            else:
                print("No entity value found in the event")

        return {
            'statusCode': 200,
            'body': json.dumps('Handled ECS Task Patching Retirement')
        }

    except Exception as e:
        print("Error updating service:", e)
        return {
            'statusCode': 500,
            'body': json.dumps('Error updating service')
        }
        
