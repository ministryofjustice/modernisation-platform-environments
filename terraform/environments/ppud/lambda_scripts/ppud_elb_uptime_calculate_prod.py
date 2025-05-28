# Python script to retrieve elastic load balancer target uptime data from S3 and calculate the daily and monthly average uptime
# Nick Buckingham
# 28 May 2025

import boto3
import csv
import io
import smtplib
from email.mime.text import MIMEText

# AWS Configuration
AWS_REGION = "eu-west-2"
S3_BUCKET = "moj-lambda-metrics-prod"
S3_PREFIX = "elb-target-uptime/"
S3_CLIENT = boto3.client("s3", region_name=AWS_REGION)

# Email Configuration
SENDER = "donotreply@cjsm.secure-email.ppud.justice.gov.uk"
RECIPIENTS = ["nick.buckingham@colt.net"]
SUBJECT = "AWS PPUD Load Balancer Uptime Report"
SMTP_SERVER = "10.27.9.39"
SMTP_PORT = 25

def list_csv_files():
    """Lists all CSV files in the specified S3 bucket and prefix."""
    response = S3_CLIENT.list_objects_v2(Bucket=S3_BUCKET, Prefix=S3_PREFIX)
    if "Contents" not in response:
        raise ValueError("No CSV files found in S3 bucket.")

    csv_files = [obj["Key"] for obj in response["Contents"] if obj["Key"].endswith(".csv")]
    return csv_files

def download_csv_from_s3(s3_key):
    """Downloads CSV file content from S3."""
    response = S3_CLIENT.get_object(Bucket=S3_BUCKET, Key=s3_key)
    return response["Body"].read().decode("utf-8")

def calculate_uptime(csv_data):
    """Processes the CSV data and calculates the average uptime using Python's csv module."""
    reader = csv.DictReader(io.StringIO(csv_data))

    uptime_values = []
    for row in reader:
        if "Uptime" in row:
            try:
                uptime_values.append(float(row["Uptime"]))
            except ValueError:
                pass  # Skip invalid entries

    if not uptime_values:
        raise ValueError("No valid 'Uptime' values found in CSV")

    return sum(uptime_values) / len(uptime_values)

def send_email(overall_average_uptime):
    """Sends an email with the uptime results."""
    body = f"""Hi Team,

The PPUD Load Balancers had an uptime of: {overall_average_uptime:.4f}% over the last 30 days.

This is an automated email."""

    msg = MIMEText(body)
    msg["Subject"] = SUBJECT
    msg["From"] = SENDER
    msg["To"] = ", ".join(RECIPIENTS)

    with smtplib.SMTP(SMTP_SERVER, SMTP_PORT) as server:
        server.sendmail(SENDER, RECIPIENTS, msg.as_string())

def lambda_handler(event, context):
    """Main Lambda function entry point."""
    try:
        csv_files = list_csv_files()
        uptime_values = []

        for csv_file in csv_files:
            csv_data = download_csv_from_s3(csv_file)
            uptime_values.append(calculate_uptime(csv_data))

        overall_average_uptime = round(sum(uptime_values) / len(uptime_values), 4)

        send_email(overall_average_uptime)

        return {"statusCode": 200, "body": f"Overall Average Uptime Percentage: {overall_average_uptime:.4f}% (Email Sent)"}
    
    except Exception as e:
        return {"statusCode": 500, "body": f"Error: {str(e)}"}
