#!/bin/bash
# Download and encrypt ec2-user private keys from SSM
set -e
profiles=$(find . -name 'ec2-user.pub' | cut -d/ -f2)
for profile in $profiles; do
  if [[ -e $profile/ec2-user ]]; then
    echo "# $profile: ec2-user private key already exists"
  else
    echo "# $profile: downloading ec2-user secret from $profile"
    key=$(aws secretsmanager get-secret-value --secret-id "/ec2/.ssh/ec2-user" --query SecretString --output text --profile "$profile")
    echo "# $profile: creating encrypted private key, paste in passphrase"
    openssl rsa -in <(echo "${key}") -out "$profile/ec2-user" -aes256
    chmod 0600 "$profile/ec2-user"
  fi
done
