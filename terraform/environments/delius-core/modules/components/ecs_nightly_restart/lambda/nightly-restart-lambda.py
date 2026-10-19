import os
import boto3

def handler(event, context):
    ecs = boto3.client('ecs')
    cloudwatch = boto3.client('cloudwatch')

    cluster = os.environ['CLUSTER']
    service = os.environ['SERVICE']
    desired_count = int(os.environ['DESIRED_COUNT'])

    alarm_names = [ name.strip()
        for name in os.environ['ALARM_NAMES'].split(',')
        if name.strip()
    ]

    # Disable CloudWatch alarm
    if alarm_names:
        cloudwatch.disable_alarm_actions(
            AlarmNames=alarm_names
        )

    try:
        ecs.update_service(
            cluster=cluster,
            service=service,
            desiredCount=desired_count,
            forceNewDeployment=True
        )

        # Wait for the ECS service to become stable
        waiter = ecs.get_waiter('services_stable')
        waiter.wait(
            cluster=cluster,
            services=[service],
            WaiterConfig={
                'Delay': 15,
                'MaxAttempts': 100
            }
        )
        print('ECS deployment completed successfully.')

    finally:
        if alarm_names:
            cloudwatch.enable_alarm_actions(
                AlarmNames=alarm_names
            )
        print('CloudWatch alarm actions re-enabled.')