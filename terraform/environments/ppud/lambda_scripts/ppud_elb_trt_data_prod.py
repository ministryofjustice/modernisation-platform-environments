# Python script to retrieve elastic load balancer target response time data from EC2 and store it in an S3 bucket for future analysis
# Nick Buckingham
# 29 May 2025

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
AVAILABILITY_ZONES = ['eu-west-2b', 'eu-west-2c']

def lambda_handler(event, context):
    cloudwatch = boto3.client('cloudwatch', region_name=REGION)
    s3 = boto3.client('s3', region_name=REGION)

    # Time range: last 24 hours from now (UTC)
    end_time = datetime.now(timezone.utc)
    start_time = end_time - timedelta(days=1)

    # Format for S3 file path
    start_date_str = start_time.strftime('%Y-%m-%d')
    s3_key = f"elb-target-response-time/elb_trt_report_{start_date_str}.csv"

    # Retrieve CloudWatch metrics for each availability zone
    data_points = {}

    for az in AVAILABILITY_ZONES:
        response = cloudwatch.get_metric_statistics(
            Namespace='AWS/ApplicationELB',
            MetricName='TargetResponseTime',
            Dimensions=[
                {'Name': 'TargetGroup', 'Value': TARGET_GROUP},
                {'Name': 'LoadBalancer', 'Value': LOAD_BALANCER},
                {'Name': 'AvailabilityZone', 'Value': az}
            ],
            StartTime=start_time,
            EndTime=end_time,
            Period=60,  # 1 minute
            Statistics=['Average'],
            Unit='Seconds'
        )

        # Store data by timestamp
        for point in response['Datapoints']:
            timestamp = point['Timestamp'].astimezone(timezone.utc).strftime('%d/%m/%Y %H:%M')
            avg_response_time = point['Average']

            if timestamp not in data_points:
                data_points[timestamp] = {}

            data_points[timestamp][az] = avg_response_time

    if not data_points:
        print("No metrics data found.")
        return

    # Write CSV
    with tempfile.NamedTemporaryFile(mode='w+', delete=False) as csvfile:
        writer = csv.writer(csvfile)
        writer.writerow([
            'TimeStamp',
            'AvailabilityZone eu-west-2b', 'AverageTargetResponseTime eu-west-2b',
            'AvailabilityZone eu-west-2c', 'AverageTargetResponseTime eu-west-2c',
            'Overall AverageTargetResponseTime'
        ])

        for timestamp in sorted(data_points.keys()):
            trt_2b = data_points[timestamp].get('eu-west-2b', None)
            trt_2c = data_points[timestamp].get('eu-west-2c', None)

            # Calculate average if both values exist
            overall_avg = (
                (trt_2b + trt_2c) / 2
                if trt_2b is not None and trt_2c is not None
                else "N/A"
            )

            row = [
                timestamp,
                'eu-west-2b', trt_2b if trt_2b is not None else "N/A",
                'eu-west-2c', trt_2c if trt_2c is not None else "N/A",
                overall_avg
            ]
            writer.writerow(row)

        temp_file_name = csvfile.name

    # Upload to S3
    with open(temp_file_name, 'rb') as data:
        s3.upload_fileobj(data, S3_BUCKET, s3_key)
        print(f"Uploaded file to s3://{S3_BUCKET}/{s3_key}")

    # Clean up
    os.remove(temp_file_name)
