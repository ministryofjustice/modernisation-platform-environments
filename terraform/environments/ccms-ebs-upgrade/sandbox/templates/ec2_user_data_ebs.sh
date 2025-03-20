#!/usr/bin/env bash
exec > /tmp/userdata.log 2>&1

# Create/update ec2-user ssh directory and authorized_keys regardless of whether the directory exists
mkdir -p /home/ec2-user/.ssh
touch /home/ec2-user/.ssh/authorized_keys
chmod 700 /home/ec2-user
chmod 700 /home/ec2-user/.ssh
chmod 600 /home/ec2-user/.ssh/authorized_keys

# Add the public key to authorized_keys
echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCkmtXdBQqg/YxggH1jlD0dTawYk09J5VyQ45dO/GebDI6RzvgQpkb9uRFjKhQZAO5wTzD3Gbae9goJ4b2/E32cfxT6KHPHN1ZBhMwEdZnR9+2enbFxQxKLLUmVBtD0+eOjSh4cCi2v7bHP25i1GnNIHwjhrQEO9AfBPN/h95Wh3xTACnFjdYfK6lJm362OEgTRX7eIUdZ0dQxgNSmPTMoNDlZKglZw9kG6wVy/qnVxJVBDHiBPIPTwiwbxpscm++m6vFcjJGBh55/nEmdzqEyLTj0835iG2aEcSjYeR1r3F71ME0+cmhhc7SdvgOwnYilOUNOFih7sxyR4UHu8UZoR oracle-base-dev" > /home/ec2-user/.ssh/authorized_keys

# Set correct ownership
chown -R ec2-user:ec2-user /home/ec2-user

# Fix SELinux contexts if needed
restorecon -R -v /home/ec2-user

# Fix resolv.conf
echo "Configuring resolv.conf"
# Remove immutable attribute if it exists
chattr -i /etc/resolv.conf 2>/dev/null || true

# Create a properly configured resolv.conf
cat > /etc/resolv.conf << EOF
# This file has +i attribute, so it can not be modified!
# To edit this file, execute "chattr -i /etc/resolv.conf" first.
search laa-development.modernisation-platform.service.justice.gov.uk eu-west-2.compute.internal
nameserver 10.26.56.2
# Remember to "chattr +i /etc/resolv.conf" after editing!
EOF

# Set the immutable attribute to prevent modification
chattr +i /etc/resolv.conf
echo "resolv.conf configuration complete"

# Original user data script
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
s3fs -o iam_role="role_stsassume_oracle_base" -o url="https://s3.eu-west-2.amazonaws.com" -o endpoint=eu-west-2 -o dbglevel=info -o curldbg -o allow_other ccms-ebs-development-dbbackup /rman
echo "ccms-ebs-development-dbbackup /rman fuse.s3fs _netdev,allow_other,url=https://s3.eu-west-2.amazonaws.com,iam_role=role_stsassume_oracle_base 0 0" >> /etc/fstab