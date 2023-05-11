#!/usr/bin/env bash

sudo snap install amazon-ssm-agent --classic
sudo snap start amazon-ssm-agent

hostnamectl set-hostname mailrelay

#/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -s -c ssm:cloud-watch-config