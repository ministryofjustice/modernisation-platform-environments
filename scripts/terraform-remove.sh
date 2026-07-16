#!/bin/bash
set -e
set -o pipefail

# Script for removing resources from Terraform state
# Usage: scripts/terraform-remove.sh <terraform_dir> <addresses_file>

TERRAFORM_DIR=$1
ADDRESSES_FILE=$2

if [ ! -d "$TERRAFORM_DIR" ]; then
  echo "Error: Terraform directory '$TERRAFORM_DIR' not found"
  exit 1
fi

if [ ! -f "$ADDRESSES_FILE" ]; then
  echo "Error: Resource addresses file '$ADDRESSES_FILE' not found"
  exit 1
fi

# Process each resource address
while IFS= read -r ADDRESS; do
  # Skip empty lines
  if [ -z "$ADDRESS" ]; then
    continue
  fi
  echo "Removing from state: $ADDRESS"
  terraform -chdir="$TERRAFORM_DIR" state rm "$ADDRESS" | ./scripts/redact-output.sh
done < "$ADDRESSES_FILE"

echo "State removal operation completed successfully"