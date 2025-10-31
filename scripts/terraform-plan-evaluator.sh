#!/usr/bin/env bash

TERRAFORM_PLAN="${1}"

RESOURCES_TO_CHECK_FOR=(
  "aws_eks_cluster"
  "aws_subnet"
  "aws_transfer_server"
  "aws_vpc"
  "aws_vpc_endpoint"
  "aws_vpc_peering_connection"
  "aws_vpc_peering_connection_accepter"
  "aws_vpc_peering_connection_options"
  "aws_iam_user"
  "aws_iam_user_policy"
  "aws_iam_user_policy_attachment"
  "aws_iam_access_key"
  "aws_internet_gateway"
  "aws_internet_gateway_attachment"
  "aws_nat_gateway"
  "aws_route_table"
  "aws_route_table_association"
  "aws_route",
  "aws_iam_openid_connect_provider",
  "aws_cloudformation_stack",
  "aws_cloudformation_stack_set",
  "aws_cloudformation_stack_set_instance",
  "aws_cloudformation_type",
  "aws_ec2_transit_gateway_vpc_attachment",
  "aws_lakeformation_permissions",
  "aws_ram_resource_share",
  "aws_ram_principal_association",
  "aws_ram_resource_association"
)

resourcesFound=false

for resource in "${RESOURCES_TO_CHECK_FOR[@]}"; do
  echo "Checking for resource: ${resource}"
  checkForResource=$(jq -r --arg resourceType "${resource}" '.resource_changes[] | select(.type == $resourceType) | .change.actions[] | select(. != "no-op" and . != "read")' "${TERRAFORM_PLAN}")
  if [[ -n "${checkForResource}" ]]; then
    echo "Resource ${resource} found in plan"
    resourcesFound=true
  fi
done

if [[ "${GITHUB_ACTIONS}" == "true" ]] && [[ "${resourcesFound}" == "true" ]]; then
  echo "resources_found=true" >>"${GITHUB_OUTPUT}"
elif [[ "${GITHUB_ACTIONS}" == "true" ]] && [[ "${resourcesFound}" == "false" ]]; then
  echo "resources_found=false" >>"${GITHUB_OUTPUT}"
fi
