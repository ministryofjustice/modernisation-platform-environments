#!/bin/bash

type aws >/dev/null 2>&1 || { echo >&2 "aws cli needs to be installed"; exit 2; }
type jq >/dev/null 2>&1 || { echo >&2 "jq is not installed"; exit 2; }

SNAPSHOTS="$(aws ec2 describe-snapshots --owner-ids self | jq -r '.Snapshots[].SnapshotId')"

printf "Enter account ID to share snapshots with: "
read -r ACCOUNT_ID

for i in $SNAPSHOTS
  do aws ec2 modify-snapshot-attribute --snapshot-id $i --attribute createVolumePermission --operation-type add --user-ids $ACCOUNT_ID
  echo "Shared $i with $ACCOUNT_ID!"
done