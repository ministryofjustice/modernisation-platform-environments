# We want to delete old ami/snapshots created by the index.py lambda function
import boto3
from datetime import datetime, timedelta
from dateutil import parser


def lambda_handler(event, context):
    today = datetime.datetime.now()
    date_time = today.date()
    deletion_time = date_time - timedelta(days=122)
    client = boto3.client("ec2")
    print("AMI Filtering process started %s...\n" % datetime.now())
    image_response = client.describe_images(Owners=["self"])
    # Get all the images
    for image in image_response["Images"]:
        if parser.parse(image["CreationDate"]).date() < deletion_time:
            # Check if it's in use
            instance_response = client.describe_instances(
                Filters=[{"Name": "image-id", "Values": [image["ImageId"]]}]
            )
            if len(instance_response["Reservations"]) == 0:
                for bdm in image["BlockDeviceMappings"]:
                    # Ignore ephemeral bdm
                    if (
                        bdm.get("Ebs") is not None
                        and bdm.get("Ebs").get("SnapshotId") is not None
                    ):
                        try:
                            snap_id = bdm.get("Ebs").get("SnapshotId")
                            client.delete_snapshot(
                                SnapshotId=snap_id, dry_run=True)
                        except Exception as e:
                            if "InvalidSnapshot.InUse" in e.message:
                                print(f"Snapshot {id} in use")
                                continue
                try:
                    image_id = image["ImageId"]
                    client.deregister_image(ImageId=image_id, dry_run=True)
                except Exception as e:
                    print(f"Error deleting image: {e.message}")
                    continue
