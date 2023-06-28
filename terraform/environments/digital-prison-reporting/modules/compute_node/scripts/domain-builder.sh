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

# Create home directory with dir structure for domain builder jars
sudo mkdir -p /home/ssm-user/domain-builder/jars
sudo chown -R ssm-user /home/ssm-user
chmod -R 0777 /home/ssm-user/domain-builder
cd /home/ssm-user

# Sync S3 Domain Builder Artifacts
aws s3 cp s3://dpr-artifact-store-development/build-artifacts/domain-builder/jars/domain-builder-cli-frontend-vLatest-all.jar /home/ssm-user/domain-builder/jars

# Location of script that will be used to launch the domain builder jar.
launcher_script_location=/usr/bin/domain-builder

# Get the configured API gateway for the domain builder backend API lambda
domain_builder_url=$(aws apigatewayv2 get-apis --output json | jq -r  '.Items[] | select(.Name == "domain-builder-backend-api") | .ApiEndpoint')

# Generate a launcher script for the jar that starts domain-builder in interactive mode
# and configured to use the function URL via the DOMAIN_API_URL environment variable.
sudo cat <<EOF > $launcher_script_location
#!/bin/bash

cd /home/ssm-user

DOMAIN_API_URL="$domain_builder_url" java -jar domain-builder/jars/domain-builder-cli-vLatest-all.jar -i --enable-ansi

EOF

sudo chmod 0755 $launcher_script_location

echo "Bootstrap Complete"
