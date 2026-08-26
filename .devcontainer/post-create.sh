#!/usr/bin/env bash

# Install Graphviz (Required by MCP: awslabs.aws-diagram-mcp-server)
sudo apt-get update
sudo apt-get install --yes graphviz
sudo apt-get clean --yes
sudo rm --force --recursive /var/lib/apt/lists/*

# Install yq
# shellcheck source=/dev/null
# /usr/local/bin/devcontainer-utils is not accessible from GitHub Actions
source /usr/local/bin/devcontainer-utils
get_system_architecture
get_github_latest_tag "mikefarah/yq"
curl --location "https://github.com/mikefarah/yq/releases/download/${GITHUB_LATEST_TAG}/yq_linux_${ARCHITECTURE}" \
  --output /tmp/yq
sudo install --owner=vscode --group=vscode --mode=775 /tmp/yq /usr/local/bin/yq
rm --force /tmp/yq
