# Python script to retrieve cloudwatch metic data (cpu processes), graph it and email it to end users via the internal mail relay.
# Nick Buckingham
# 20 May 2025

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
INSTANCE_ID = "i-029d2b17679dab982"
SERVER = "022"
#START_TIME = datetime(2025, 5, 13, 8, 0, 0)
#END_TIME = datetime(2025, 5, 13, 17, 0, 0)
END_TIME = datetime.utcnow() 
START_TIME = END_TIME - timedelta(hours=9)
SENDER = "donotreply@cjsm.secure-email.ppud.justice.gov.uk"
RECIPIENTS = ["nick.buckingham@colt.net", "pankaj.pant@colt.net", "david.savage@colt.net", "kofi.owusu-nimoh@colt.net", "helen.stimpson@colt.net", "prasad.cherukuri@colt.net"]
#RECIPIENTS = ["nick.buckingham@colt.net"]
SUBJECT = f'AWS EC2 CPU Utilization Report - {SERVER} - {CURRENT_DATE}'
REGION = "eu-west-2"
IMAGE_ID = "ami-02f8251c8cdf2464f"
INSTANCE_TYPE = "m5.xlarge"

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
                    'Stat': 'Average'
                },
                'ReturnData': True
            },
        ],
        StartTime=START_TIME,
        EndTime=END_TIME
    )
    return response['MetricDataResults'][0]

def create_graph(cpu_data, converttopdf_data, pdfcrawler2app_data, winword_data, wmiprvse_data, createthumbnails_data):
    plt.figure(figsize=(20, 5))
    plt.plot(cpu_data['Timestamps'], cpu_data['Values'], label='Total Server CPU Utilization', marker="o", linestyle="-", color="teal")
    plt.plot(converttopdf_data['Timestamps'], converttopdf_data['Values'], label='Convert to PDF CPU Utilization', marker="o", linestyle="--", color="royalblue")
    plt.plot(pdfcrawler2app_data['Timestamps'], pdfcrawler2app_data['Values'], label='PDF Crawler CPU Utilization',  marker="o", linestyle="--", color="cyan")
    plt.plot(winword_data['Timestamps'], winword_data['Values'], label='Microsoft Word CPU Utilization',  marker="o", linestyle="--", color="orange")
    plt.plot(wmiprvse_data['Timestamps'], wmiprvse_data['Values'], label='WmiPrvSE CPU Utilization',  marker="o", linestyle="--", color="red")
    plt.plot(createthumbnails_data['Timestamps'], createthumbnails_data['Values'], label='Create Thumbnails CPU Utilization',  marker="o", linestyle="--", color="darkviolet")
    plt.xlabel('Time (UTC)')
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
        <p>Please find below the CPU utilization metrics for EC2 instance {SERVER} for today from 08:00 to 17:00.</p>
        <img src="data:image/png;base64,{graph_base64}" alt="CPU Utilization Graph" />
        <p>Note the times above are in UTC time, for BST time please add one hour to the above times.
        <p></p>
        <p>For multiple processes with the same name, the graph will display the aggregated average of all the processes and not the total CPU usage.</p>
        <p></p>
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
    cpu_data = get_metric_data('AWS/EC2', 'CPUUtilization', [{'Name': 'InstanceId', 'Value': INSTANCE_ID}])
    converttopdf_data = get_metric_data('CWAgent', 'procstat cpu_usage', [{'Name': 'InstanceId', 'Value': INSTANCE_ID}, {'Name': 'process_name', 'Value': 'ConvertToPDF.exe'}, {'Name': 'exe', 'Value': 'ConvertToPDF'}, {'Name': 'ImageId', 'Value': IMAGE_ID}, {'Name': 'InstanceType', 'Value': INSTANCE_TYPE}])
    pdfcrawler2app_data = get_metric_data('CWAgent', 'procstat cpu_usage', [{'Name': 'InstanceId', 'Value': INSTANCE_ID}, {'Name': 'process_name', 'Value': 'PDFCrawler2App.exe'}, {'Name': 'exe', 'Value': 'PDFCrawler2App'}, {'Name': 'ImageId', 'Value': IMAGE_ID}, {'Name': 'InstanceType', 'Value': INSTANCE_TYPE}])
    winword_data = get_metric_data('CWAgent', 'procstat cpu_usage', [{'Name': 'InstanceId', 'Value': INSTANCE_ID}, {'Name': 'process_name', 'Value': 'WINWORD.exe'.upper()}, {'Name': 'exe', 'Value': 'WINWORD'.upper()}, {'Name': 'ImageId', 'Value': IMAGE_ID}, {'Name': 'InstanceType', 'Value': INSTANCE_TYPE}])
    wmiprvse_data = get_metric_data('CWAgent', 'procstat cpu_usage', [{'Name': 'InstanceId', 'Value': INSTANCE_ID}, {'Name': 'process_name', 'Value': 'WmiPrvSE.exe'}, {'Name': 'exe', 'Value': 'WmiPrvSE'}, {'Name': 'ImageId', 'Value': IMAGE_ID}, {'Name': 'InstanceType', 'Value': INSTANCE_TYPE}])
    createthumbnails_data = get_metric_data('CWAgent', 'procstat cpu_usage', [{'Name': 'InstanceId', 'Value': INSTANCE_ID}, {'Name': 'process_name', 'Value': 'CreateThumbnails.exe'}, {'Name': 'exe', 'Value': 'CreateThumbnails'}, {'Name': 'ImageId', 'Value': IMAGE_ID}, {'Name': 'InstanceType', 'Value': INSTANCE_TYPE}])

    # Adjust CPU utilization values for multi-core distribution (divide by 4)
    converttopdf_data['Values'] = [v / 4 for v in converttopdf_data['Values']]
    pdfcrawler2app_data['Values'] = [v / 4 for v in pdfcrawler2app_data['Values']]
    winword_data['Values'] = [v / 4 for v in winword_data['Values']]
    wmiprvse_data['Values'] = [v / 4 for v in wmiprvse_data['Values']]
    createthumbnails_data['Values'] = [v / 4 for v in createthumbnails_data['Values']]

    # Create a graph and encode it as base64
    print("Creating graph...")
    graph_base64 = create_graph(cpu_data, converttopdf_data, pdfcrawler2app_data, winword_data, wmiprvse_data, createthumbnails_data)

    # Send email with the graph embedded
    print("Sending email...")
    #email_image_to_users(graph_image.getvalue())
    email_image_to_users(graph_base64)

    return {
        'statusCode': 200,
        'body': 'Graph successfully emailed!'
    }
