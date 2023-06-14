#!/bin/bash -xe
# send script output to /tmp so we can debug boot failures
# Ouput all log
exec > >(tee /tmp/userdata.log|logger -t user-data-extra -s 2>/dev/console) 2>&1

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

# Set Env Configuration
sudo mkdir -p /home/ssm-user/domain-builder/jars
sudo touch /home/ssm-user/.bash_profile; echo "export PATH=$PATH:/home/ssm-user/domain-builder/jars" >> /home/ssm-user/.bash_profile
sudo chmod +x /home/ssm-user/.bash_profile

# Sync S3 Domain Builder Artifacts
aws s3 cp s3://dpr-artifact-store-development/build-artifacts/domain-builder/jars/domain-builder-cli-frontend-vLatest-all.jar /home/ssm-user/domain-builder/jars

echo "Bootstrap Complete"