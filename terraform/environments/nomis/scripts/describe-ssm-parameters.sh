#!/bin/bash
# Get a list of all parameter names and store in ssm-parameters/ directory

PROFILE=$1

if [[ -z $PROFILE ]]; then
  echo "Usage: $0 <profile>" >&2
  exit 1
fi

echo "# aws ssm describe-parameters --profile $PROFILE --query 'Parameters[*].Name' --output text"
params=$(aws ssm describe-parameters --profile $PROFILE --query 'Parameters[*].Name' --output text | tr '\t' '\n' | sort)

if [[ ! -d ssm-parameters/$PROFILE ]]; then
  mkdir -p ssm-parameters/$PROFILE
fi

if [[ ! -e ssm-parameters/$PROFILE.txt ]]; then
  echo "# Creating ssm-parameters/$PROFILE.txt"
  echo "$params" > ssm-parameters/$PROFILE.txt
  exit 1
else 
  echo "# Diffs with ssm-parameters/$PROFILE.txt"
  file=$(mktemp)
  echo "$params" > $file
  if ! (diff $file ssm-parameters/$PROFILE.txt); then
    rm -f $file
    echo
    echo "Update?  Press CTRL-C to cancel"
    read
    mv -f ssm-parameters/$PROFILE.txt ssm-parameters/$PROFILE.txt.old
    echo "$params" > ssm-parameters/$PROFILE.txt
  else
    rm -f $file
  fi
fi

