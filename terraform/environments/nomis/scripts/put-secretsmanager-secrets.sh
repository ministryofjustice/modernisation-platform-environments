#!/bin/bash
# Upload secrets to SecretsManager
# For example, first call describe-secretsmanager-secrets.sh and get-secretsmanager-secrets.sh
# to get existing secrets.  Create new secrets as required and add into
# the secretsmanager-secrets/profile.txt file.  Then use this script to upload them

MODE=safe # force
PROFILE=$1
PREFIX=$2

if [[ -z $PROFILE ]]; then
  echo "Usage: $0 <profile> [<prefix>]" >&2
  exit 1
fi

if [[ ! -e secretsmanager-secrets/$PROFILE.txt ]]; then
  echo "Could not find secretsmanager-secrets/$PROFILE.txt" >&2
  exit 1
fi

secrets=$(cat secretsmanager-secrets/$PROFILE.txt | grep -v '^$' | grep "^$PREFIX")
echo aws secretsmanager list-secrets --profile $PROFILE
all_secrets=$(aws secretsmanager list-secrets --profile $PROFILE --query 'SecretList[*].[Name,ARN]' --output text)

if [[ $MODE == "force" ]]; then
  for secret in $secrets; do
    if [[ ! -e secretsmanager-secrets/$PROFILE/$secret ]]; then
      echo "skipping $secret as file does not exist" >&2
    else
      arn=$(echo "${all_secrets}" | grep "^${secret}[[:space:]]" | cut -f2)
      if [[ -z $arn ]]; then
        echo "Error looking up ARN for $secret"
        exit 1
      fi
      value=$(cat secretsmanager-secrets/$PROFILE/$secret)
      echo aws secretsmanager put-secret-value --profile $PROFILE --secret-id $arn --secret-string "$value" >&2
    fi
  done
  echo Press RETURN to put-secrets, CTRL-C to cancel
  read

  for secret in $secrets; do
    if [[ ! -e secretsmanager-secrets/$PROFILE/$secret ]]; then
      echo "skipping $secret as file does not exist" >&2
    else
      arn=$(echo "${all_secrets}" | grep "^${secret}[[:space:]]" | cut -f2)
      if [[ -z $arn ]]; then
        echo "Error looking up ARN for $secret"
        exit 1
      fi
      value=$(cat secretsmanager-secrets/$PROFILE/$secret)
      echo aws secretsmanager put-secret-value --profile $PROFILE --secret-id $arn --secret-string "$value" >&2
      aws secretsmanager put-secret-value --profile $PROFILE --secret-id $arn --secret-string "$value"
    fi
  done
elif [[ $MODE == "safe" ]]; then
  for secret in $secrets; do
    if [[ ! -e secretsmanager-secrets/$PROFILE/$secret ]]; then
      echo "skipping $secret as file does not exist" >&2
    else
      arn=$(echo "${all_secrets}" | grep "^${secret}[[:space:]]" | cut -f2)
      if [[ -z $arn ]]; then
        echo "Error looking up ARN for $secret"
        exit 1
      fi
      echo aws secretsmanager get-secret-value --secret-id $arn --query SecretString --output text --profile $PROFILE >&2
      oldvalue=$(aws secretsmanager get-secret-value --secret-id $arn --query SecretString --output text --profile $PROFILE)
      newvalue=$(cat secretsmanager-secrets/$PROFILE/$secret)
      if [[ "$oldvalue" == "$newvalue" ]]; then
        echo "No change"
      else
        echo "Change from $oldvalue to $newvalue"
        echo aws secretsmanager put-secret-value --profile $PROFILE --secret-id $arn --secret-string "$newvalue" >&2
        echo Press RETURN to put-secrets, CTRL-C to cancel
        read
        aws secretsmanager put-secret-value --profile $PROFILE --secret-id $arn --secret-string "$newvalue"
      fi
    fi
  done
fi
