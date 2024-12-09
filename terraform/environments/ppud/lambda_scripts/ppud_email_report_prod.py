# Python script to retrieve emails send data from S3, count the number of outgoing emails
# graph it and email it to end users via the internal mail relay.
# Nick Buckingham
# 9 December 2024

import boto3
import os
os.environ['MPLCONFIGDIR'] = "/tmp/graph"
import matplotlib.pyplot as plt
import re
import io
import base64
import smtplib
from datetime import datetime, timedelta
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText

# Initialize boto3 clients
s3 = boto3.client('s3')
# ses = boto3.client('ses')

# Configuration
CURRENT_DATE = datetime.now().strftime('%a %d %b %Y')
TODAY = datetime.now()
YESTERDAY = TODAY - timedelta(days=1)
YESTERDAY_DATE = YESTERDAY.strftime('%a %d %b %Y')
bucket_name = 'moj-lambda-layers-prod'
file_names = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday']
SENDER = 'donotreply@cjsm.secure-email.ppud.justice.gov.uk'
RECIPIENTS = ['nick.buckingham@colt.net']
SUBJECT = f'AWS PPUD Email Report - {CURRENT_DATE}'
AWS_REGION = 'eu-west-2'

# SMTP Configuration
SMTP_SERVER = "10.27.9.39"
SMTP_PORT = 25
MAIL_FROM = "donotreply@cjsm.secure-email.ppud.justice.gov.uk"
EMAIL_TO = ["nick.buckingham@colt.net"]

def retrieve_file_from_s3(bucket, key):
    response = s3.get_object(Bucket=bucket, Key=key)
    content = response['Body'].read().decode('utf-8')
    return content

def count_occurrences(content, pattern):
    matches = re.findall(pattern, content)
    return len(matches)

def create_graph(data):
    days = list(data.keys())
    counts = list(data.values())

    plt.figure(figsize=(15, 5))
    plt.bar(days, counts)
    plt.xlabel('Days of the Week')
    plt.ylabel('Number of Emails ')
    plt.title('PPUD Emails Sent')
    plt.tight_layout()

    # Save the graph to a temporary buffer
    temp_file = "/tmp/ppud_emails_sent.png"
    plt.savefig(temp_file)
    plt.close()

    # Read the image and encode it to base64
    with open(temp_file, "rb") as image_file:
        encoded_string = base64.b64encode(image_file.read()).decode("utf-8")

    # Cleanup temporary file
    os.remove(temp_file)
    return encoded_string
	
def send_email_with_graph(graph_base64):
    """
    Send an email with the graph embedded in the email body using AWS SES.
    """
 #   ses_client = boto3.client("ses", region_name=REGION)

    # Email body with the embedded image
    email_body = f"""
    <html>
    <body>
        <p>Hi Team,</p>
        <p>Please find below the PPUD email report for the week ending {YESTERDAY_DATE}.</p>
        <img src="data:image/png;base64,{graph_base64}" alt="PPUD Email Report" />
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
    pattern = r'to=<'
    data = {}
    
    for file_name in file_names:
        content = retrieve_file_from_s3(bucket_name, file_name)
        count = count_occurrences(content, pattern)
        data[file_name] = count

    graph_base64 = create_graph(data)

    # Send email with the graph embedded
    print("Sending email...")
    #email_image_to_users(graph_image.getvalue())
    send_email_with_graph(graph_base64)

    return {
        'statusCode': 200,
        'body': 'Email sent successfully!'
    }
