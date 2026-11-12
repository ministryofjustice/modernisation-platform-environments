#!/bin/bash
# Download and encrypt ec2-user private keys from SSM
set -e
profiles=$(find . -name 'ec2-user.pub' | cut -d/ -f2)
for profile in $profiles; do
  if [[ -e $profile/ec2-user ]]; then
    echo "# $profile: ec2-user private key already exists"
  else
    echo "# $profile: downloading ec2-user secret from $profile"
    secret_id=
    if [[ $profile == "delius-mis-development" ]]; then
      secret_id="delius-mis-dev-app-ec2-user-ssh-private-key"
    elif [[ $profile == "delius-mis-preproduction" ]]; then
      secret_id="delius-mis-preprod-app-ec2-user-ssh-private-key"
    elif [[ $profile == "delius-mis-production" ]]; then
      secret_id="delius-mis-prod-app-ec2-user-ssh-private-key"
    else
      echo "ERROR: update script with corresponding secret id for $profile"
      exit 1
    fi
    key=$(aws secretsmanager get-secret-value --secret-id $secret_id --query SecretString --output text --profile "$profile")    
    echo "# $profile: creating encrypted private key, paste in your passphrase"
    read -rs passphrase
    echo "$key" > "$profile/ec2-user"
    chmod 0600 "$profile/ec2-user"
    ssh-keygen -p -P "" -N "$passphrase" -f "$profile/ec2-user"
  fi
done
