#!/usr/bin/env bash

# Install Graphviz (Required by MCP: awslabs.aws-diagram-mcp-server)
sudo apt-get update
sudo apt-get install --yes graphviz
sudo apt-get clean --yes
sudo rm --force --recursive /var/lib/apt/lists/*
