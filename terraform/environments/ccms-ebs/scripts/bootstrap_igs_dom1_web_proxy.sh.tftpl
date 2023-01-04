#!/bin/bash -xe
# send script output to /tmp so we can debug boot failures
exec > /tmp/userdata.log 2>&1
echo test of user_data | sudo tee /tmp/user_data.log

# Update all packages
sudo yum -y update
sudo yum install -y httpd.x86_64
sudo yum install -y jq
systemctl start httpd.service
systemctl enable httpd.service
echo "You have reached IGS Dom1 Proxy Web Server" > /var/www/html/index.html