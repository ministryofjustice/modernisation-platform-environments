echo "########################################################################################################################"
echo "Lake Formation V4 RAM shared resources:"

# Get active Lake Formation V4 shares
resourceShareNames=$(aws ram get-resource-shares --resource-owner OTHER-ACCOUNTS | jq -r '.resourceShares[] | select(.name | startswith("LakeFormation-V4")) | select(.status == "ACTIVE") | .name')
export resourceShareNames

for resourceShareName in ${resourceShareNames}; do
  echo "  ${resourceShareName}:"

  # Get the resource share ARN
  resourceShareArn=$(aws ram get-resource-shares --resource-owner OTHER-ACCOUNTS | jq -r --arg name "${resourceShareName}" '.resourceShares[] | select(.name == $name) | .resourceShareArn')
  export resourceShareArn
  echo "    ${resourceShareArn}:"

  # Get the resource share resources
  resourceShareResources=$(aws ram list-resources --resource-owner OTHER-ACCOUNTS --resource-share-arns "${resourceShareArn}" | jq -r '.resources[].arn')
  export resourceShareResources

  for resourceShareResource in ${resourceShareResources}; do
    echo "      ${resourceShareResource}"
  done
done
