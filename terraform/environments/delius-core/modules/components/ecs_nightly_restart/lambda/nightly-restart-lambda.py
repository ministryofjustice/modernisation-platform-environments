import os
import boto3

def handler(event, context):
    ecs = boto3.client('ecs')

    # Replace instances and scale in to desired count
    ecs.update_service(cluster=os.getenv('CLUSTER'),
                       service=os.getenv('SERVICE'),
                       desiredCount=int(os.getenv('DESIRED_COUNT')),
                       forceNewDeployment=True)
