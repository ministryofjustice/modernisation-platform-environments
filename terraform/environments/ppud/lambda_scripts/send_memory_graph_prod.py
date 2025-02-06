# Python script to retrieve cloudwatch metic data (memory), graph it and email it to end users via the internal mail relay.
# Nick Buckingham
# 9 December 2024

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

# Initialize boto3 clients
cloudwatch = boto3.client('cloudwatch')
# ses_client = boto3.client('ses', region_name=REGION)

# Configuration
CURRENT_DATE = datetime.now().strftime('%a %d %b %Y')
INSTANCE_ID = "i-080498c4c9d25e6bd"
SERVER = "021"
START_TIME = datetime(2024, 12, 6, 8, 0, 0)
END_TIME = datetime(2024, 12, 6, 17, 0, 0)
#END_TIME = datetime.utcnow()
#START_TIME = END_TIME - timedelta(hours=9)
SENDER = "donotreply@cjsm.secure-email.ppud.justice.gov.uk"
RECIPIENTS = ["nick.buckingham@colt.net"]
SUBJECT = f'AWS EC2 Memory Utilization Report - {SERVER} - {CURRENT_DATE}'
REGION = "eu-west-2"
IMAGE_ID = "ami-02f8251c8cdf2464f"
INSTANCE_TYPE = "m5.2xlarge"

# SMTP Configuration
SMTP_SERVER = "10.27.9.39"
SMTP_PORT = 25

def get_metric_data(namespace, metric_name, dimensions):
    response = cloudwatch.get_metric_data(
        MetricDataQueries=[
            {
                'Id': 'm1',
                'MetricStat': {
                    'Metric': {
                        'Namespace': namespace,
                        'MetricName': metric_name,
                        'Dimensions': dimensions
                    },
                    'Period': 300,
                    'Stat': 'Maximum'
                },
                'ReturnData': True
            },
        ],
        StartTime=START_TIME,
        EndTime=END_TIME
    )
    return response['MetricDataResults'][0]

def create_graph(memory_data, sqlserver_data, ssms_data):
    plt.figure(figsize=(20, 5))
    plt.plot(memory_data['Timestamps'], memory_data['Values'], label='Total Server Memory Utilization', marker="o", linestyle="-", color="teal")
    plt.plot(sqlserver_data['Timestamps'], sqlserver_data['Values'], label='SQL Server Memory Utilization', marker="o", linestyle="--", color="royalblue")
    plt.plot(ssms_data['Timestamps'], ssms_data['Values'], label='SSSM Memory Utilization',  marker="o", linestyle="--", color="cyan")
    plt.xlabel('Time')
    plt.ylabel('CPU Utilization (%)')
    plt.title(f'EC2 CPU Utilization - {SERVER} - {CURRENT_DATE}')
    plt.legend()
    plt.grid(True)
    plt.tight_layout()

    # Save the graph to a temporary buffer
    temp_file = "/tmp/cpu_utilization_graph.png"
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
    ses_client = boto3.client("ses", region_name=REGION)

    # Email body with the embedded image
    email_body = f"""
    <html>
    <body>
        <p>Hi Team,</p>
        <p>Please find below the memory utilization metrics for EC2 instance {SERVER} for today from 08:00 to 17:00.</p>
        <img src="data:image/png;base64,{graph_base64}" alt="Memory Utilization Graph" />
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
    memory_data = get_metric_data('AWS/EC2', 'CPUUtilization', [{'Name': 'InstanceId', 'Value': INSTANCE_ID}])
    sqlservr_data = get_metric_data('CWAgent', 'procstat memory_rss', [{'Name': 'InstanceId', 'Value': INSTANCE_ID}, {'Name': 'process_name', 'Value': 'sqlservr.exe'}, {'Name': 'exe', 'Value': 'sqlservr'}, {'Name': 'ImageId', 'Value': IMAGE_ID}, {'Name': 'InstanceType', 'Value': INSTANCE_TYPE}])
    ssms_data = get_metric_data('CWAgent', 'procstat memory_rss', [{'Name': 'InstanceId', 'Value': INSTANCE_ID}, {'Name': 'process_name', 'Value': 'Ssms.exe'}, {'Name': 'exe', 'Value': 'Ssms'}, {'Name': 'ImageId', 'Value': IMAGE_ID}, {'Name': 'InstanceType', 'Value': INSTANCE_TYPE}])

    # Create a graph and encode it as base64
    print("Creating graph...")
    graph_base64 = create_graph(memory_data, sqlservr_data, ssms_data)

    # Send email with the graph embedded
    print("Sending email...")
    #email_image_to_users(graph_image.getvalue())
    email_image_to_users(graph_base64)

    return {
        'statusCode': 200,
        'body': 'Graph successfully emailed!'
    }
