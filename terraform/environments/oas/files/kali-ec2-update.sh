#!/bin/bash
set -e
exec > >(tee /var/log/user-data.log | logger -t user-data) 2>&1

export DEBIAN_FRONTEND=noninteractive

echo "Updating and upgrading system packages..."
apt-get update -y
apt-get upgrade -y

echo "Installing required packages and Kali default tools..."
apt-get install -y wget git sudo kali-linux-default

echo "Downloading and installing Amazon SSM Agent..."
cd /tmp
wget -O amazon-ssm-agent.deb https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/debian_amd64/amazon-ssm-agent.deb
dpkg -i amazon-ssm-agent.deb || apt-get install -f -y

echo "Enabling and starting Amazon SSM Agent..."
systemctl enable amazon-ssm-agent
systemctl start amazon-ssm-agent

echo "Checking whether user 'kali' exists..."
if id "kali" >/dev/null 2>&1; then
  echo "User 'kali' exists. Creating tooling directory..."
  mkdir -p /home/kali/tooling
  chown -R kali:kali /home/kali

  echo "Cloning gotestwaf into /home/kali/tooling..."
  sudo -u kali git clone https://github.com/wallarm/gotestwaf.git /home/kali/tooling
else
  echo "User 'kali' does not exist. Skipping tooling setup."
fi

echo "User data script completed successfully."