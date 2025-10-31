#!/bin/bash
# Get a list of all secrets and store in secretsmanager-secrets/ directory

PROFILE=$1

if [[ -z $PROFILE ]]; then
  echo "Usage: $0 <profile>" >&2
  exit 1
fi

echo "# aws secretsmanager list-secrets --profile $PROFILE --query 'SecretList[*].Name' --output text"
secrets=$(aws secretsmanager list-secrets --profile $PROFILE --query 'SecretList[*].Name' --output text | tr '\t' '\n' | sort)

if [[ ! -d secretsmanager-secrets/$PROFILE ]]; then
  mkdir -p secretsmanager-secrets/$PROFILE
fi

if [[ ! -e secretsmanager-secrets/$PROFILE.txt ]]; then
  echo "# Creating secretsmanager-secrets/$PROFILE.txt"
  echo "$secrets" > secretsmanager-secrets/$PROFILE.txt
  exit 1
else 
  echo "# Diffs with secretsmanager-secrets/$PROFILE.txt"
  file=$(mktemp)
  echo "$secrets" > $file
  if ! (diff $file secretsmanager-secrets/$PROFILE.txt); then
    rm -f $file
    echo
    echo "Update?  Press CTRL-C to cancel"
    read
    mv -f secretsmanager-secrets/$PROFILE.txt secretsmanager-secrets/$PROFILE.txt.old
    echo "$secrets" > secretsmanager-secrets/$PROFILE.txt
  else
    rm -f $file
  fi
fi

