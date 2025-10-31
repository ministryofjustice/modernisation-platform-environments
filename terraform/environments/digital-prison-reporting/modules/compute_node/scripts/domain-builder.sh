#!/bin/bash -xe
# send script output to /tmp so we can debug boot failures
# Ouput all log
exec > >(tee /tmp/userdata.log|logger -t user-data-extra -s 2>/dev/console) 2>&1

echo "assumeyes=1" >> /etc/yum.conf

# Pass Variables into a file
echo "DOMAIN_API_KEY=${DOMAIN_API_KEY}" >> /etc/environment

# Update all packages
sudo yum -y update

# Setup YUM install Utils
sudo yum -y install curl wget unzip jq

# Install Java 11
sudo amazon-linux-extras install java-openjdk11

# Install AWS CLI Libs
echo "Seup AWSCLI V2....."
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
./aws/install

if grep ssm-user /etc/passwd &> /dev/null;
then
  echo "ssm-user already exists - skipping create"
else
  # Create the ssm-user using system defaults.
  # See /etc/default/useradd
  echo "ssm-user does not exist - creating"
  sudo useradd ssm-user --create-home
  echo "ssm-user created"
fi

# Create target directories for domain builder jar
sudo mkdir -p /home/ssm-user/domain-builder/jars
sudo chown -R ssm-user /home/ssm-user
chmod -R 0777 /home/ssm-user/domain-builder

# Retrieve Env Variables
environment="${ENV}"
domain_builder_api_key="${DOMAIN_API_KEY}"

# Sync S3 Domain Builder Artifacts
aws s3 cp s3://dpr-artifact-store-$environment/build-artifacts/domain-builder/jars/domain-builder-cli-frontend-vLatest-all.jar /home/ssm-user/domain-builder/jars

# Location of script that will be used to launch the domain builder jar.
launcher_script_location=/usr/bin/domain-builder

# Construct the default endpoint URL which follows a consistent pattern.
domain_builder_url="https://${REST_API_ID}.execute-api.eu-west-2.amazonaws.com/default"

# Generate a launcher script for the jar that starts domain-builder in interactive mode
# and configured to use the function URL via the DOMAIN_API_URL environment variable
# and the api-key passed via the DOMAIN_API_KEY environment variable.
sudo cat <<EOF > $launcher_script_location
#!/bin/bash

# If no args are specified launch interactive domain builder session otherwise
# pass any args to the domain builder in batch mode.
if [ \$# -eq 0 ]
then
  args="-i --enable-ansi"
else
  args=\$@
fi

# Get Latest Artifact Version, for everyrun
aws s3 cp s3://dpr-artifact-store-$environment/build-artifacts/domain-builder/jars/domain-builder-cli-frontend-vLatest-all.jar /home/ssm-user/domain-builder/jars

    DOMAIN_API_URL="$domain_builder_url" \
      DOMAIN_API_KEY="$domain_builder_api_key" \
          java -jar /home/ssm-user/domain-builder/jars/domain-builder-cli-frontend-vLatest-all.jar \$args
EOF

sudo chmod 0755 $launcher_script_location

echo "Bootstrap Complete"
