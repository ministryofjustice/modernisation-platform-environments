#!/bin/bash
# Run describe-ssm-parameters.sh first
# Retrieve all parameters in ssm-parameters/ profile file.
# Remove existing parameter to force re-retrieval

PROFILE=$1

if [[ -z $PROFILE ]]; then
  echo "Usage: $0 <profile>" >&2
  exit 1
fi

if [[ ! -e ssm-parameters/$PROFILE.txt ]]; then
  echo "Could not find ssm-parameters/$PROFILE.txt" >&2
  exit 1
fi

if [[ ! -d ssm-parameters/$PROFILE ]]; then
  mkdir -p ssm-parameters/$PROFILE
fi

params=$(cat ssm-parameters/$PROFILE.txt | grep -v '^$')

for param in $params; do
  if [[ -e ssm-parameters/$PROFILE/$param ]]; then
    echo "skipping $param as file already exists.  Delete to force re-query" >&2
  else
    echo aws ssm get-parameter --name $param --with-decryption --query Parameter.Value --output text --profile $PROFILE >&2
    value=$(aws ssm get-parameter --name $param --with-decryption --query Parameter.Value --output text --profile $PROFILE)
    dir=$(dirname ssm-parameters/$PROFILE/$param)
    mkdir -p $dir
    echo "$value" > ssm-parameters/$PROFILE/$param
    # aws ssm get-parameter-history --name $param --profile $PROFILE --no-paginate > ssm-parameters/$PROFILE/.$param.history.json
  fi
done
