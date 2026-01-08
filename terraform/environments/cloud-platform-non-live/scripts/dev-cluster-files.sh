#!/bin/bash

set -euo pipefail

# Script to copy cluster configuration folders to a temporary directory
# Usage: ./dev-cluster-files.sh [cluster-name]

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE_DIR="$(dirname "$SCRIPT_DIR")"
TMP_DIR="${BASE_DIR}/tmp"
CLUSTER_NAME="${1:-cp-$(date +%d%m-%H%M)}"

# Create temporary directory if it doesn't exist
mkdir -p "$TMP_DIR"

# List of folders to copy
FOLDERS=(
    "network"
    "cluster"
    "cluster-core"
    "cluster-components"
)

# Copy each folder to the temporary directory
for folder in "${FOLDERS[@]}"; do
    if [ -d "${BASE_DIR}/${folder}" ]; then
        echo "Copying ${folder} to ${TMP_DIR}/"
        cp -r "${BASE_DIR}/${folder}" "$TMP_DIR/"
        
        # Modify platform_backend.tf if it exists in the folder
        if [ -f "${TMP_DIR}/${folder}/platform_backend.tf" ]; then
            echo "Updating ${folder}/platform_backend.tf with cluster-specific values..."
            sed -i.bak "s/bucket *= *\".*\"/bucket               = \"development-clusters-terraform-state20251223114024319400000001\"/" "${TMP_DIR}/${folder}/platform_backend.tf"
            sed -i.bak "s|workspace_key_prefix *= *\".*\"|workspace_key_prefix = \"${folder}\"|" "${TMP_DIR}/${folder}/platform_backend.tf"
            rm -f "${TMP_DIR}/${folder}/platform_backend.tf.bak"
        fi
    else
        echo "Warning: ${folder} does not exist, skipping..."
    fi
done

echo "Copy complete. Files copied to ${TMP_DIR}"