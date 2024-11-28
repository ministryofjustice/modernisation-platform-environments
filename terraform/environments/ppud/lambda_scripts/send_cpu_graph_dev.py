import boto3
import datetime
import os
os.environ['MPLCONFIGDIR'] = "/tmp/graph"
import matplotlib.pyplot as plt
import io
import base64
from botocore.exceptions import ClientError

# Initialize clients
cloudwatch = boto3.client('cloudwatch')
ses = boto3.client('ses')

def lambda_handler(event, context):
    # 1. Define parameters
    instance_id = event.get('InstanceId', 'i-0c98db0c20242e12c')  # Replace with your instance ID
    email_recipient = event.get('RecipientEmail', 'nick.buckingham@colt.net')  # Replace with recipient email
    email_sender = 'noreply@internaltest.ppud.justice.gov.uk'  # Replace with a verified SES sender email
    region = 'eu-west-2'  # Replace with your AWS region

    # 2. Fetch CPU Utilization data from CloudWatch
    try:
        response = cloudwatch.get_metric_data(
            MetricDataQueries=[
                {
                    'Id': 'cpuUtilization',
                    'MetricStat': {
                        'Metric': {
                            'Namespace': 'AWS/EC2',
                            'MetricName': 'CPUUtilization',
                            'Dimensions': [{'Name': 'InstanceId', 'Value': instance_id}]
                        },
                        'Period': 300,  # 5 minutes
                        'Stat': 'Average'
                    },
                    'ReturnData': True
                }
            ],
            StartTime=datetime.datetime.utcnow() - datetime.timedelta(hours=168),
            EndTime=datetime.datetime.utcnow()
        )
    except ClientError as e:
        print(f"Error fetching CloudWatch data: {e}")
        return {'statusCode': 500, 'body': str(e)}

    # 3. Process data for graphing
    timestamps = []
    values = []
    for data_point in response['MetricDataResults'][0]['Timestamps']:
        timestamps.append(data_point)
    for data_point in response['MetricDataResults'][0]['Values']:
        values.append(data_point)

    # Sort data by timestamps
    sorted_data = sorted(zip(timestamps, values))
    timestamps, values = zip(*sorted_data)

    # 4. Generate a graph
    plt.figure(figsize=(10, 6))
    plt.plot(timestamps, values, label="CPU Utilization", marker='o')
    plt.xlabel('Time')
    plt.ylabel('CPU Utilization (%)')
    plt.title(f'CPU Utilization for {instance_id}')
    plt.legend()
    plt.grid(True)

    # Save the graph to memory
    image_buffer = io.BytesIO()
    plt.savefig(image_buffer, format='png')
    image_buffer.seek(0)

    # Convert to base64 for email attachment
    graph_base64 = base64.b64encode(image_buffer.getvalue()).decode('utf-8')
    image_buffer.close()

    # 5. Send the email via SES
    email_subject = f"CPU Utilization Graph for {instance_id}"
    email_body = (
        f"Attached is the CPU Utilization graph for the EC2 instance {instance_id} "
        f"for the past week. \n\nBest regards,\nYour Monitoring Team"
    )

    email_html_body = (
        f"<html><body><p>{email_body}</p><img src='data:image/png;base64,{graph_base64}'/></body></html>"
    )

    try:
        ses.send_email(
            Source=email_sender,
            Destination={'ToAddresses': [email_recipient]},
            Message={
                'Subject': {'Data': email_subject},
                'Body': {
                    'Html': {'Data': email_html_body}
                }
            }
        )
        print(f"Email sent successfully to {email_recipient}")
    except ClientError as e:
        print(f"Error sending email: {e}")
        return {'statusCode': 500, 'body': str(e)}

    return {'statusCode': 200, 'body': 'Email sent successfully'}
