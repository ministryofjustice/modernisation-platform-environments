#!/bin/bash
set -e

profile=$1
db_name=$2
expiry=$3

if [[ -z $profile || -z $db_name || -z $expiry ]]; then
  echo "Usage: $0 <aws-profile> <db-name> <token-expiry>"
  echo 
  echo "e.g. $0 nomis-test t1-nomis-db-1 2023-04-15"
  echo 
  echo "Prereq: az logged in aws profile creds set"
  echo "Note: use a short expiry"
  exit 1
fi

az_sas_token=$(az storage account generate-sas --subscription "NOMS Production 1" --account-name strpdnomsazcopyorabkup --permissions rl --resource-types o --services b --https-only --expiry "$expiry" | sed 's/"//g')
SSM_PATH="/database/$db_name"
aws ssm put-parameter --name "${SSM_PATH}/az_sas_token" --type "SecureString" --data-type "text" --value "$az_sas_token" --profile "$profile" --overwrite
