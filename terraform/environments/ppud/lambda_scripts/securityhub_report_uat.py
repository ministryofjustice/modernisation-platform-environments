import boto3
import re
from datetime import datetime
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText

# Initialize boto3 clients
securityhub = boto3.client('securityhub')
ses = boto3.client('ses')

# Configuration
CURRENT_DATE = datetime.now().strftime('%a %d %b %Y')
SENDER = 'noreply@uat.ppud.justice.gov.uk'
RECIPIENTS = ['nick.buckingham@colt.net']
SUBJECT = f'AWS Security Hub - Critical Vulnerabilities Report - {CURRENT_DATE}'

# Function to obfuscate patterns in text
def obfuscate_text(text):
    patterns = [
        (r'(8\d{10}4)', '**********'), # Obfuscate Production
        (r'(0\d{10}6)', '**********'), # Obfuscate Dev
        (r'(1\d{10}0)', '**********')  # Obfuscate UAT
    ]
    
    for pattern, replacement in patterns:
        text = re.sub(pattern, lambda x: x.group(1)[0] + replacement + x.group(1)[-1], text)
    
    return text

# Functions to replace sensitive information with the obfuscated text

def obfuscate_account_number(resource_id):
    return re.sub(r'(1)(\w{10})(0)', r'\1**********\3', resource_id)

def obfuscate_instance_id(resource_id):
    return re.sub(r'(instance/i-0)(\w{13})', r'\1**************', resource_id)

def obfuscate_access_key(resource_id):
    return re.sub(r'(AccessKey:)(\w{12})', r'\1****************', resource_id)

def obfuscate_vpc(resource_id):
    return re.sub(r'(vpc/vpc-0)(\w{12})', r'\1****************', resource_id)

def obfuscate_network_interface(resource_id):
    return re.sub(r'(network-interface/eni-0)(\w{12})', r'\1****************', resource_id)

def obfuscate_networkinterface(resource_id):
    return re.sub(r'(networkinterface/eni-0)(\w{12})', r'\1****************', resource_id)

def obfuscate_load_balancer(resource_id):
    return re.sub(r'(loadbalancer/app.{7})(.{8})', r'\1********', resource_id)

def obfuscate_secret(resource_id):
    return re.sub(r'(secret:)(\w{8})', r'\1********', resource_id)

def obfuscate_security_group(resource_id):
    return re.sub(r'(security-group/sg-0)(\w{12})', r'\1************', resource_id)

def obfuscate_certificate_id(resource_id):
    return re.sub(r'(certificate/app.{9})(.{10})', r'\1**********', resource_id)

def obfuscate_role(resource_id):
    return re.sub(r'(role/)(\w{16})', r'\1****************', resource_id)

def obfuscate_volume(resource_id):
    return re.sub(r'(volume/vol-0)(\w{12})', r'\1************', resource_id)

# Function to obfuscate resources based on conditions
def obfuscate_resource(resource_id):
    resource_id = obfuscate_account_number(resource_id)
    resource_id = obfuscate_instance_id(resource_id)
    resource_id = obfuscate_access_key(resource_id)
    resource_id = obfuscate_vpc(resource_id)
    resource_id = obfuscate_network_interface(resource_id)
    resource_id = obfuscate_networkinterface(resource_id)
    resource_id = obfuscate_load_balancer(resource_id)
    resource_id = obfuscate_secret(resource_id)
    resource_id = obfuscate_security_group(resource_id)
    resource_id = obfuscate_certificate_id(resource_id)
    resource_id = obfuscate_role(resource_id)
    resource_id = obfuscate_volume(resource_id)
    return resource_id

def check_vulnerabilities():
    findings = []
    paginator = securityhub.get_paginator('get_findings')
    response_iterator = paginator.paginate(
        Filters={
            'WorkflowStatus': [{'Value': 'NEW', 'Comparison': 'EQUALS'}],
            'RecordState': [{'Value': 'ACTIVE', 'Comparison': 'EQUALS'}],
            'Region': [{'Value': 'eu-west-2', 'Comparison': 'EQUALS'}],
            'SeverityLabel': [
                {'Value': 'CRITICAL', 'Comparison': 'EQUALS'}
            ]
        }
    )

    for page in response_iterator:
        findings.extend(page['Findings'])

    # Sort findings by severity
    severity_order = {'CRITICAL': 1, 'HIGH': 2, 'MEDIUM': 3, 'LOW': 4}
    findings.sort(key=lambda x: severity_order.get(x['Severity']['Label'], 5))

    return findings

def format_findings(findings):
    formatted_findings = """
    <html>
    <head></head>
    <body>
      <p>Hi Team</p>
      <p></p>
      <p>Please find below the current PPUD AWS Security Hub Vulnerabilities.</p>
      <table border="1" style="border-collapse: collapse; width: 100%;">
        <tr style="background-color: #f2f2f2;">
            <th style="padding: 12px; text-align: left;">Title</th>
            <th style="padding: 12px; text-align: left;">Description</th>
            <th style="padding: 12px; text-align: left;">Resources</th>
            <th style="padding: 12px; text-align: left;">Workflow Status</th>
            <th style="padding: 12px; text-align: left;">Record State</th>
            <th style="padding: 12px; text-align: left;">Severity</th>
        </tr>
    """

    severity_colors = {
        'CRITICAL': 'color: purple;',
        'HIGH': 'color: red;',
        'MEDIUM': 'color: orange;',
        'LOW': 'color: teal;'
    }

    for finding in findings:
        title = obfuscate_text(finding.get('Title', 'N/A'))
        description = obfuscate_text(finding.get('Description', 'N/A'))
        resources = ', '.join([obfuscate_resource(res['Id']) for res in finding.get('Resources', [])])
        workflow = finding.get('WorkflowState', 'N/A')
        record = finding.get('RecordState', 'N/A')
        severity = finding.get('Severity', {}).get('Label', 'N/A')
        color = severity_colors.get(severity, '')

        formatted_findings += f"""
        <tr>
            <td style="padding: 12px; text-align: left;">{title}</td>
            <td style="padding: 12px; text-align: left;">{description}</td>
            <td style="padding: 12px; text-align: left;">{resources}</td>
            <td style="padding: 12px; text-align: left;">{workflow}</td>
            <td style="padding: 12px; text-align: left;">{record}</td>
            <td style="padding: 12px; text-align: left; {color}">{severity}</td>
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

    response = ses.send_raw_email(
        Source=SENDER,
        Destinations=RECIPIENTS,
        RawMessage={'Data': msg.as_string()}
    )

def lambda_handler(event, context):
    # Check for vulnerabilities
    findings = check_vulnerabilities()

    if findings:
        # Format the findings into HTML
        formatted_findings = format_findings(findings)

        # Email the findings
        subject = SUBJECT
        body_html = formatted_findings

        send_email(subject, body_html)

        return {
            'statusCode': 200,
            'body': 'Email sent successfully with vulnerabilities report!'
        }
    else:
        return {
            'statusCode': 200,
            'body': 'No vulnerabilities found!'
        }
