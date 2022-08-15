# We want to delete old ami/snapshots created by the index.py lambda function
import boto3
import botocore
from datetime import datetime, timedelta
from dateutil import parser


def lambda_handler(event, context):
    today = datetime.now()
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
                        snap_id = bdm.get("Ebs").get("SnapshotId")
                        try:
                            print(f"Deleting Snapshot {snap_id}")
                            client.delete_snapshot(SnapshotId=snap_id)
                        except botocore.exceptions.ClientError as e:
                            print(
                                f"Error deleting Snapshot {e.response['Error']['Message']}"
                            )
                            continue
                image_id = image["ImageId"]
                try:
                    print(f"Deleting Image {image_id}")
                    client.deregister_image(ImageId=image_id)
                except botocore.exceptions.ClientError as e:
                    print(
                        f"Error deleting AMI {e.response['Error']['Message']}")
                    continue
