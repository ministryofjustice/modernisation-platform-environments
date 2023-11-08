#!/bin/bash

# Update the system
sudo yum update -y

# Install NGINX
sudo amazon-linux-extras enable nginx1
sudo yum -y install nginx
sudo nginx -v

# Install dependencies
# sudo yum install openssl11

# Enable NGINX to start on boot
sudo systemctl enable nginx
sudo chkconfig nginx on

# Install CertBox and setup SSL
# sudo amazon-linux-extras install epel
# sudo yum install -y certbot certbot-nginx
# certbot --non-interactive --agree-tos --register-unsafely-without-email --nginx -d example.com -d www.example.com

# Start/Test NGINX
sudo systemctl start nginx
sudo curl localhost:80


