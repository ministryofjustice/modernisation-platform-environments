#!/bin/bash
# Extract secrets from azure key vault
set -e

vault=dso-passwords-prod
filter="Oracle"

secrets=$(az keyvault secret list --vault-name "${vault}"  --query "[*].name" --output table | grep $filter)
echo "$secrets"
echo "Continue?"
read
for secret in $secrets; do
  echo $secret
  value=$(az keyvault secret show --vault-name ${vault} --name "${secret}")
  username=$(echo "$value" | jq -r .contentType)
  password=$(echo "$value" | jq .value)
  echo '{"'$username'": '$password'}'
done

