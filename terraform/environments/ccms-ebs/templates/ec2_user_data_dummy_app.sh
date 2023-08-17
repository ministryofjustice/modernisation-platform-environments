#!/usr/bin/env bash


amazon_ssm_agent_setup() {
    yum install -y https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/linux_amd64/amazon-ssm-agent.rpm
    systemctl stop amazon-ssm-agent
    rm -rf /var/lib/amazon/ssm/ipc/
    systemctl start amazon-ssm-agent
}

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
amazon_ssm_agent_setup
cloudwatch_agent_setup