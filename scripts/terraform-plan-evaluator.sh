#!/usr/bin/env bash

TERRAFORM_PLAN="${1}"

RESOURCES_TO_CHECK_FOR=(
  "aws_eks_cluster"
  "aws_subnet"
  "aws_transfer_server"
  "aws_vpc"
  "aws_vpc_endpoint"
  "aws_iam_user"
  "aws_iam_user_policy"
  "aws_iam_user_policy_attachment"
  "aws_iam_access_key"
  "aws_internet_gateway"
  "aws_internet_gateway_attachment"
  "aws_nat_gateway"
  "aws_route_table"
  "aws_route_table_association"
  "aws_route"
)

resourcesFound=false

for resource in "${RESOURCES_TO_CHECK_FOR[@]}"; do
  checkForResource=$(jq -r --arg resourceType "${resource}" '.resource_changes[] | select(.type == $resourceType) | .change.actions[] | select(. != "no-op" and . != "read")' "${TERRAFORM_PLAN}")
  if [[ -n "${checkForResource}" ]]; then
    echo "Resource ${resource} found in plan"
    resourcesFound=true
  else
    echo "Resource ${resource} not found in plan"
  fi
done

if [[ "${GITHUB_ACTIONS}" == "true" ]] && [[ "${resourcesFound}" == "true" ]]; then
  echo "resources_found=true" >>"${GITHUB_OUTPUT}"
elif [[ "${GITHUB_ACTIONS}" == "true" ]] && [[ "${resourcesFound}" == "false" ]]; then
  echo "resources_found=false" >>"${GITHUB_OUTPUT}"
fi
