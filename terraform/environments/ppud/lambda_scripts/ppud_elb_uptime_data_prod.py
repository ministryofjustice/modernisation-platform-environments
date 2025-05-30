# Python script to retrieve elastic load balancer target uptime data from EC2 and store it in an S3 bucket for future analysis
# Nick Buckingham
# 28 May 2025

import boto3
import csv
import os
import tempfile
from datetime import datetime, timedelta, timezone

# Configuration
REGION = 'eu-west-2'
TARGET_GROUP = 'targetgroup/PPUD/bcba227bc22d4132'
LOAD_BALANCER = 'app/PPUD-ALB/9d129853721723f4'
S3_BUCKET = 'moj-lambda-metrics-prod'

def lambda_handler(event, context):
    cloudwatch = boto3.client('cloudwatch', region_name=REGION)
    s3 = boto3.client('s3', region_name=REGION)

    # Time range for a specific period (UTC):
    #start_time = datetime(2025, 5, 24, 0, 0, 0, tzinfo=timezone.utc)
    #end_time = datetime(2025, 5, 24, 23, 59, 59, tzinfo=timezone.utc)

    # Time range: last 24 hours from now (UTC)
    end_time = datetime.now(timezone.utc)
    start_time = end_time - timedelta(days=1)

    # Format for S3 file path: elb-target-uptime/elb_uptime_report_START_DATE.csv
    start_date_str = start_time.strftime('%Y-%m-%d')
    s3_key = f"elb-target-uptime/elb_uptime_report_{start_date_str}.csv"

    # Get CloudWatch metrics
    response = cloudwatch.get_metric_statistics(
        Namespace='AWS/ApplicationELB',
        MetricName='HealthyHostCount',
        Dimensions=[
            {'Name': 'TargetGroup', 'Value': TARGET_GROUP},
            {'Name': 'LoadBalancer', 'Value': LOAD_BALANCER}
        ],
        StartTime=start_time,
        EndTime=end_time,
        Period=60,  # 1 minute
        Statistics=['Minimum'],
        Unit='Count'
    )

    # Prepare data
    rows = []
    for point in sorted(response['Datapoints'], key=lambda x: x['Timestamp']):
        formatted_timestamp = point['Timestamp'].astimezone(timezone.utc).strftime('%d/%m/%Y %H:%M')
        healthy_count = int(point['Minimum'])
        uptime = 100 if healthy_count >= 1 else 0
        rows.append([formatted_timestamp, healthy_count, uptime])

    if not rows:
        print("No metrics data found.")
        return

    # Write CSV
    with tempfile.NamedTemporaryFile(mode='w+', delete=False) as csvfile:
        writer = csv.writer(csvfile)
        writer.writerow(['Timestamp', 'HealthyHostCount', 'Uptime'])
        writer.writerows(rows)
        temp_file_name = csvfile.name

    # Upload to S3
    with open(temp_file_name, 'rb') as data:
        s3.upload_fileobj(data, S3_BUCKET, s3_key)
        print(f"Uploaded file to s3://{S3_BUCKET}/{s3_key}")

    # Clean up
    os.remove(temp_file_name)
