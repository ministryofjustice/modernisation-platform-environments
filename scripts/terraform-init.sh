#!/bin/bash

set -e

# This script runs terraform init with input set to false, no color outputs, and backend-config, suitable for running as part of a CI/CD pipeline.
# You need to pass through a Terraform directory and backend config as arguments, e.g.
# sh terraform-init.sh terraform/environments "assume_role={role_arn=\"arn:aws:iam::123456789012:role/modernisation-account-terraform-state-member-access\"}"

if [ -z "$1" ] || [ -z "$2" ]; then
  echo "Unsure where to run terraform, exiting. (Usage: terraform-init.sh <terraform_directory> <backend_config>)"
  exit 1
else
  terraform -chdir="$1" init -input=false -no-color -backend-config="$2"
fi
