#!/bin/bash
# Push ec2-user private keys to SSM
set -e
profiles=$(find . -name 'ec2-user' | cut -d/ -f2)
for profile in $profiles; do
  echo "# Downloading ssm parameter ec2-user_pem from $profile"
  key=$(aws ssm get-parameter --with-decryption --name ec2-user_pem --output text --query Parameter.Value --profile "$profile")
  pem=$(cat $profile/ec2-user)
  if [[ "$key" != "$pem" ]]; then
    echo aws ssm put-parameter --name "ec2-user_pem" --type "SecureString" --data-type "text" --value "xxx" --profile "$profile"
    aws ssm put-parameter --name "ec2-user_pem" --type "SecureString" --data-type "text" --value "$pem" --overwrite --profile "$profile"
  else
    echo "$profile already uploaded"
  fi
done
