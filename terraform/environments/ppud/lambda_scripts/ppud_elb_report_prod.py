import boto3
import os
os.environ['MPLCONFIGDIR'] = "/tmp/graph"
import matplotlib.pyplot as plt
from datetime import datetime, timedelta
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText
from email.mime.base import MIMEBase
from email import encoders
from botocore.exceptions import NoCredentialsError, PartialCredentialsError
import base64
import smtplib

# Configuration
CURRENT_DATE = datetime.now().strftime('%a %d %b %Y')
SENDER = 'noreply@internaltest.ppud.justice.gov.uk'
RECIPIENTS = ['nick.buckingham@colt.net']
SUBJECT = f'AWS Daily PPUD ELB Request Report - {CURRENT_DATE}'
AWS_REGION = 'eu-west-2'
ELB_NAME = "PPUD-ALB"  # Replace with your ELB name

# SMTP Configuration
SMTP_SERVER = "10.27.9.39"
SMTP_PORT = 25

# Initialize AWS clients
cloudwatch = boto3.client("cloudwatch", region_name=AWS_REGION)
ses = boto3.client("ses", region_name=AWS_REGION)

def get_hourly_request_counts(elb_name):
    """Fetches daily connection counts for the ELB from CloudWatch."""
    end_time = datetime.utcnow()
    start_time = end_time - timedelta(days=1)  # Fetch data for the last 1 day

    response = cloudwatch.get_metric_statistics(
        Namespace="AWS/ELB",
        MetricName="RequestCount",
        Dimensions=[
            {"Name": "LoadBalancerName", "Value": elb_name}
        ],
        StartTime=start_time,
        EndTime=end_time,
        Period=3600,  # Daily period
        Statistics=["Sum"]
    )

    data_points = sorted(response["Datapoints"], key=lambda x: x["Timestamp"])
    return [(dp["Timestamp"].strftime('%H:%M'), dp["Sum"]) for dp in data_points]

def plot_graph(request_data):
    """Plots the graph of hourly requests and returns it as an in-memory file."""
    times, requests = zip(*request_data)
    plt.figure(figsize=(20, 6))
    plt.bar(times, requests, color="blue")
    plt.title(f"Hourly Requests to {ELB_NAME} Over the Last 24 Hours")
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

# Function to send an email via SES
def send_email_with_graph(graph_base64):
    """
    Send an email with the graph embedded in the email body using AWS SES.
    """
    cloudwatch = boto3.client("cloudwatch", region_name=AWS_REGION)

    # Email body with the embedded image
    email_body = f"""
    <html>
    <body>
        <p>Hi Team,</p>
        <p>Please find below the daily PPUD ELB Request Report.</p>
        <img src="data:image/png;base64,{graph_base64}" alt="PPUD ELB Request Report" />
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
        request_data = get_hourly_request_counts(ELB_NAME)
        if not request_data:
            print("No data found for the specified ELB.")
            return

        # Create graph
        temp_file = plot_graph(request_data)

        # Send email
        send_email_with_graph(SENDER, temp_file)
        print("Process completed successfully.")
		
    except (NoCredentialsError, PartialCredentialsError) as cred_error:
        print(f"Credential issue: {cred_error}")
    except Exception as e:
        print(f"An error occurred: {e}")
