#!/bin/bash
set -euo pipefail

mkdir -p /SSOGEN
EFS_MOUNT_POINT=/SSOGEN
# === Set hostname ===
hostnamectl set-hostname "${hostname}"
echo "127.0.0.1   ${hostname}" >> /etc/hosts

#--Configure EFS
yum install -y amazon-efs-utils
mkdir $EFS_MOUNT_POINT
mount -t efs -o tls ${efs_id}:/ $EFS_MOUNT_POINT
chmod go+rw $EFS_MOUNT_POINT
# create large file for better EFS performance 
# https://docs.aws.amazon.com/efs/latest/ug/performance.html
dd if=/dev/urandom of=$EFS_MOUNT_POINT/large_file_for_efs_performance bs=1024k count=10000

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
