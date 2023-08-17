#!/usr/bin/env bash

cloudwatch_agent_setup() {
    amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -s -c ssm:cloud-watch-config
}

hostname_setup() {
    hostnamectl set-hostname dummy-app
}

yum_install() {
    yum install -y amazon-cloudwatch-agent jq nc telnet
}

hostname_setup
yum_install
cloudwatch_agent_setup