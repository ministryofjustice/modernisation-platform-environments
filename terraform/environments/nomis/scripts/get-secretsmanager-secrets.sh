#!/bin/bash
# Run describe-secretsmanager-secrets.sh first
# Retrieve all secrets in secretsmanager-secrets/ profile file.
# Remove existing secret to force re-retrieval

set -e
PROFILE=$1

if [[ -z $PROFILE ]]; then
  echo "Usage: $0 <profile>" >&2
  exit 1
fi

if [[ ! -e secretsmanager-secrets/$PROFILE.txt ]]; then
  echo "Could not find secretsmanager-secrets/$PROFILE.txt" >&2
  exit 1
fi

if [[ ! -d secretsmanager-secrets/$PROFILE ]]; then
  mkdir -p secretsmanager-secrets/$PROFILE
fi

secrets=$(cat secretsmanager-secrets/$PROFILE.txt | grep -v '^$')
echo aws secretsmanager list-secrets --profile $PROFILE
all_secrets=$(aws secretsmanager list-secrets --profile $PROFILE --query 'SecretList[*].[Name,ARN]' --output text)

for secret in $secrets; do
  if [[ -e secretsmanager-secrets/$PROFILE/$secret ]]; then
    echo "skipping $secret as file already exists.  Delete to force re-query" >&2
  else
    arn=$(echo "${all_secrets}" | grep "^${secret}[[:space:]]" | cut -f2)
    if [[ -z $arn ]]; then
      echo "Error looking up ARN for $secret"
      exit 1
    fi
    echo aws secretsmanager get-secret-value --secret-id $arn --query SecretString --output text --profile $PROFILE >&2
    value=$(aws secretsmanager get-secret-value --secret-id $arn --query SecretString --output text --profile $PROFILE || true)
    dir=$(dirname secretsmanager-secrets/$PROFILE/$secret)
    mkdir -p $dir
    echo "$value" > secretsmanager-secrets/$PROFILE/$secret
  fi
done
