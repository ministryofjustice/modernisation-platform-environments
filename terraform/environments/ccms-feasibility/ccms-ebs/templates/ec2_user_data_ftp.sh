#!/bin/bash

exec > /tmp/userdata.log 2>&1

yum install -y wget unzip vsftpd

echo "pasv_enable=YES" >> /etc/vsftpd/vsftpd.conf
echo "pasv_min_port=3000" >> /etc/vsftpd/vsftpd.conf
echo "pasv_max_port=3010" >> /etc/vsftpd/vsftpd.conf

systemctl enable vsftpd.service
systemctl restart vsftpd.service
