# Python script to retrieve elastic load balancer data from cloudwatch, count the connections per 15 minutes
# graph it and email it to end users via the internal mail relay.
# Nick Buckingham
# 3 April 2025

import boto3
import os
os.environ['MPLCONFIGDIR'] = "/tmp/graph"
import matplotlib.pyplot as plt
from datetime import datetime, timedelta
import io
import base64
import smtplib
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText
from botocore.exceptions import NoCredentialsError, PartialCredentialsError

# Configuration
CURRENT_DATE = datetime.now().strftime('%a %d %b %Y')
SENDER = "donotreply@cjsm.secure-email.ppud.justice.gov.uk"
RECIPIENTS = ['nick.buckingham@colt.net']
SUBJECT = f'AWS WAM Load Balancer Report - {CURRENT_DATE}'
AWS_REGION = 'eu-west-2'
ELB_NAME = "app/WAM-ALB-PROD/bfc963544454bdde"  # Replace with your ELB name

# SMTP Configuration
SMTP_SERVER = "10.27.9.39"
SMTP_PORT = 25

# Initialize AWS clients
cloudwatch = boto3.client("cloudwatch", region_name=AWS_REGION)
#ses = boto3.client("ses", region_name=AWS_REGION)

def get_elb_request_counts(ELB_NAME):
    """Fetches daily connection counts for the ELB from CloudWatch."""
    # Calculate the start and end time for the day
    #start_time = datetime(2024, 12, 8, 6, 0, 0)  # 08:00 UTC, 28 Nov 2024
    #end_time = datetime(2024, 12, 8, 20, 10, 0)  # 17:00 UTC, 28 Nov 2024
    # current_time = datetime.utcnow()
    current_time = datetime.utcnow() + timedelta(hours=1)
    end_time = datetime.utcnow()
    start_time = end_time - timedelta(hours=14)

    response = cloudwatch.get_metric_statistics(
        Namespace="AWS/ApplicationELB",
        MetricName="RequestCount",
        Dimensions=[
            {"Name": "LoadBalancer", "Value": ELB_NAME},
#			{'Name': 'TargetGroup', 'Value': 'PPUD'},
#			{'Name': 'AvailabilityZone', 'Value': 'eu-west-2c'}
        ],
        StartTime=start_time,
        EndTime=end_time,
        Period=900,  # 15 minute intervals
        Statistics=["Sum"]
    )

    data_points = sorted(response["Datapoints"], key=lambda x: x["Timestamp"])
    return [(dp["Timestamp"].strftime('%H:%M'), dp["Sum"]) for dp in data_points]

def create_graph(request_data):
    """Plots the graph of requests and returns it as an in-memory file."""
    times, requests = zip(*request_data)
    plt.figure(figsize=(20, 6))
    plt.plot(times, requests, color="blue")
    plt.title(f"Requests to the WAM Load Balancer on {CURRENT_DATE} (Every 15 Minutes)")
    plt.xlabel("Time (UTC)")
    plt.ylabel("Number of Requests")
    plt.xticks(rotation=45)
    plt.grid(axis="y", linestyle="--", linewidth=0.7, alpha=0.7)
    plt.tight_layout()
	
  #  graph_path = "elb_daily_connections.png"
  #  plt.savefig(graph_path)
  #  plt.close()
  #  return graph_path

    # Save the graph to a temporary buffer
    temp_file = "/tmp/elb_daily_connections.png"
    plt.savefig(temp_file)
    plt.close()

    # Read the image and encode it to base64
    with open(temp_file, "rb") as image_file:
        encoded_string = base64.b64encode(image_file.read()).decode("utf-8")

    # Cleanup temporary file
    os.remove(temp_file)
    return encoded_string

def email_image_to_users(graph_base64):
    """
    Send an email with the graph embedded in the email body using AWS SES.
    """
    ses_client = boto3.client("ses", region_name=AWS_REGION)

    # Email body with the embedded image
    email_body = f"""
    <html>
    <body>
        <p>Hi Team,</p>
        <p>Please find below the WAM Elastic Load Balancer report for {CURRENT_DATE}.</p>
        <img src="data:image/png;base64,{graph_base64}" alt="WAM ELB Report" />
        <p>This is an automated email.</p>
    </body>
    </html>
    """

    # Create the email message
    msg = MIMEMultipart("alternative")
    msg["From"] = SENDER
    msg["To"] = ", ".join(RECIPIENTS)
    msg["Subject"] = SUBJECT

    # Attach the HTML body
    msg.attach(MIMEText(email_body, "html"))

    # Send the email with AWS SES
  #  try:
  #      response = ses_client.send_raw_email(
  #          Source=SENDER,
  #          Destinations=RECIPIENTS,
  #          RawMessage={"Data": msg.as_string()},
  #      )
  #      print("Email sent! Message ID:", response["MessageId"])
  #  except Exception as e:
  #      print("Error sending email:", e)
  #      raise

    # Send the email with an EC2 Instance Mail Relay
    try:
        with smtplib.SMTP(SMTP_SERVER, SMTP_PORT) as server:
         #  server.starttls()
         #  server.login(SENDER, EMAIL_PASSWORD)
            server.sendmail(SENDER, RECIPIENTS, msg.as_string())
        print("Email sent successfully.")
    except Exception as e:
        print(f"Error sending email: {e}")

		
def lambda_handler(event, context):
    try:
        # Get hourly request counts
        request_data = get_elb_request_counts(ELB_NAME)
        if not request_data:
            print("No data found for the specified ELB.")
            return

        # Create graph
        #temp_file = plot_graph(request_data)
        graph_base64 = create_graph(request_data)

        # Send email
        email_image_to_users(graph_base64)
        print("Process completed successfully.")
		
    except (NoCredentialsError, PartialCredentialsError) as cred_error:
        print(f"Credential issue: {cred_error}")
    except Exception as e:
        print(f"An error occurred: {e}")
