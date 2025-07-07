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

useradd -m s3xfer

echo "pasv_enable=YES" >> /etc/vsftpd/vsftpd.conf
echo "pasv_min_port=3000" >> /etc/vsftpd/vsftpd.conf
echo "pasv_max_port=3010" >> /etc/vsftpd/vsftpd.conf

systemctl restart vsftpd.service

# create mount directories
mkdir /s3xfer/S3/laa-ccms-inbound-${environment}-mp 
mkdir /s3xfer/S3/laa-ccms-outbound-${environment}-mp
# Backup fstab first
cp /etc/fstab /etc/fstab.bak.$(date +%F-%H%M%S)

# Define mount entries
LINE1="s3fs#laa-ccms-inbound-${environment}-mp /s3xfer/S3/laa-ccms-inbound-${environment}-mp fuse _netdev,iam_role=auto,allow_other,nonempty 0 0"
LINE2="s3fs#laa-ccms-outbound-${environment}-mp /s3xfer/S3/laa-ccms-outbound-${environment}-mp fuse _netdev,iam_role=auto,allow_other,nonempty 0 0"

# Append to fstab if not already present
grep -qxF "$LINE1" /etc/fstab || echo "$LINE1" >> /etc/fstab
grep -qxF "$LINE2" /etc/fstab || echo "$LINE2" >> /etc/fstab

echo "fstab updated."
# Test mounting all entries and capture errors
echo "Testing mounts with: mount -a"
if ! sudo mount -a 2>&1 | tee /etc/mount_errors.log; then
  echo "[ERROR] One or more mounts failed. See /tmp/mount_errors.log:"
  cat /etc/mount_errors.log
  exit 1
else
  echo "[SUCCESS] All mounts applied successfully."
fi