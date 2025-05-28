# Python script to retrieve elastic load balancer target uptime data from EC2 and store it in an S3 bucket for future analysis
# Nick Buckingham
# 27 May 2025

import boto3
import datetime
import csv
import io

# AWS Configuration
AWS_REGION = "eu-west-2"
ELB_NAME = "app/PPUD-ALB/9d129853721723f4"
TARGET_GROUP = "targetgroup/PPUD/bcba227bc22d4132"
S3_BUCKET = "moj-lambda-metrics-prod"

def get_uptime_percentage():
    client = boto3.client("cloudwatch", region_name=AWS_REGION)

    # Time range: Last 24 hours
    end_time = datetime.datetime.utcnow()
    start_time = end_time - datetime.timedelta(days=1)

    response = client.get_metric_statistics(
        Namespace="AWS/ApplicationELB",
        MetricName="HealthyHostCount",
        Dimensions=[
            {"Name": "LoadBalancer", "Value": ELB_NAME},
            {"Name": "TargetGroup", "Value": TARGET_GROUP}
        ],
        StartTime=start_time,
        EndTime=end_time,
        Period=60,  # 1-minute interval
        Statistics=["Average"]
    )

    healthy_counts = [datapoint["Average"] for datapoint in response.get("Datapoints", [])]
    total_minutes = len(healthy_counts)
    healthy_minutes = sum(1 for count in healthy_counts if count > 0)
    uptime_percentage = round((healthy_minutes / total_minutes) * 100, 4) if total_minutes else 0

    return uptime_percentage, healthy_counts, start_time, end_time

def save_to_s3(uptime_percentage, healthy_counts, start_time, end_time):
    s3_client = boto3.client("s3")

    # Generate filename based on the current date
    current_date = datetime.datetime.utcnow().strftime("%Y-%m-%d")
    s3_key = f"elb-target-uptime/elb_uptime_report_{current_date}.csv"

    # Prepare CSV Data
    csv_buffer = io.StringIO()
    csv_writer = csv.writer(csv_buffer)
    
    # Write headers
    csv_writer.writerow(["Timestamp", "HealthyHostCount", "Uptime"])

    # Write data points
    for i, count in enumerate(healthy_counts):
        timestamp = start_time + datetime.timedelta(minutes=i)
        uptime_value = 100 if count in [1, 2] else 0
        csv_writer.writerow([timestamp.strftime("%Y-%m-%d %H:%M:%S"), round(count, 2), uptime_value])

    # Upload CSV to S3
    s3_client.put_object(
        Bucket=S3_BUCKET,
        Key=s3_key,
        Body=csv_buffer.getvalue(),
        ContentType="text/csv"
    )

    return f"CSV file uploaded successfully to s3://{S3_BUCKET}/{s3_key}"

def lambda_handler(event, context):
    uptime_percentage, healthy_counts, start_time, end_time = get_uptime_percentage()
    result = save_to_s3(uptime_percentage, healthy_counts, start_time, end_time)

    return {"statusCode": 200, "body": result}
