# Python script to retrieve elastic load balancer target uptime data from S3 and calculate the daily and monthly average uptime
# Nick Buckingham
# 27 May 2025

import boto3
import pandas as pd
import datetime

# AWS Configuration
AWS_REGION = "eu-west-2"
S3_BUCKET = "moj-lambda-metrics-prod"
S3_PREFIX = "elb-target-uptime/"
S3_CLIENT = boto3.client("s3", region_name=AWS_REGION)

def get_latest_csv_key():
    """Retrieves the latest CSV file from S3 based on today's date"""
    today_date = datetime.datetime.utcnow().strftime("%Y-%m-%d")
    csv_key = f"{S3_PREFIX}elb_uptime_report_{today_date}.csv"
    return csv_key

def download_csv_from_s3(s3_key):
    """Downloads CSV file content from S3"""
    response = S3_CLIENT.get_object(Bucket=S3_BUCKET, Key=s3_key)
    csv_data = response["Body"].read().decode("utf-8")
    return csv_data

def calculate_uptime(csv_data):
    """Processes the CSV data and calculates daily % uptime"""
    df = pd.read_csv(pd.compat.StringIO(csv_data))  # Load CSV into DataFrame
    
    if "Uptime" not in df.columns:
        raise ValueError("Column 'Uptime' not found in CSV")

    # Calculate % uptime (average of uptime values)
    uptime_percentage = round(df["Uptime"].mean(), 4)

    return uptime_percentage

def lambda_handler(event, context):
    """Main Lambda function entry point"""
    try:
        csv_key = get_latest_csv_key()
        csv_data = download_csv_from_s3(csv_key)
        uptime_percentage = calculate_uptime(csv_data)
        return {"statusCode": 200, "body": f"Daily Uptime Percentage: {uptime_percentage:.4f}%"}
    
    except Exception as e:
        return {"statusCode": 500, "body": f"Error: {str(e)}"}