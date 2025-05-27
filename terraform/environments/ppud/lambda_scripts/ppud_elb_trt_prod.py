# Python script to retrieve PPUD elastic load balancer target response time metric from cloudwatch, calculate the average over 40 minutes, graph it and email it to end users via the internal mail relay.
# Nick Buckingham
# 27 May 2025

import boto3
import datetime
import os
os.environ['MPLCONFIGDIR'] = "/tmp/graph"
import matplotlib.pyplot as plt
import smtplib
import base64
from io import BytesIO
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText

# AWS and Load Balancer details
region = "eu-west-2"
lb_name = "app/PPUD-ALB/9d129853721723f4"
metric_name = "TargetResponseTime"
namespace = "AWS/ApplicationELB"

# Email details
smtp_server = "10.27.9.39"
smtp_port = 25
sender_email = "donotreply@cjsm.secure-email.ppud.justice.gov.uk"
#recipients = ["nick.buckingham@colt.net"]
recipients = ["nick.buckingham@colt.net", "david.savage@colt.net", "gabriela.browning@colt.net", "pankaj.pant@colt.net"]

# Fetch CloudWatch metrics
def get_metrics():
    client = boto3.client("cloudwatch", region_name=region)
    end_time = datetime.datetime.utcnow()
    start_time = end_time - datetime.timedelta(days=14)

    response = client.get_metric_statistics(
        Namespace=namespace,
        MetricName=metric_name,
        Dimensions=[{"Name": "LoadBalancer", "Value": lb_name}],
        StartTime=start_time,
        EndTime=end_time,
        Period=2400,  # 40 minutes
        Statistics=["Average"],
        Unit="Seconds"
    )
    
    timestamps = sorted([point["Timestamp"] for point in response["Datapoints"]])
    values = [point["Average"] for point in response["Datapoints"]]
    
    return timestamps, values

# Generate graph with a single line
def generate_graph(timestamps, values):
    plt.figure(figsize=(20, 6))
    plt.plot(timestamps, values, linestyle="-", color="b")  # Ensuring single continuous line
    plt.xlabel("Date Range")
    plt.ylabel("Response Time (seconds)")
    plt.title("PPUD Load Balancer Target Response Time (Last 14 Days)")
    plt.xticks(rotation=45)
    plt.grid()
    plt.tight_layout()

    # Save the figure to a BytesIO object
    img_stream = BytesIO()
    plt.savefig(img_stream, format="png")
    img_stream.seek(0)

    # Encode to base64
    encoded_img = base64.b64encode(img_stream.read()).decode("utf-8")
    return encoded_img

# Send email with embedded graph
def send_email(encoded_img):
    msg = MIMEMultipart("alternative")
    msg["From"] = sender_email
    msg["To"] = ", ".join(recipients)
    msg["Subject"] = "AWS PPUD Load Balancer Target Response Time Report"

    html_body = f"""
    <html>
    <body>
        <p>Hi Team,</p>
        <p></p>
        <p>Please find below the PPUD Load Balancer Target Response Time Report for the last 14 days.</p>
        <img src="data:image/png;base64,{encoded_img}" alt="Response Time Graph">
        <p>The datapoints in this graph have been averaged over a 40 minute period.</p>
        <p>Target response time measures the time it takes for the load balancer to send a request to the targets (in this case the EC2 instance web servers) and for the targets to start sending back the response headers. It measures the general latency of the PPUD web servers up to the perimeter of the AWS network.
</p>
        <p>This is an automated email.</p>
    </body>
    </html>
    """

    msg.attach(MIMEText(html_body, "html"))

    with smtplib.SMTP(smtp_server, smtp_port) as server:
        server.sendmail(sender_email, recipients, msg.as_string())

def lambda_handler(event, context):
    timestamps, values = get_metrics()
    encoded_img = generate_graph(timestamps, values)
    send_email(encoded_img)
    return {"status": "Email sent successfully"}
