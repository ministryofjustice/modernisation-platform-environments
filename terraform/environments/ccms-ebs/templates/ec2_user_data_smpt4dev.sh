#!/usr/bin/env bash

# Install Docker
sudo su
sudo yum -y install docker
sudo service docker start
 
# Wait for Docker to be ready
until sudo docker info >/dev/null 2>&1; do
   echo "Waiting for Docker to start..."
   sleep 2
done
 
# Run your container
 sudo docker run -d --name smtp4dev-mock-email-container \
   --restart always \
   -p 80:80 -p 2525:25 -p 110:110 \
   -v /path/on/host:/app/Data \
   -e Smtp4Dev__MessageRetentionOptions__MaxAge=30 \
   rnwood/smtp4dev
 
# Install sqlite db on the ec2
 sudo dnf install sqlite -y