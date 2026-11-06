import logging
import os
from datetime import datetime, timezone
from typing import Any

import boto3
from botocore.exceptions import ClientError

AWS_REGION = os.getenv("AWS_REGION", "eu-west-2")
RETENTION_DAYS = int(os.getenv("RETENTION_DAYS", "35"))
DESCRIPTION_MATCH = "automatically created snapshot"


logger = logging.getLogger()
logger.setLevel(logging.INFO)


ec2 = boto3.client("ec2", region_name=AWS_REGION)


def lambda_handler(event: dict[str, Any], context: Any) -> dict[str, int]:
    """
    Delete EBS snapshots older than RETENTION_DAYS whose description contains
    DESCRIPTION_MATCH.
    """

    deleted_count = 0
    current_time = datetime.now(timezone.utc)

    paginator = ec2.get_paginator("describe_snapshots")

    for page in paginator.paginate(OwnerIds=["self"]):
        for snapshot in page.get("Snapshots", []):
            snapshot_id = snapshot.get("SnapshotId")
            description = snapshot.get("Description", "")
            start_time = snapshot.get("StartTime")

            if not snapshot_id or not start_time:
                logger.warning(
                    "Skipping snapshot with missing required fields: %s.",
                    snapshot,
                )
                continue

            age_days = (current_time - start_time).days

            if (
                age_days <= RETENTION_DAYS
                or DESCRIPTION_MATCH not in description.lower()
            ):
                continue

            logger.info(
                "Found snapshot eligible for deletion: %s (age=%s days).",
                snapshot_id,
                age_days,
            )

            try:
                ec2.delete_snapshot(SnapshotId=snapshot_id)
                deleted_count += 1

                logger.info(
                    "Deleted snapshot %s.",
                    snapshot_id,
                )

            except ClientError as error:
                error_code = error.response.get("Error", {}).get("Code", "")

                if error_code == "InvalidSnapshot.InUse":
                    logger.info(
                        "Snapshot %s is in use. Skipping.",
                        snapshot_id,
                    )
                    continue

                logger.exception(
                    "Failed to delete snapshot %s.",
                    snapshot_id,
                )

    logger.info(
        "Deleted a total of %s snapshots older than %s days.",
        deleted_count,
        RETENTION_DAYS,
    )

    return {
        "deleted_snapshots": deleted_count,
    }
