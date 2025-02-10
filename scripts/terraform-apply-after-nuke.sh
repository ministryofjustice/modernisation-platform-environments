#!/bin/bash

export AWS_REGION=eu-west-2

# for example PERFORMANCE_HUB_DEVELOPMENT_ACCID will be converted to the directory name 'performance-hub'
to_dir_name() {
  dir_name=$(echo ${1%%_DEVELOPMENT_ACCID} | tr '[:upper:]' '[:lower:]' | tr '_' '-')
}

# get secret
nuke_account_ids_json=$(aws secretsmanager get-secret-value --secret-id nuke_account_ids --query 'SecretString' --output text --no-cli-pager)

# Extract the account IDs into the account_ids map
declare -A account_ids
eval "$(jq -r '.NUKE_ACCOUNT_IDS | to_entries | .[] |"account_ids[" + (.key | @sh) + "]=" + (.value | @sh)' <<<"$nuke_account_ids_json")"

redeployed_envs=()
skipped_envs=()
failed_envs=()
for key in "${!account_ids[@]}"; do
  exit_code=0
  to_dir_name "$key"
  if [[ "$NUKE_DO_NOT_RECREATE_ENVIRONMENTS" != *"${dir_name}-development,"* ]]; then
    echo "BEGIN: terraform apply ${dir_name}-development"
    bash scripts/terraform-init.sh "terraform/environments/${dir_name}" || exit_code=$?
    terraform -chdir="terraform/environments/${dir_name}" workspace select "${dir_name}-development" || exit_code=$?
    bash scripts/terraform-apply.sh "terraform/environments/${dir_name}" || exit_code=$?
    if [[ $exit_code -ne 0 ]]; then
      failed_envs+=("${dir_name}-development")
    else
      redeployed_envs+=("${dir_name}-development")
    fi
    echo "END: terraform apply ${dir_name}-development"
  else
    echo "Skipped terraform apply for ${dir_name}-development because of the env variable NUKE_DO_NOT_RECREATE_ENVIRONMENTS=${NUKE_DO_NOT_RECREATE_ENVIRONMENTS}"
    skipped_envs+=("${dir_name}-development")
  fi
done

echo "Terraform apply complete: ${#redeployed_envs[@]} redeployed, ${#skipped_envs[@]} skipped, ${#failed_envs[@]} failed."

if [[ ${#redeployed_envs[@]} -ne 0 ]]; then
  echo "Redeployed environments: ${redeployed_envs[@]}"
fi

if [[ ${#skipped_envs[@]} -ne 0 ]]; then
  echo "Skipped environments: ${skipped_envs[@]}"
fi

if [[ ${#failed_envs[@]} -ne 0 ]]; then
  echo "ERROR: could not perform terraform apply for environments: ${failed_envs[@]}"
  echo "Refer to previous errors for details."
  exit 1
fi
