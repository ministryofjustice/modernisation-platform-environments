#!/usr/bin/env bash

# This is a convenience script for https://user-guide.modernisation-platform.service.justice.gov.uk/user-guide/running-terraform-plan-locally.html#running-terraform-plan-locally
# Run it from within the environment directory, e.g. terraform/environments/cooker

ENVIRONMENT=$(basename ${PWD})
STAGE="development"
ROLE="modernisation-platform-developer"

while getopts s:r: option; do
  case "${option}" in
    s) STAGE="${OPTARG}";;
    r) ROLE="${OPTARG}";;
  esac
done

###

echo "Account: ${ENVIRONMENT}"
echo "Stage: ${STAGE}"
echo "Role: ${ROLE}"

modernisationPlatformAccountId=$(aws-sso exec --profile ${ENVIRONMENT}-${STAGE}:${ROLE} -- aws ssm get-parameters --names "modernisation_platform_account_id" --with-decryption --query "Parameters[*].{Value:Value}" --output text)

aws-sso exec --profile ${ENVIRONMENT}-${STAGE}:${ROLE} -- terraform init -backend-config=assume_role={role_arn=\"arn:aws:iam::${modernisationPlatformAccountId}:role/modernisation-account-terraform-state-member-access\"}

aws-sso exec --profile ${ENVIRONMENT}-${STAGE}:${ROLE} -- terraform workspace select ${ENVIRONMENT}-${STAGE}

aws-sso exec --profile ${ENVIRONMENT}-${STAGE}:${ROLE} -- terraform plan
