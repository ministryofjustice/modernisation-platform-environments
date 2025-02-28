#!/bin/bash
set -e

# Script for importing resources into Terraform state
# Usage: scripts/terraform-import.sh <terraform_dir> <addresses_file> <ids_file>

TERRAFORM_DIR=$1
ADDRESSES_FILE=$2
IDS_FILE=$3

if [ ! -d "$TERRAFORM_DIR" ]; then
  echo "Error: Terraform directory '$TERRAFORM_DIR' not found"
  exit 1
fi

if [ ! -f "$ADDRESSES_FILE" ]; then
  echo "Error: Resource addresses file '$ADDRESSES_FILE' not found"
  exit 1
fi

if [ ! -f "$IDS_FILE" ]; then
  echo "Error: Resource IDs file '$IDS_FILE' not found"
  exit 1
fi

# Get arrays of addresses and IDs
mapfile -t ADDRESSES < "$ADDRESSES_FILE"
mapfile -t IDS < "$IDS_FILE"

# Check array lengths
if [ ${#ADDRESSES[@]} -ne ${#IDS[@]} ]; then
  echo "Error: Number of resource addresses (${#ADDRESSES[@]}) doesn't match number of resource IDs (${#IDS[@]})"
  exit 1
fi

# Process each resource
for i in "${!ADDRESSES[@]}"; do
  ADDRESS="${ADDRESSES[$i]}"
  ID="${IDS[$i]}"
  
  # Skip empty lines
  if [ -z "$ADDRESS" ] || [ -z "$ID" ]; then
    continue
  fi
  
  echo "Importing: $ADDRESS ($ID)"
  terraform -chdir="$TERRAFORM_DIR" import "$ADDRESS" "$ID" | ./scripts/redact-output.sh
done

echo "Import operation completed successfully"