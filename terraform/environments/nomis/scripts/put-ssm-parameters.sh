#!/bin/bash
# Upload parameters to SSM
# For example, first call describe-ssm-parameters.sh and get-ssm-parameters.sh
# to get existing parameters.  Create new parameters as required and add into
# the ssm-parameters/profile.txt file.  Then use this script to upload them

MODE=safe # force
PROFILE=$1
PREFIX=$2

if [[ -z $PROFILE ]]; then
  echo "Usage: $0 <profile> [<prefix>]" >&2
  exit 1
fi

if [[ ! -e ssm-parameters/$PROFILE.txt ]]; then
  echo "Could not find ssm-parameters/$PROFILE.txt" >&2
  exit 1
fi

params=$(cat ssm-parameters/$PROFILE.txt | grep -v '^$' | grep "^$PREFIX")

if [[ $MODE == "force" ]]; then
  for param in $params; do
    if [[ ! -e ssm-parameters/$PROFILE/$param ]]; then
      echo "skipping $param as file does not exist" >&2
    else
      value=$(cat ssm-parameters/$PROFILE/$param)
      echo aws ssm put-parameter --name $param --type "SecureString" --data-type "text" --value "$value" --profile $PROFILE --overwrite >&2
    fi
  done
  echo Press RETURN to put-parameters, CTRL-C to cancel
  read

  for param in $params; do
    if [[ ! -e ssm-parameters/$PROFILE/$param ]]; then
      echo "skipping $param as file does not exist" >&2
    else
      value=$(cat ssm-parameters/$PROFILE/$param)
      echo aws ssm put-parameter --name $param --type "SecureString" --data-type "text" --value "$value" --profile $PROFILE --overwrite >&2
      aws ssm put-parameter --name $param --type "SecureString" --data-type "text" --value "$value" --profile $PROFILE --overwrite
    fi
  done
elif [[ $MODE == "safe" ]]; then
  for param in $params; do
    if [[ ! -e ssm-parameters/$PROFILE/$param ]]; then
      echo "skipping $param as file does not exist" >&2
    else
      echo aws ssm get-parameter --name $param --with-decryption --query Parameter.Value --output text --profile $PROFILE >&2
      oldvalue=$(aws ssm get-parameter --name $param --with-decryption --query Parameter.Value --output text --profile $PROFILE)
      newvalue=$(cat ssm-parameters/$PROFILE/$param)
      if [[ "$oldvalue" == "$newvalue" ]]; then
        echo "No change"
      else
        echo "Change from $oldvalue to $newvalue"
        echo aws ssm put-parameter --name $param --type "SecureString" --data-type "text" --value "$newvalue" --profile $PROFILE --overwrite >&2
        echo Press RETURN to put-parameters, CTRL-C to cancel
        read
        aws ssm put-parameter --name $param --type "SecureString" --data-type "text" --value "$newvalue" --profile $PROFILE --overwrite
      fi
    fi
  done
fi
