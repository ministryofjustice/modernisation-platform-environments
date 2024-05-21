import boto3
from datetime import datetime

ec2 = boto3.client('ec2', 'eu-west-2')
paginator = ec2.get_paginator('describe_snapshots')
page_iterator = paginator.paginate(OwnerIds=['self'])

def lambda_handler(event, context):
    count = 0
    for page in page_iterator:
        for snapshot in page['Snapshots']:
            a = snapshot['StartTime']
            b = a.date()
            c = datetime.now().date()
            d = c-b
            try:
                if d.days > 35 and "automatically created snapshot" in snapshot['Description']:
                    id = snapshot['SnapshotId']
                    print("Found an automatically created snapshot older than 35 days", id)
                    ec2.delete_snapshot(SnapshotId=id)
                    count += 1
            except Exception as e:
                print(e)
                if 'InvalidSnapshot.InUse' in str(e):
                    print("skipping this snapshot")
                    continue
    print(f"Deleted a total of {count} snapshots")