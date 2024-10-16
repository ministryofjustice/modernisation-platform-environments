#!/bin/bash

yum install -y python-setuptools wget unzip libXp.i386 sshpass
service iptables stop
chkconfig iptables off
yum install -y nawk
mkdir -p /usr/xpg4
ln -s /bin /usr/xpg4/bin
yum update -y

mkdir -p /opt/aws/bin
cd /root
wget https://s3.amazonaws.com/cloudformation-examples/aws-cfn-bootstrap-latest.tar.gz
easy_install --script-dir /opt/aws/bin aws-cfn-bootstrap-latest.tar.gz
mkdir -p /run/cfn-init