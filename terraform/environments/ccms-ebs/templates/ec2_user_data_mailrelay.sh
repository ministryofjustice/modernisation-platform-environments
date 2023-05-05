#!/usr/bin/env bash

yum install -y https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/linux_amd64/amazon-ssm-agent.rpm
yum install -y https://s3.amazonaws.com/amazoncloudwatch-agent/oracle_linux/amd64/latest/amazon-cloudwatch-agent.rpm
yum install -y awscli jq telnet unzip

systemctl stop amazon-ssm-agent
rm -rf /var/lib/amazon/ssm/ipc/
systemctl start amazon-ssm-agent

hostnamectl set-hostname mailrelay

#/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -s -c ssm:cloud-watch-config