# Python script to retrieve elastic load balancer target uptime data from S3 and calculate the daily and monthly average uptime
# Nick Buckingham
# Updated: 29 May 2025

import boto3
import csv
import io
import smtplib
from datetime import datetime, timedelta
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
    response = S3_CLIENT.list_objects_v2(Bucket=S3_BUCKET, Prefix=S3_PREFIX)
    if "Contents" not in response:
        raise ValueError("No CSV files found in S3 bucket.")

    return [obj["Key"] for obj in response["Contents"] if obj["Key"].endswith(".csv")]

def download_csv_from_s3(s3_key):
    response = S3_CLIENT.get_object(Bucket=S3_BUCKET, Key=s3_key)
    return response["Body"].read().decode("utf-8")

def get_previous_month_range():
    today = datetime.today()
    first_day_current_month = today.replace(day=1)
    last_day_previous_month = first_day_current_month - timedelta(days=1)
    first_day_previous_month = last_day_previous_month.replace(day=1)
    return first_day_previous_month, last_day_previous_month

def calculate_uptimes(csv_data, month_start, month_end):
    reader = csv.DictReader(io.StringIO(csv_data))

    overall_uptime = []
    business_hours_uptime = []

    for row in reader:
        try:
            uptime = float(row["Uptime"])
            timestamp_str = row["Timestamp"]
            timestamp = datetime.strptime(timestamp_str, "%d/%m/%Y %H:%M")

            if not (month_start <= timestamp <= month_end):
                continue

            hour = timestamp.hour
            weekday = timestamp.weekday()  # Monday is 0, Sunday is 6

            overall_uptime.append(uptime)
            if 0 <= weekday <= 4 and 8 <= hour < 18:  # Monday to Friday, 08:00 to 17:59
                business_hours_uptime.append(uptime)
        except (ValueError, KeyError):
            continue

    return overall_uptime, business_hours_uptime

def send_email(overall_avg, business_avg):
    body = f"""Hi Team,

Please find below the PPUD Load Balancer availability figures for the last month:

Business day uptime (08:00 to 18:00 Mon to Fri): {business_avg:.2f}%

Overall uptime (24 hours): {overall_avg:.2f}%

Note the uptime figures measure the availability of the PPUD web servers in the load balancer. It does not measure the availability of the backend PPUD system.

This is an automated email."""

    msg = MIMEText(body)
    msg["Subject"] = SUBJECT
    msg["From"] = SENDER
    msg["To"] = ", ".join(RECIPIENTS)

    with smtplib.SMTP(SMTP_SERVER, SMTP_PORT) as server:
        server.sendmail(SENDER, RECIPIENTS, msg.as_string())

def lambda_handler(event, context):
    try:
        month_start, month_end = get_previous_month_range()
        csv_files = list_csv_files()

        all_overall = []
        all_business = []

        for csv_file in csv_files:
            csv_data = download_csv_from_s3(csv_file)
            overall, business = calculate_uptimes(csv_data, month_start, month_end)
            all_overall.extend(overall)
            all_business.extend(business)

        if not all_overall:
            raise ValueError("No valid overall uptime data found for previous month.")
        if not all_business:
            raise ValueError("No valid business hours uptime data found for previous month.")

        overall_avg = sum(all_overall) / len(all_overall)
        business_avg = sum(all_business) / len(all_business)

        send_email(overall_avg, business_avg)

        return {
            "statusCode": 200,
            "body": (
                f"Overall Average Uptime: {overall_avg:.2f}% | "
                f"Business Hours Uptime: {business_avg:.2f}% (Email Sent)"
            )
        }

    except Exception as e:
        return {"statusCode": 500, "body": f"Error: {str(e)}"}
