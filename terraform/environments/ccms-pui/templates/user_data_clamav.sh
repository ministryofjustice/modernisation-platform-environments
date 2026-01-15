#!/usr/bin/env bash

exec > /tmp/userdata.log 2>&1

yum install -y wget unzip vsftpd jq s3fs-fuse

yum install -y https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/linux_amd64/amazon-ssm-agent.rpm
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
./aws/install

wget https://s3.amazonaws.com/amazoncloudwatch-agent/oracle_linux/amd64/latest/amazon-cloudwatch-agent.rpm
rpm -U ./amazon-cloudwatch-agent.rpm
amazon-linux-extras install -y epel

/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -s -c ssm:cloud-watch-config

systemctl stop amazon-ssm-agent
rm -rf /var/lib/amazon/ssm/ipc/
systemctl start amazon-ssm-agent

dnf install -y clamav1.4 clamav1.4-freshclam clamav1.4-data clamav1.4-filesystem clamd1.4.x86_64

cat << EOF > /etc/clamd.d/scan.conf
## Minimal config
LogFile /var/log/clamd.scan
LogTime yes
LogClean yes
LogSyslog yes
LogVerbose yes
TCPSocket 3310
StreamMaxLength 320M
User clamscan
EOF

freshclam

systemctl enable clamd@scan.service
systemctl start clamd@scan.service