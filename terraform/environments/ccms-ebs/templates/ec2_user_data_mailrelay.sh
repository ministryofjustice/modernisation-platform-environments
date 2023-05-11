#!/usr/bin/env bash

hostnamectl set-hostname mailrelay

#/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -s -c ssm:cloud-watch-config