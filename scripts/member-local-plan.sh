#!/usr/bin/env bash

# This is a convenience script for https://user-guide.modernisation-platform.service.justice.gov.uk/user-guide/running-terraform-plan-locally.html#running-terraform-plan-locally
# Run it from within the environment directory, e.g. terraform/environments/cooker

ENVIRONMENT=$(basename ${PWD})
STAGE="development"
ROLE="modernisation-platform-developer"
APPLY="false"

while getopts a:s:r: option; do
  case "${option}" in
    a) APPLY=${OPTARG};;
    s) STAGE="${OPTARG}";;
    r) ROLE="${OPTARG}";;
  esac
done

###

echo "Account: ${ENVIRONMENT}"
echo "Stage: ${STAGE}"
echo "Role: ${ROLE}"
echo "Apply: ${APPLY}"

aws-sso exec --profile ${ENVIRONMENT}-${STAGE}:${ROLE} -- terraform init

aws-sso exec --profile ${ENVIRONMENT}-${STAGE}:${ROLE} -- terraform workspace select ${ENVIRONMENT}-${STAGE}

aws-sso exec --profile ${ENVIRONMENT}-${STAGE}:${ROLE} -- terraform plan

if [[ "${APPLY}" == "true" ]]; then
  aws-sso exec --profile ${ENVIRONMENT}-${STAGE}:${ROLE} -- terraform apply
fi
