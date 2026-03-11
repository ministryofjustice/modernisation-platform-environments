#!/bin/bash
set -euxo pipefail

export DEBIAN_FRONTEND=noninteractive

# Update package lists
apt-get update

# Upgrade installed packages
apt-get -y upgrade

# Ensure SSM agent is installed (usually already present on AWS Kali AMI)
if ! systemctl list-unit-files | grep -q amazon-ssm-agent; then
    snap install amazon-ssm-agent --classic || true
fi

# Enable and start SSM agent
systemctl enable amazon-ssm-agent || true
systemctl restart amazon-ssm-agent || true