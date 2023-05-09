#!/bin/bash
              
# Clone CKAN git repo
git clone https://github.com/ckan/ckan-docker.git
cd ckan-docker

sudo yum -y update
sudo yum -y install docker.io docker-compose

sudo usermod -aG docker ec2-user
sudo service docker start

docker compose build
docker compose up