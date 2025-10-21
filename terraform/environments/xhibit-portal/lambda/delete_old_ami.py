import boto3
import botocore
from datetime import datetime, timedelta
from dateutil import parser
import os

def lambda_handler(event=None, context=None):
    dry_run = os.getenv("DRY_RUN", "false").lower() == "true"
    today = datetime.utcnow()
    deletion_date = today.date() - timedelta(days=122)
    ec2 = boto3.client("ec2", region_name="eu-west-2")

    print(f"AMI Filtering process started at {today}...")

    # AMI deletion tracking
    ami_deleted = 0
    ami_failed = 0

    try:
        images = ec2.describe_images(Owners=["self"])["Images"]
        print(f"Found {len(images)} AMIs.")
    except botocore.exceptions.ClientError as e:
        print(f"Error fetching AMIs: {e}")
        return

    for image in images:
        creation_date = parser.parse(image["CreationDate"]).date()
        image_id = image["ImageId"]
        if creation_date < deletion_date:
            try:
                instances = ec2.describe_instances(Filters=[{"Name": "image-id", "Values": [image_id]}])
                if not instances["Reservations"]:
                    print(f"{'Dry-run: ' if dry_run else ''}Deleting AMI: {image_id}")
                    if not dry_run:
                        ec2.deregister_image(ImageId=image_id)
                    ami_deleted += 1
                else:
                    ami_failed += 1
            except botocore.exceptions.ClientError as e:
                print(f"Error deleting AMI {image_id}: {e}")
                ami_failed += 1

    print("Checking Snapshots...")
    paginator = ec2.get_paginator("describe_snapshots")

    backup_managed_count = 0
    in_use_count = 0
    other_error_count = 0
    older_snapshots = 0
    younger_snapshots = 0
    snapshot_deleted = 0
    snapshot_failed = 0
    snapshot_ami_map = {}

    evidence_backup = []
    evidence_in_use = []
    evidence_other = []

    # Build AMI snapshot map
    ami_snapshot_ids = {
        bdm["Ebs"]["SnapshotId"]: image["ImageId"]
        for image in images
        for bdm in image.get("BlockDeviceMappings", [])
        if "Ebs" in bdm and "SnapshotId" in bdm["Ebs"]
    }

    for page in paginator.paginate(OwnerIds=["self"]):
        for snapshot in page["Snapshots"]:
            snap_id = snapshot["SnapshotId"]
            snap_date = snapshot["StartTime"].date()
            description = snapshot.get("Description", "").lower()
            tags = snapshot.get("Tags", [])
            if not isinstance(tags, list):
                tags = []

             # Check the AWS Backup service managed snapshots for skipping them
            is_backup_managed = (
                "aws backup" in description or
                "created by the aws backup service" in description or
                any(isinstance(tag, dict) and tag.get("Key") == "aws:backup:source-resource" for tag in tags)
            )

            if is_backup_managed:
                backup_managed_count += 1
                if len(evidence_backup) < 5:
                    evidence_backup.append(f"{snap_id}: {description}")
                continue

            if snap_date < deletion_date:
                older_snapshots += 1
                if snap_id in ami_snapshot_ids:
                    snapshot_ami_map[snap_id] = ami_snapshot_ids[snap_id]
                try:
                    print(f"{'Dry-run: ' if dry_run else ''}Deleting Snapshot: {snap_id}")
                    if not dry_run:
                        ec2.delete_snapshot(SnapshotId=snap_id)
                    snapshot_deleted += 1
                except botocore.exceptions.ClientError as e:
                    error_msg = str(e)
                    snapshot_failed += 1
                    if "is currently in use by" in error_msg:
                        in_use_count += 1
                        if len(evidence_in_use) < 5:
                            evidence_in_use.append(f"{snap_id}: {error_msg}")
                    else:
                        other_error_count += 1
                        if len(evidence_other) < 5:
                            evidence_other.append(f"{snap_id}: {error_msg}")
            else:
                younger_snapshots += 1

    print("\nSnapshots older than 122 days and assigned to AMIs (max 10):")
    for i, (snap_id, ami_id) in enumerate(snapshot_ami_map.items()):
        if i >= 10:
            break
        print(f"{snap_id} -> {ami_id}")

    # Final stats
    print("\nSummary Statistics:")
    print(f"Total AMIs deleted: {ami_deleted}")
    print(f"Total AMIs failed to delete: {ami_failed}")
    print(f"Total EC2 Snapshots older than 122 days: {older_snapshots}")
    print(f"Total EC2 Snapshots younger than 122 days: {younger_snapshots}")
    print(f"Total EC2 Snapshots deleted: {snapshot_deleted}")
    print(f"Total EC2 Snapshots failed to delete: {snapshot_failed}")
    print(f"Total Snapshots managed by AWS Backup service: {backup_managed_count}")
    print(f"Total Snapshots in use by AMIs: {in_use_count}")
    print(f"Total Snapshots failed due to other errors: {other_error_count}")

    print("\nEvidence - AWS Backup Managed Snapshots:")
    for evidence in evidence_backup:
        print(evidence)

    print("\nEvidence - Snapshots In Use:")
    for evidence in evidence_in_use:
        print(evidence)

    print("\nEvidence - Other Errors:")
    for evidence in evidence_other:
        print(evidence)

# Example usage:
# lambda_handler(dry_run=True)
