# Python script to retrieve elastic load balancer target response time data from S3 and calculate the monthly average target response time
# Nick Buckingham
# 30 May 2025

import boto3
import csv
import io
import smtplib
from datetime import datetime, timedelta
from email.mime.text import MIMEText

# AWS Configuration
AWS_REGION = "eu-west-2"
S3_BUCKET = "moj-lambda-metrics-prod"
S3_PREFIX = "elb-target-response-time/"
S3_CLIENT = boto3.client("s3", region_name=AWS_REGION)

# Email Configuration
SENDER = "donotreply@cjsm.secure-email.ppud.justice.gov.uk"
RECIPIENTS = ["nick.buckingham@colt.net"]
SUBJECT = "AWS PPUD Load Balancer Target Response Time Report"
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

def calculate_response_times(csv_data, month_start, month_end):
    reader = csv.DictReader(io.StringIO(csv_data))

    overall_response_times = []
    business_hours_response_times = []

    for row in reader:
        try:
            response_time = float(row["OverallAverageTargetResponseTime"])
            timestamp_str = row["Timestamp"]
            timestamp = datetime.strptime(timestamp_str, "%d/%m/%Y %H:%M")  # Updated format

            if not (month_start <= timestamp <= month_end):
                continue

            hour = timestamp.hour
            weekday = timestamp.weekday()  # Monday is 0, Sunday is 6

            overall_response_times.append(response_time)
            if 0 <= weekday <= 4 and 8 <= hour < 18:  # Monday to Friday, 08:00 to 17:59
                business_hours_response_times.append(response_time)
        except (ValueError, KeyError):
            continue

    return overall_response_times, business_hours_response_times

def send_email(overall_avg, business_avg):
    body = f"""<html><body>
    <p>Hi Team,</p>

    <p>Please find below the PPUD load balancer target response time figures for the last month:</p>

    <p>Business day target response time (08:00 to 18:00 Mon to Fri): <b>{business_avg:.2f} ms</b></p>
    <p>Overall target response time (entire month): <b>{overall_avg:.2f} ms</b></p>

    <p>Target response time measures the time it takes for the load balancer to send a request to the targets 
    (in this case the EC2 instance web servers) and for the targets to start sending back the response headers.</p>

    <p>It measures the general latency of the PPUD web servers up to the perimeter of the AWS network. 
    It does not include latency on the MoJ network.</p>

    <p>This is an automated email.</p>
    </body></html>"""

    msg = MIMEText(body, "html")  # Setting MIME type to HTML for formatting
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
            overall, business = calculate_response_times(csv_data, month_start, month_end)
            all_overall.extend(overall)
            all_business.extend(business)

        if not all_overall:
            raise ValueError("No valid overall response time data found for previous month.")
        if not all_business:
            raise ValueError("No valid business hours response time data found for previous month.")

        overall_avg = sum(all_overall) / len(all_overall)
        business_avg = sum(all_business) / len(all_business)

        send_email(overall_avg, business_avg)

        return {
            "statusCode": 200,
            "body": (
                f"Overall Average Target Response Time: {overall_avg:.2f} ms | "
                f"Business Day Target Response Time: {business_avg:.2f} ms (Email Sent)"
            )
        }

    except Exception as e:
        return {"statusCode": 500, "body": f"Error: {str(e)}"}
