#!/bin/bash
# Push ec2-user private keys to SecretsManager
set -e
profiles=$(find . -name 'ec2-user' | cut -d/ -f2)
for profile in $profiles; do
  if (grep "ENCRYPTED" $profile/ec2-user > /dev/null); then
    echo "# $profile: not uploading encrypted private key"
    continue
  fi
  echo "# $profile: checking ec2-user secret exists - run terraform if this fails"
  key=$(aws secretsmanager describe-secret --secret-id "/ec2/.ssh/ec2-user" --profile "$profile")
  echo "# $profile: checking existing ec2-user secret value"
  key=$(aws secretsmanager get-secret-value --secret-id "/ec2/.ssh/ec2-user" --query SecretString --output text --profile "$profile" || true)
  pem=$(cat $profile/ec2-user)
  if [[ "$key" != "$pem" ]]; then
    echo aws secretsmanager put-secret-value --profile $profile --secret-id "/ec2/.ssh/ec2-user" --secret-string "xxxx"
    echo "Press CTRL-C to cancel or RETURN to put secret"
    read
    aws secretsmanager put-secret-value --profile $profile --secret-id "/ec2/.ssh/ec2-user" --secret-string "$pem"
  else
    echo "# $profile: key already uploaded, delete the local unencrypted key"
    echo "Press CTRL-C to cancel or RETURN to delete local unencrypted key"
    read
    rm $profile/ec2-user
  fi
done
