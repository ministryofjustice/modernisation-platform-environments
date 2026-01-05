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
        
        # Modify network/locals.tf if this is the network folder
        if [ "$folder" = "network" ] && [ -f "${TMP_DIR}/network/locals.tf" ]; then
            echo "Updating network/locals.tf with cluster-specific values..."
            sed -i.bak "s/cluster_environment = .*/cluster_environment = \"development_cluster\"/" "${TMP_DIR}/network/locals.tf"
            sed -i.bak "s|cp_vpc_name.*= .*|cp_vpc_name         = \"${CLUSTER_NAME}\"|" "${TMP_DIR}/network/locals.tf"
            rm -f "${TMP_DIR}/network/locals.tf.bak"
        fi
        
        # Modify cluster/locals.tf if this is the cluster folder
        if [ "$folder" = "cluster" ] && [ -f "${TMP_DIR}/cluster/locals.tf" ]; then
            echo "Updating cluster/locals.tf with cluster-specific values..."
            sed -i.bak "s/cluster_environment = .*/cluster_environment = \"development_cluster\"/" "${TMP_DIR}/cluster/locals.tf"
            sed -i.bak "s|cp_vpc_name.*= .*|cp_vpc_name         = \"${CLUSTER_NAME}\"|" "${TMP_DIR}/cluster/locals.tf"
            sed -i.bak "s|cluster_name.*= .*|cluster_name         = \"${CLUSTER_NAME}\"|" "${TMP_DIR}/cluster/locals.tf"
            rm -f "${TMP_DIR}/cluster/locals.tf.bak"
        fi
        
        # Modify platform_backend.tf if it exists in the folder
        if [ -f "${TMP_DIR}/${folder}/platform_backend.tf" ]; then
            echo "Updating ${folder}/platform_backend.tf with cluster-specific values..."
            sed -i.bak "s/bucket *= *\".*\"/bucket               = \"development-clusters-terraform-state20251223114024319400000001\"/" "${TMP_DIR}/${folder}/platform_backend.tf"
            sed -i.bak "s|key *= *\".*\"|key                  = \"${CLUSTER_NAME}/${folder}/terraform.tfstate\"|" "${TMP_DIR}/${folder}/platform_backend.tf"
            sed -i.bak "/workspace_key_prefix/d" "${TMP_DIR}/${folder}/platform_backend.tf"
            rm -f "${TMP_DIR}/${folder}/platform_backend.tf.bak"
        fi
    else
        echo "Warning: ${folder} does not exist, skipping..."
    fi
done

echo "Copy complete. Files copied to ${TMP_DIR}"