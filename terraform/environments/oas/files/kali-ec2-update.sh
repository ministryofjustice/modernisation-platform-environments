#!/bin/bash
set -euxo pipefail
exec > >(tee /var/log/user-data.log | logger -t user-data) 2>&1

export DEBIAN_FRONTEND=noninteractive

echo "Updating package lists..."
apt-get update -y

echo "Upgrading installed packages..."
apt-get upgrade -y

echo "Installing required packages and Kali default tools..."
apt-get install -y wget ca-certificates git kali-linux-default

echo "Downloading Amazon SSM Agent..."
cd /tmp
wget -O amazon-ssm-agent.deb https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/debian_amd64/amazon-ssm-agent.deb

echo "Installing Amazon SSM Agent..."
apt-get install -y ./amazon-ssm-agent.deb

echo "Enabling and starting Amazon SSM Agent..."
systemctl enable amazon-ssm-agent
systemctl restart amazon-ssm-agent
systemctl status amazon-ssm-agent --no-pager || true

echo "User data script completed successfully."