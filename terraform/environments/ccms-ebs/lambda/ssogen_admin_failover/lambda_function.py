"""
AWS Lambda function to pull CloudWatch Alarm from SNS Topic and
update the route 53 dnsname record for ssogen admin to secondary private ip
"""
import socket
import boto3
import os
import logging

logger = logging.getLogger()
logger.setLevel(logging.INFO)

PRIMARY_IP = os.environ['PRIMARY_IP']
SECONDARY_IP = os.environ['SECONDARY_IP']
PORT = int(os.environ['PORT'])
ZONE_ID = os.environ['HOSTED_ZONE_ID']
RECORD = os.environ['RECORD_NAME']

route53 = boto3.client("route53")

def check(ip, port):
    try:
        s = socket.create_connection((ip, port), timeout=3)
        s.close()
        return True
    except:
        return False

def update_dns(target_ip):
    route53.change_resource_record_sets(
        HostedZoneId=ZONE_ID,
        ChangeBatch={
            "Changes": [{
                "Action": "UPSERT",
                "ResourceRecordSet": {
                    "Name": RECORD,
                    "Type": "A",
                    "TTL": 30,
                    "ResourceRecords": [{"Value": target_ip}]
                }
            }]
        }
    )

def lambda_handler(event, context):
    if check(PRIMARY_IP, PORT):
        update_dns(PRIMARY_IP)
        return f"Primary healthy → Set DNS to {PRIMARY_IP}"
    elif check(SECONDARY_IP, PORT):
        update_dns(SECONDARY_IP)
        return f"Primary unhealthy → Secondary healthy → Set DNS to {SECONDARY_IP}"
    else:
        return "ERROR: Both primary and secondary are down!"