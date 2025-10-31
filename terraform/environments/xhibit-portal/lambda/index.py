import boto3
from datetime import datetime


def lambda_handler(event, context):
    today = datetime.now()
    date_time = today.date()

    format_time = today.strftime("%m/%d/%Y")
    root_snapshots = [
        "root-block-device-portal-xhibit-portal",
        "root-block-device-app-xhibit-portal",
        "root-block-device-infra2-xhibit-portal",
        "root-block-device-sms-server-xhibit-portal",
        "root-block-device-database-xhibit-portal",
        "root-block-device-cjim-xhibit-portal",
        "root-block-device-infra1-xhibit-portal",
        "root-block-device-exchange-server-xhibit-portal",
        "root-block-device-cjip-xhibit-portal",
        "root-block-device-baremetal-xhibit-portal",
        "root-block-device-importmachine-xhibit-portal",
    ]
    print("Connecting to EC2")
    client = boto3.client("ec2")
    print("Root block snapshot to ami process started at %s...\n" % datetime.now())
    for element in root_snapshots:
        print(element)
        response = client.describe_snapshots(
            OwnerIds=["self"], Filters=[{"Name": "tag:Name", "Values": [element]}]
        )
        for snapshot in response["Snapshots"]:
            if snapshot["StartTime"].date() == date_time:
                description = snapshot["Description"]
                if "Create" in description:
                    snapshot_id = snapshot["SnapshotId"]
                    snapshot_volume_size = snapshot["VolumeSize"]
                    # create a AMI from snapshot
                    image = client.register_image(
                        BlockDeviceMappings=[
                            {
                                "DeviceName": "/dev/sda1",
                                "Ebs": {
                                    "DeleteOnTermination": True,
                                    "SnapshotId": snapshot_id,
                                    "VolumeSize": snapshot_volume_size,
                                    "VolumeType": "gp2",
                                },
                            },
                        ],
                        Description="AMI created from snapshot "
                        + snapshot_id
                        + " using a custom Lambda",
                        Name=element + "-" + format_time,
                        RootDeviceName="/dev/sda1",
                        VirtualizationType="hvm",
                    )
                    # print the resource ID of created EBS volume
                    print(f"AMI created: {image}")
