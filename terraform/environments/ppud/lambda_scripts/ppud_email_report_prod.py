import boto3
import os
os.environ['MPLCONFIGDIR'] = "/tmp/graph"
import matplotlib.pyplot as plt
import re
import io
import base64
from datetime import datetime, timedelta
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText

# Initialize boto3 clients
s3 = boto3.client('s3')
ses = boto3.client('ses')

# Configuration
CURRENT_DATE = datetime.now().strftime('%a %d %b %Y')
bucket_name = 'moj-lambda-layers-dev'
file_names = ['monday.log', 'tuesday.log', 'wednesday.log', 'thursday.log', 'friday.log', 'saturday.log', 'sunday.log']
SENDER = 'noreply@internaltest.ppud.justice.gov.uk'
RECIPIENTS = ['nick.buckingham@colt.net']
SUBJECT = f'AWS Weekly PPUD Email Report - {CURRENT_DATE}'
AWS_REGION = 'eu-west-2'

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

 #   buf = io.BytesIO()
 #   plt.savefig(buf, format='png')
 #   buf.seek(0)
 #   return buf.getvalue()

    # Save the graph to a temporary buffer
    temp_file = "/tmp/ppud_emails_send.png"
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
    ses_client = boto3.client("ses", region_name=AWS_REGION)

    # Email body with the embedded image
    email_body = f"""
    <html>
    <body>
        <p>Hi Team,</p>
        <p>Please find below the weekly PPUD Email Report.</p>
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

    # Send the email
    try:
        response = ses_client.send_raw_email(
            Source=SENDER,
            Destinations=RECIPIENTS,
            RawMessage={"Data": msg.as_string()},
        )
        print("Email sent! Message ID:", response["MessageId"])
    except Exception as e:
        print("Error sending email:", e)
        raise
		
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
