#!/usr/bin/env bash

# This is a convenience script for https://user-guide.modernisation-platform.service.justice.gov.uk/user-guide/running-terraform-plan-locally.html#running-terraform-plan-locally
# Run it from within the environment directory, e.g. terraform/environments/cooker

if [[ -z "${REMOTE_CONTAINERS}" ]]; then
  echo "This script is intended to be run from within the development container"
  exit 1
fi

COMPONENT="${PWD#/workspaces/modernisation-platform-environments/terraform/environments/}"
ACCOUNT="${COMPONENT%%/*}"
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

if [[ "${ACCOUNT}" == "${COMPONENT}" ]]; then
  COMPONENT="root"
fi

echo "Account: ${ACCOUNT}"
echo "Component: ${COMPONENT}"
echo "Stage: ${STAGE}"
echo "Role: ${ROLE}"
echo "Apply: ${APPLY}"

aws-sso login

aws-sso exec --profile ${ACCOUNT}-${STAGE}:${ROLE} -- terraform init -upgrade

aws-sso exec --profile ${ACCOUNT}-${STAGE}:${ROLE} -- terraform workspace select ${ACCOUNT}-${STAGE}

aws-sso exec --profile ${ACCOUNT}-${STAGE}:${ROLE} -- terraform plan

if [[ "${APPLY}" == "true" ]]; then
  aws-sso exec --profile ${ACCOUNT}-${STAGE}:${ROLE} -- terraform apply
fi
