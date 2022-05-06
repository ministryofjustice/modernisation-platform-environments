#!/bin/bash

export AWS_REGION=eu-west-2

# get secret
nuke_account_blocklist_json=$(aws secretsmanager get-secret-value --secret-id nuke_account_blocklist --query 'SecretString' --output text --no-cli-pager)

# Extract the account IDs into the account_blocklist map
declare -A account_blocklist
eval "$(jq -r '.NUKE_ACCOUNT_BLOCKLIST | to_entries | .[] |"account_blocklist[" + (.key | @sh) + "]=" + (.value | @sh)' <<<"$nuke_account_blocklist_json")"

# Generate the accounts blocklist section to be added to nuke-config.yml. These are the accounts that will be EXCLUDED
# from aws-nuke.
account_blocklist_str=''
for key in "${!account_blocklist[@]}"; do
  account_blocklist_str+="  - \"${account_blocklist[$key]}\" # ${key}"
  account_blocklist_str+=$'\n'
done

# get secret
nuke_account_ids_json=$(aws secretsmanager get-secret-value --secret-id nuke_account_ids --query 'SecretString' --output text --no-cli-pager)

# Extract the account IDs into the account_ids map
declare -A account_ids
eval "$(jq -r '.NUKE_ACCOUNT_IDS | to_entries | .[] |"account_ids[" + (.key | @sh) + "]=" + (.value | @sh)' <<<"$nuke_account_ids_json")"

# Generate the accounts section to be added to nuke-config.yml. These are the accounts that will be nuked.
accounts_str=''
for key in "${!account_ids[@]}"; do
  accounts_str+="  \"${account_ids[$key]}\": # ${key}"
  accounts_str+=$'\n'
  accounts_str+="    presets:"
  accounts_str+=$'\n'
  accounts_str+="      - \"common\""
  accounts_str+=$'\n'
done

# Generate nuke-config.yml interpolating env variables with account IDs.
export account_blocklist_str
export accounts_str
cat ./scripts/nuke-config-template.txt | envsubst >nuke-config.yml

nuked_envs=()
failed_envs=()
for key in "${!account_ids[@]}"; do
  echo "BEGIN: nuke ${key}"
  eval $(aws sts assume-role --role-arn "arn:aws:iam::${account_ids[$key]}:role/MemberInfrastructureAccess" --role-session-name "${key}_SESSION" | jq -r '.Credentials | "export AWS_ACCESS_KEY_ID=\(.AccessKeyId)\nexport AWS_SECRET_ACCESS_KEY=\(.SecretAccessKey)\nexport AWS_SESSION_TOKEN=\(.SessionToken)\n"')

  $HOME/bin/aws-nuke --access-key-id "$AWS_ACCESS_KEY_ID" \
    --secret-access-key "$AWS_SECRET_ACCESS_KEY" \
    --session-token "$AWS_SESSION_TOKEN" \
    --config nuke-config.yml \
    --force \
    --no-dry-run || exit_code=$?

  if [[ $exit_code -ne 0 ]]; then
    failed_envs+=("${key}")
  else
    nuked_envs+=("${key}")
  fi
  echo "END: nuke ${key}"
done

echo "Nuke complete: ${#nuked_envs[@]} nuked, ${#failed_envs[@]} failed."

if [[ ${#nuked_envs[@]} -ne 0 ]]; then
  echo "Nuked environments: ${nuked_envs[@]}"
fi

if [[ ${#failed_envs[@]} -ne 0 ]]; then
  echo "ERROR: could not nuke environments: ${failed_envs[@]}"
  echo "Refer to previous errors for details."
  exit 1
fi
