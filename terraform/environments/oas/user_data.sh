#!/bin/bash
cd /tmp
sudo yum install -y https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/linux_amd64/amazon-ssm-agent.rpm
# sudo aws s3 cp s3://laa-oracle-software/amazon-ssm-agent.rpm ./
sudo systemctl start amazon-ssm-agent
sudo systemctl enable amazon-ssm-agent
