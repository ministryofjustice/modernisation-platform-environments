#!/usr/bin/env bash

# This scripts exists because the Terraform Kubernetes provider does not pass assumed credentials from the default AWS provider

AWS_ACCOUNT_ID=${1}
EKS_CLUSTER_NAME=${2}
AWS_ROLE=${3:-MemberInfrastructureAccess}

if [[ "${GITHUB_ACTIONS}" == "true" ]]; then

  assumeRole=$(aws sts assume-role \
    --role-arn arn:aws:iam::${AWS_ACCOUNT_ID}:role/${AWS_ROLE} \
    --role-session-name modernisation-platform-environments)
  export assumeRole

  AWS_ACCESS_KEY_ID=$(echo ${assumeRole} | jq -r '.Credentials.AccessKeyId')
  export AWS_ACCESS_KEY_ID
  AWS_SECRET_ACCESS_KEY=$(echo ${assumeRole} | jq -r '.Credentials.SecretAccessKey')
  export AWS_SECRET_ACCESS_KEY
  AWS_SESSION_TOKEN=$(echo ${assumeRole} | jq -r '.Credentials.SessionToken')
  export AWS_SESSION_TOKEN

fi

aws eks get-token --cluster-name "${EKS_CLUSTER_NAME}"
