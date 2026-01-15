import boto3
from datetime import datetime
from typing import Any, Dict

def lambda_handler(event: Dict[str, Any], context: Any) -> None:
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
    ec2_client = boto3.client("ec2")
    print(f"Root block snapshot to AMI process started at {datetime.now()}...\n")

    for tag_name in root_snapshots:
        print(f"Processing snapshot tag: {tag_name}")
        response = ec2_client.describe_snapshots(
            OwnerIds=["self"],
            Filters=[{"Name": "tag:Name", "Values": [tag_name]}]
        )

        for snapshot in response.get("Snapshots", []):
            snapshot_date = snapshot.get("StartTime").date()
            description = snapshot.get("Description", "")
            if snapshot_date == date_time and "Create" in description:
                snapshot_id = snapshot["SnapshotId"]
                volume_size = snapshot["VolumeSize"]

                # Register AMI from snapshot
                image_response = ec2_client.register_image(
                    BlockDeviceMappings=[
                        {
                            "DeviceName": "/dev/sda1",
                            "Ebs": {
                                "DeleteOnTermination": True,
                                "SnapshotId": snapshot_id,
                                "VolumeSize": volume_size,
                                "VolumeType": "gp2",
                            },
                        },
                    ],
                    Description=f"AMI created from snapshot {snapshot_id} using a custom Lambda",
                    Name=f"{tag_name}-{format_time}",
                    RootDeviceName="/dev/sda1",
                    VirtualizationType="hvm",
                )

                print(f"AMI created: {image_response}")
