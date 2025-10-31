#!/bin/bash
# Delete parameters to SSM
# For example, first call describe-ssm-parameters.sh and get-ssm-parameters.sh
# to get existing parameters.  Use this script to delete the given 
# parameters from SSM
# the ssm-parameters/profile.txt file.  Then use this script to upload them

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

for param in $params; do
  if [[ ! -e ssm-parameters/$PROFILE/$param ]]; then
    echo "skipping $param as file does not exist" >&2
  else
    echo aws ssm delete-parameter --name $param --profile $PROFILE
  fi
done
echo "Press RETURN to delete"
read
for param in $params; do
  if [[ -e ssm-parameters/$PROFILE/$param ]]; then
    echo aws ssm delete-parameter --name $param --profile $PROFILE
    aws ssm delete-parameter --name $param --profile $PROFILE
  fi
done
