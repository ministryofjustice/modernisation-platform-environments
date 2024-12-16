# Python script to retrieve cloudwatch metic data (disk information), graph it and email it to end users via the internal mail relay.
# Nick Buckingham
# 12 December 2024

import boto3
import os
os.environ['MPLCONFIGDIR'] = "/tmp/graph"
import re
import io
import base64
from datetime import datetime, timedelta
import smtplib
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText
from email.mime.base import MIMEBase
from email import encoders
from botocore.exceptions import NoCredentialsError, PartialCredentialsError

# Configuration
CURRENT_DATE = datetime.now().strftime('%a %d %b %Y')
SENDER = "donotreply@cjsm.secure-email.ppud.justice.gov.uk"
RECIPIENTS = ["nick.buckingham@colt.net", "gabriela.browning@colt.net", "pankaj.pant@colt.net", "david.savage@colt.net"]
SUBJECT = f'AWS PPUD Disk Information Report - {CURRENT_DATE}'
AWS_REGION = 'eu-west-2'
bucket_name = 'moj-lambda-layers-prod'
file_key = 'all-disks.log'

# SMTP Configuration
SMTP_SERVER = "10.27.9.39"
SMTP_PORT = 25

# Initialize boto3 client
s3 = boto3.client('s3')
cloudwatch = boto3.client("cloudwatch", region_name=AWS_REGION)
ses = boto3.client("ses")

def retrieve_file_from_s3(bucket, key):
    response = s3.get_object(Bucket=bucket, Key=key)
    content = response['Body'].read().decode('utf-8')
    return content

def parse_disk_info(content):
    disk_info_pattern = re.compile(
        r"Hostname\s+:\s+(.+)\n"
        r"Current Date\s+:\s+(.+)\n"
        r"Drive Letter\s+:\s+(.+)\n"
        r"Drive Label\s+:\s*(.*)\n"
        r"File System Type\s+:\s+(.+)\n"
        r"Total Capacity \(GB\)\s+:\s+(.+)\n"
        r"Used Capacity \(GB\)\s+:\s+(.+)\n"
        r"Total Free Space \(GB\)\s+:\s+(.+)\n"
        r"% Free Space\s+:\s+(.+)\n"
        r"Status\s+:\s+(.+)"
    )
    matches = disk_info_pattern.findall(content)
    return matches

def format_disk_info(disk_info):
    # Sort disk_info to place the C drive first
    sorted_disk_info = sorted(disk_info, key=lambda x: (x[2] != 'C', x))
    
    formatted_info = """<table border="1" style="border-collapse: collapse; width: 100%;">
                        <tr style="background-color: #f2f2f2;">
                            <th style="padding: 8px; text-align: left;">Server</th>
                            <th style="padding: 8px; text-align: left;">Date</th>
                            <th style="padding: 8px; text-align: left;">Drive</th>
                            <th style="padding: 8px; text-align: left;">Drive Label</th>
                            <th style="padding: 8px; text-align: left;">File System</th>
                            <th style="padding: 8px; text-align: left;">Total Capacity (GB)</th>
                            <th style="padding: 8px; text-align: left;">Used Capacity (GB)</th>
                            <th style="padding: 8px; text-align: left;">Free Space (GB)</th>
                            <th style="padding: 8px; text-align: left;">% Free Space</th>
                            <th style="padding: 8px; text-align: left;">Status</th>
                        </tr>"""

    current_hostname = None
    for info in sorted_disk_info:
        if current_hostname != info[0]:
            if current_hostname is not None:
                formatted_info += f"""<tr><td colspan="10" style="height: 20px;"></td></tr>"""
            current_hostname = info[0]
    
        status = info[9].strip().capitalize()
        status_color = {
            'Good': 'green',
            'Low': 'teal',
            'Warning': 'orange',
            'Critical': 'red'
        }.get(status, 'black')

        formatted_info += f"""<tr>
                                <td style="padding: 8px; text-align: left;">{info[0]}</td>
                                <td style="padding: 8px; text-align: left;">{info[1]}</td>
                                <td style="padding: 8px; text-align: left;">{info[2]}</td>
                                <td style="padding: 8px; text-align: left;">{info[3]}</td>
                                <td style="padding: 8px; text-align: left;">{info[4]}</td>
                                <td style="padding: 8px; text-align: left;">{info[5]}</td>
                                <td style="padding: 8px; text-align: left;">{info[6]}</td>
                                <td style="padding: 8px; text-align: left;">{info[7]}</td>
                                <td style="padding: 8px; text-align: left;">{info[8]}</td>
                                <td style="padding: 8px; text-align: left; background-color: {status_color};">{info[9]}</td>
                              </tr>"""
    formatted_info += "</table>"
    return formatted_info

def send_email(subject, body_html):
    msg = MIMEMultipart()
    msg['From'] = SENDER
    msg['To'] = ', '.join(RECIPIENTS)
    msg['Subject'] = SUBJECT

    msg.attach(MIMEText(body_html, 'html'))

    with smtplib.SMTP(SMTP_SERVER, SMTP_PORT) as server:
      #  server.starttls()
      #  server.login(smtp_username, smtp_password)
        server.send_message(msg)

def lambda_handler(event, context):
    # Retrieve file from S3
    content = retrieve_file_from_s3(bucket_name, file_key)
    
    # Parse disk information
    disk_info = parse_disk_info(content)
    
    # Format disk information
    formatted_info = format_disk_info(disk_info)

    # Get current date
    CURRENT_DATE = datetime.now().strftime('%a %d %b %Y')

    # Email formatted disk information
    subject = 'AWS PPUD Disk Information Report - {CURRENT_DATE}'
    body_html = f"""<html>
    <head></head>
    <body>
      <p>Hi Team</p>
      <p></p>
      <p>Please find below the PPUD disk information report.</p>
      <p>{formatted_info}</p>
	  <p>This is an automated email</p>
    </body>
    </html>"""

    send_email(subject, body_html)
    
    return {
        'statusCode': 200,
        'body': 'Email sent successfully!'
    }
