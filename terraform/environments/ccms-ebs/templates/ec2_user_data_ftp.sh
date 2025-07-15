#!/bin/bash

exec > /tmp/userdata.log 2>&1

amazon-linux-extras install -y epel
yum install -y wget unzip vsftpd jq s3fs-fuse
yum install -y https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/linux_amd64/amazon-ssm-agent.rpm

curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
./aws/install

wget https://s3.amazonaws.com/amazoncloudwatch-agent/oracle_linux/amd64/latest/amazon-cloudwatch-agent.rpm
rpm -U ./amazon-cloudwatch-agent.rpm

/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -s -c ssm:cloud-watch-config

systemctl stop amazon-ssm-agent
rm -rf /var/lib/amazon/ssm/ipc/
systemctl start amazon-ssm-agent

ENV="${environment}"
inbound_bucket="${ftp_inbound_bucket}"
outbound_bucket="${ftp_outbound_bucket}"

SSHD_CONFIG="/etc/ssh/sshd_config"

# Backup original config
cp "$SSHD_CONFIG" "$SSHD_CONFIG.bak_$(date +%F_%T)"

# Add port 22 if not already present
if ! grep -q '^Port 22' "$SSHD_CONFIG"; then
    echo "Port 22" | sudo tee -a "$SSHD_CONFIG" > /dev/null
fi

# Add port 8022 if not already present
if ! grep -q '^Port 8022' "$SSHD_CONFIG"; then
    echo "Port 8022" | sudo tee -a "$SSHD_CONFIG" > /dev/null
fi

SECRET_NAME="ftp-s3-$ENV-aws-key"
