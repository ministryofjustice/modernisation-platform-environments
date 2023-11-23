#!/bin/bash

# Update the system
sudo yum update -y

# Install NGINX
sudo amazon-linux-extras enable nginx1
sudo yum -y install nginx
sudo nginx -v

# Enable NGINX to start on boot
sudo systemctl enable nginx
sudo chkconfig nginx on

# Start/Test NGINX
sudo systemctl start nginx
sudo curl localhost:80


