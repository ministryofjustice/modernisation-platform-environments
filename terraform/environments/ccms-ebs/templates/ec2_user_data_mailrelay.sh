#!/usr/bin/env bash

hostnamectl set-hostname mailrelay

yum install -y amazon-cloudwatch-agent jq postfix telnet
amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -s -c ssm:cloud-watch-config