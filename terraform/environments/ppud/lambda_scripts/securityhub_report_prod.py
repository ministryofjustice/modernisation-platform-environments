import boto3
import smtplib
from datetime import datetime
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText

# Initialize boto3 clients
securityhub = boto3.client('securityhub')

# Configuration
CURRENT_DATE = datetime.now().strftime('%a %d %b %Y')
SENDER = 'donotreply@cjsm.secure-email.ppud.justice.gov.uk'
RECIPIENTS = ['nick.buckingham@colt.net']
SUBJECT = f'AWS Security Hub - Critical Vulnerabilities - {CURRENT_DATE}'
SMTP_SERVER = "10.27.9.39"
SMTP_PORT = 25

def check_critical_vulnerabilities():
    findings = []
    paginator = securityhub.get_paginator('get_findings')
    response_iterator = paginator.paginate(
        Filters={
            'WorkflowState': [{'Value': 'NEW', 'Comparison': 'EQUALS'}],
            'RecordState': [{'Value': 'ACTIVE', 'Comparison': 'EQUALS'}],
            'Region': [{'Value': 'eu-west-2', 'Comparison': 'EQUALS'}],
            'SeverityLabel': [{'Value': 'CRITICAL', 'Comparison': 'EQUALS'}]
        }
    )
    
    for page in response_iterator:
        findings.extend(page['Findings'])
        
    return findings

def format_findings(findings):
    formatted_findings = """
    <html>
    <head></head>
    <body>
      <p>Hi Team</p>
      <p></p>
      <p>Please find below the current AWS Security Hub Critical Vulnerabilities.</p>
      <table border="1" style="border-collapse: collapse; width: 100%;">
        <tr style="background-color: #f2f2f2;">
            <th style="padding: 12px; text-align: left;">Title</th>
            <th style="padding: 12px; text-align: left;">Description</th>
            <th style="padding: 12px; text-align: left;">Resources</th>
        </tr>
    """

    for finding in findings:
        title = finding.get('Title', 'N/A')
        description = finding.get('Description', 'N/A')
        resources = ', '.join([res['Id'] for res in finding.get('Resources', [])])

        formatted_findings += f"""
        <tr>
            <td style="padding: 12px; text-align: left;">{title}</td>
            <td style="padding: 12px; text-align: left;">{description}</td>
            <td style="padding: 12px; text-align: left;">{resources}</td>
        </tr>
        """
    
    formatted_findings += """
      </table>
      <p>This is an automated email.</p>
    </body>
    </html>
    """
    return formatted_findings

def send_email(subject, body_html):
    msg = MIMEMultipart()
    msg['From'] = SENDER
    msg['To'] = ', '.join(RECIPIENTS)
    msg['Subject'] = subject

    msg.attach(MIMEText(body_html, 'html'))

    with smtplib.SMTP(SMTP_SERVER, SMTP_PORT) as server:
      #  server.starttls()
      #  server.login(smtp_username, smtp_password)
        server.send_message(msg)

def lambda_handler(event, context):
    # Check for critical vulnerabilities
    findings = check_critical_vulnerabilities()

    if findings:
        # Format the findings into HTML
        formatted_findings = format_findings(findings)

        # Email the findings
        subject = SUBJECT
        body_html = formatted_findings

        send_email(subject, body_html)

        return {
            'statusCode': 200,
            'body': 'Email sent successfully with critical vulnerabilities!'
        }
    else:
        return {
            'statusCode': 200,
            'body': 'No critical vulnerabilities found!'
        }
