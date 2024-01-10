#!/usr/bin/env bash

ENVIRONMENT=$(basename ${PWD})
STAGE=${1:-"development"}
ROLE=${2:-"modernisation-platform-developer"}

###

echo "Account: ${ENVIRONMENT}"
echo "Stage: ${STAGE}"
echo "Role: ${ROLE}"

modernisationPlatformAccountId=$(aws-sso exec --profile ${ENVIRONMENT}-${STAGE}:${ROLE} -- aws ssm get-parameters --names "modernisation_platform_account_id" --with-decryption --query "Parameters[*].{Value:Value}" --output text)

aws-sso exec --profile ${ENVIRONMENT}-${STAGE}:${ROLE} -- terraform init -backend-config=assume_role={role_arn=\"arn:aws:iam::${modernisationPlatformAccountId}:role/modernisation-account-terraform-state-member-access\"}

aws-sso exec --profile ${ENVIRONMENT}-${STAGE}:${ROLE} -- terraform workspace select ${ENVIRONMENT}-${STAGE}

aws-sso exec --profile ${ENVIRONMENT}-${STAGE}:${ROLE} -- terraform plan
