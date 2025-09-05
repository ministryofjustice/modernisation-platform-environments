#!/bin/bash
set -euxo pipefail

# === Set hostname ===
hostnamectl set-hostname "${hostname}"
echo "127.0.0.1   ${hostname}" >> /etc/hosts

# === Base updates and packages ===
yum update -y
yum install -y unzip wget curl git lsof tree java-1.8.0-openjdk

# Install AWS SSM Agent
yum install -y https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/linux_amd64/amazon-ssm-agent.rpm

systemctl stop amazon-ssm-agent
rm -rf /var/lib/amazon/ssm/ipc/
systemctl enable amazon-ssm-agent
systemctl start amazon-ssm-agent


# === Install AWS CLI ===
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
./aws/install

# === Install Amazon CloudWatch Agent ===
wget https://s3.amazonaws.com/amazoncloudwatch-agent/oracle_linux/amd64/latest/amazon-cloudwatch-agent.rpm
rpm -U ./amazon-cloudwatch-agent.rpm
/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -s -c ssm:cloud-watch-config

# === Optional: Create oracle user & dirs ===
mkdir -p /oracle
useradd -g dba -m oracle || true
chown -R oracle:dba /oracle
chmod 775 /oracle

# 

# === Final logs ===
echo "SSOGEN instance bootstrap completed for ${hostname}" >> /var/log/user-data.log
