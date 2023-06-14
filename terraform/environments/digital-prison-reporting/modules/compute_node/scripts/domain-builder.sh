#!/bin/bash -xe
# send script output to /tmp so we can debug boot failures
exec > /tmp/userdata.log 2>&1

echo test of user_data | sudo tee /tmp/user_data.log

echo "assumeyes=1" >> /etc/yum.conf

# Update all packages
sudo yum -y update

# Setup YUM install Utils
sudo yum -y install curl wget unzip

# Install Java 11
sudo amazon-linux-extras install java-openjdk11

# Install AWS CLI Libs
echo "Seup AWSCLI V2....."
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
./aws/install

# Sync S3 Domain Builder Artifacts
mkdir -p ~/domain-builder/jars
echo "export PATH=$PATH:~/domain-builder/jars" >> .bash_profile
aws s3 cp s3://dpr-artifact-store-development/build-artifacts/domain-builder/jars/domain-builder-cli-frontend-vLatest-all.jar ~/domain-builder/jars