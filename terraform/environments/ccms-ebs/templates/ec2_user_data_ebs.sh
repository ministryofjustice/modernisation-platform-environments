#!/usr/bin/env bash

exec > /tmp/userdata.log 2>&1
yum update -y
yum install -y wget unzip automake fuse fuse-devel gcc-c++ git libcurl-devel libxml2-devel make openssl-devel

wget https://s3.amazonaws.com/amazoncloudwatch-agent/oracle_linux/amd64/latest/amazon-cloudwatch-agent.rpm
rpm -U ./amazon-cloudwatch-agent.rpm
/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -s -c ssm:cloud-watch-config

yum install -y https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/linux_amd64/amazon-ssm-agent.rpm
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
./aws/install

systemctl stop amazon-ssm-agent
rm -rf /var/lib/amazon/ssm/ipc/
systemctl start amazon-ssm-agent

git clone https://github.com/s3fs-fuse/s3fs-fuse.git
cd s3fs-fuse/
./autogen.sh
./configure
make
make install

cd /
mkdir /rman
s3fs -o iam_role="role_stsassume_oracle_base" -o url="https://s3.eu-west-2.amazonaws.com" -o endpoint=eu-west-2 -o dbglevel=info -o curldbg -o allow_other ccms-ebs-${environment}-dbbackup /rman
echo "ccms-ebs-${environment}-dbbackup /rman fuse.s3fs _netdev,allow_other,url=https://s3.eu-west-2.amazonaws.com,iam_role=role_stsassume_oracle_base 0 0" >> /etc/fstab