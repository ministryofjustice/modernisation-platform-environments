import boto3
import os
os.environ['MPLCONFIGDIR'] = "/tmp/graph"
import matplotlib.pyplot as plt
from datetime import datetime, timedelta
import io
import base64
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText

# Initialize boto3 clients
cloudwatch = boto3.client('cloudwatch')

# Configuration
current_date = datetime.now().strftime('%a %d %b %Y')
INSTANCE_ID = "i-029d2b17679dab982"
start_time = datetime(2024, 12, 4, 8, 0, 0)
end_time = datetime(2024, 12, 4, 17, 0, 0)
SENDER = "donotreply@cjsm.secure-email.ppud.justice.gov.uk"
RECIPIENTS = ["nick.buckingham@colt.net"]
SUBJECT = f'EC2 CPU Utilization Report - {current_date}'
REGION = "eu-west-2"
IMAGE_ID = "ami-02f8251c8cdf2464f"
INSTANCE_TYPE = "m5.xlarge"

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
        StartTime=start_time,
        EndTime=end_time
    )
    return response['MetricDataResults'][0]

def create_graph(cpu_data, converttopdf_data, pdfcrawler2app_data, winword_data, wmiprvse_data, createthumbnails_data):
    plt.figure(figsize=(20, 5))
    plt.plot(cpu_data['Timestamps'], cpu_data['Values'], label='Total Server CPU Utilization', marker="o", linestyle="-", color="teal")
    plt.plot(converttopdf_data['Timestamps'], converttopdf_data['Values'], label='Convert to PDF CPU Utilization', marker="o", linestyle="--", color="royalblue")
    plt.plot(pdfcrawler2app_data['Timestamps'], pdfcrawler2app_data['Values'], label='PDF Crawler CPU Utilization',  marker="o", linestyle="--", color="cyan")
    plt.plot(winword_data['Timestamps'], winword_data['Values'], label='Microsoft Word CPU Utilization',  marker="o", linestyle="--", color="orange")
    plt.plot(wmiprvse_data['Timestamps'], wmiprvse_data['Values'], label='WMIPrvSE CPU Utilization',  marker="o", linestyle="--", color="red")
    plt.plot(createthumbnails_data['Timestamps'], createthumbnails_data['Values'], label='Create Thumbnails CPU Utilization',  marker="o", linestyle="--", color="springgreen")
    plt.xlabel('Time')
    plt.ylabel('CPU Utilization (%)')
    plt.title(f'EC2 CPU Utilization - {INSTANCE_ID} - {current_date}')
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
        <p>Please find below the CPU utilization metrics for EC2 instance {INSTANCE_ID} for today from 08:00 to 17:00.</p>
        <img src="data:image/png;base64,{graph_base64}" alt="CPU Utilization Graph" />
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
    cpu_data = get_metric_data('AWS/EC2', 'CPUUtilization', [{'Name': 'InstanceId', 'Value': INSTANCE_ID}])
    converttopdf_data = get_metric_data('CWAgent', 'procstat cpu_usage', [{'Name': 'InstanceId', 'Value': INSTANCE_ID}, {'Name': 'process_name', 'Value': 'converttopdf.exe'}, {'Name': 'exe', 'Value': 'converttopdf'}, {'Name': 'ImageId', 'Value': IMAGE_ID}, {'Name': 'InstanceType', 'Value': INSTANCE_TYPE}])
    pdfcrawler2app_data = get_metric_data('CWAgent', 'procstat cpu_usage', [{'Name': 'InstanceId', 'Value': INSTANCE_ID}, {'Name': 'process_name', 'Value': 'pdfcrawler2app.exe'}, {'Name': 'exe', 'Value': 'pdfcrawler2app'}, {'Name': 'ImageId', 'Value': IMAGE_ID}, {'Name': 'InstanceType', 'Value': INSTANCE_TYPE}])
    winword_data = get_metric_data('CWAgent', 'procstat cpu_usage', [{'Name': 'InstanceId', 'Value': INSTANCE_ID}, {'Name': 'process_name', 'Value': 'winword.exe'}, {'Name': 'exe', 'Value': 'winword'}, {'Name': 'ImageId', 'Value': IMAGE_ID}, {'Name': 'InstanceType', 'Value': INSTANCE_TYPE}])
    wmiprvse_data = get_metric_data('CWAgent', 'procstat cpu_usage', [{'Name': 'InstanceId', 'Value': INSTANCE_ID}, {'Name': 'process_name', 'Value': 'wmiprcse.exe'}, {'Name': 'exe', 'Value': 'wmiprcse'}, {'Name': 'ImageId', 'Value': IMAGE_ID}, {'Name': 'InstanceType', 'Value': INSTANCE_TYPE}])
    createthumbnails_data = get_metric_data('CWAgent', 'procstat cpu_usage', [{'Name': 'InstanceId', 'Value': INSTANCE_ID}, {'Name': 'process_name', 'Value': 'createthumbnails.exe'}, {'Name': 'exe', 'Value': 'createthumbnails'}, {'Name': 'ImageId', 'Value': IMAGE_ID}, {'Name': 'InstanceType', 'Value': INSTANCE_TYPE}])

    # Create a graph and encode it as base64
    print("Creating graph...")
    graph_base64 = create_graph(cpu_data, converttopdf_data, pdfcrawler2app_data, winword_data, wmiprvse_data, createthumbnails_data)

    # Send email with the graph embedded
    print("Sending email...")
    #email_image_to_users(graph_image.getvalue())
    email_image_to_users(graph_base64)

    return {
        'statusCode': 200,
        'body': 'Graph uploaded to S3 successfully!'
    }
