import boto3
import os
os.environ['MPLCONFIGDIR'] = "/tmp/graph"
import matplotlib.pyplot as plt
import matplotlib.dates as mdates
from datetime import datetime, timedelta
import io
import base64
import smtplib
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText
from botocore.exceptions import NoCredentialsError, PartialCredentialsError

# Configuration
CURRENT_DATE = datetime.now().strftime('%a %d %b %Y')
SENDER = 'noreply@internaltest.ppud.justice.gov.uk'
RECIPIENTS = ['nick.buckingham@colt.net']
SUBJECT = f'AWS PPUD Load Balancer Target Response Time Report - {CURRENT_DATE}'
AWS_REGION = 'eu-west-2'
ELB_NAME = "app/PPUD-ALB/9d129853721723f4"  # Replace with your ELB name
SMTP_SERVER = "10.27.9.39"
SMTP_PORT = 25

# Initialize AWS clients
cloudwatch = boto3.client("cloudwatch", region_name=AWS_REGION)

def get_elb_response_times(ELB_NAME):
    """Fetches TargetResponseTime for the ELB from CloudWatch."""
    current_time = datetime.utcnow() + timedelta(hours=1)
    end_time = datetime.utcnow()
    start_time = end_time - timedelta(hours=8)

    response = cloudwatch.get_metric_statistics(
        Namespace="AWS/ApplicationELB",
        MetricName="TargetResponseTime",
        Dimensions=[
            {"Name": "LoadBalancer", "Value": ELB_NAME},
            {"Name": "AvailabilityZone", "Value": "eu-west-2b"},
            {"Name": "AvailabilityZone", "Value": "eu-west-2c"}
        ],
        StartTime=start_time,
        EndTime=end_time,
        Period=60,  # 1-minute intervals
        Statistics=["Average"]
    )

    data_points = sorted(response["Datapoints"], key=lambda x: x["Timestamp"])
    return [(dp["Timestamp"].strftime('%H:%M'), dp["Average"]) for dp in data_points]

def create_graph(response_data):
    """Plots the graph for TargetResponseTime and returns it as an in-memory file."""
    # Convert string times to datetime objects for formatting
    times_str, response_times = zip(*response_data)
    times = [datetime.strptime(t, '%H:%M') for t in times_str]

    plt.figure(figsize=(20, 6))
    plt.plot(times, response_times, color="blue")
    plt.title(f"Target Response Time for PPUD Load Balancer on {CURRENT_DATE} (Every 1 Minute)")
    plt.xlabel("Time (UTC)")
    plt.ylabel("Response Time (Seconds)")

    # Set X-axis to only show full hours
    plt.gca().xaxis.set_major_locator(mdates.HourLocator())
    plt.gca().xaxis.set_major_formatter(mdates.DateFormatter('%H:%M'))

    plt.xticks(rotation=45)
    plt.grid(axis="y", linestyle="--", linewidth=0.7, alpha=0.7)
    plt.tight_layout()

    temp_file = "/tmp/elb_target_response_time.png"
    plt.savefig(temp_file)
    plt.close()

    with open(temp_file, "rb") as image_file:
        encoded_string = base64.b64encode(image_file.read()).decode("utf-8")

    os.remove(temp_file)
    return encoded_string

def email_image_to_users(graph_base64):
    """
    Send an email with the graph embedded in the email body using an SMTP relay.
    """
    email_body = f"""
    <html>
    <body>
        <p>Hi Team,</p>
        <p>Please find below the PPUD load balancer target response time report for {CURRENT_DATE}.</p>
        <img src="data:image/png;base64,{graph_base64}" alt="PPUD ELB Report" />
        <p>Note the data displayed is the averaged value of the response time of both web servers.</p>
        <p>This is an automated email.</p>
    </body>
    </html>
    """

    msg = MIMEMultipart("alternative")
    msg["From"] = SENDER
    msg["To"] = ", ".join(RECIPIENTS)
    msg["Subject"] = SUBJECT
    msg.attach(MIMEText(email_body, "html"))

    try:
        with smtplib.SMTP(SMTP_SERVER, SMTP_PORT) as server:
            server.sendmail(SENDER, RECIPIENTS, msg.as_string())
        print("Email sent successfully.")
    except Exception as e:
        print(f"Error sending email: {e}")

def lambda_handler(event, context):
    try:
        response_data = get_elb_response_times(ELB_NAME)
        if not response_data:
            print("No data found for the specified ELB.")
            return

        graph_base64 = create_graph(response_data)
        email_image_to_users(graph_base64)
        print("Process completed successfully.")
        
    except (NoCredentialsError, PartialCredentialsError) as cred_error:
        print(f"Credential issue: {cred_error}")
    except Exception as e:
        print(f"An error occurred: {e}")
