#!/bin/bash
# Download and encrypt ec2-user private keys from SSM
set -e
profiles=$(find . -name 'ec2-user.pub' | cut -d/ -f2)
for profile in $profiles; do
  echo "# Downloading ssm parameter ec2-user_pem from $profile"
  key=$(aws ssm get-parameter --with-decryption --name ec2-user_pem --output text --query Parameter.Value --profile "$profile")
  echo "# Creating encrypted private key, paste in passphrase"
  openssl rsa -in <(echo "${key}") -out "$profile/ec2-user" -aes256
  chmod 0600 "$profile/ec2-user"
done
