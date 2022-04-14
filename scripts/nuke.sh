#!/bin/bash

set -euo pipefail

# Parse the env variable NUKE_ACCOUNT_IDS which holds a JSON string of account IDs. Example value held in
# NUKE_ACCOUNT_IDS is as follows
#    NUKE_ACCOUNT_IDS='
#    {
#      "NUKE_ACCOUNT_IDS": {
#        "SPRINKLER_DEVELOPMENT_ACCID": "111111111111",
#        "COOKER_DEVELOPMENT_ACCID": "222222222222"
#      }
#    }'
# Export the account IDs to env variables, for example: export SPRINKLER_DEVELOPMENT_ACCID=111111111111
eval "$(jq -r '.NUKE_ACCOUNT_IDS | to_entries | .[] |"export " + .key + "=" + (.value | @sh)' <<<"$NUKE_ACCOUNT_IDS")"

# Generate nuke-config.yml interpolating env variables with account IDs.
cat ./scripts/nuke-config-template.txt | envsubst >nuke-config.yml

export AWS_REGION=eu-west-2

for d in terraform/environments/*; do
  dir_name=$(basename "$d")
  dir_name_upper_case=${dir_name^^}
  echo "Search for development workspace to nuke in $d"
  bash scripts/terraform-init.sh "$d"
  tf_workspaces=$(terraform -chdir="$d" workspace list)
  if [[ "$tf_workspaces" == *"${dir_name}-development"* ]]; then
    if [[ "$NUKE_SKIP_ENVIRONMENTS" != *"${dir_name}-development"* ]]; then
      echo "BEGIN: nuke ${dir_name}-development"
      acc_id_var_name="${dir_name_upper_case}_DEVELOPMENT_ACCID"
      acc_id=${!acc_id_var_name}
      echo "acc_id = $acc_id"
      eval $(aws sts assume-role --role-arn "arn:aws:iam::${acc_id}:role/MemberInfrastructureAccess" --role-session-name "${dir_name_upper_case}_DEVELOPMENT_ACCID_SESSION" | jq -r '.Credentials | "export AWS_ACCESS_KEY_ID=\(.AccessKeyId)\nexport AWS_SECRET_ACCESS_KEY=\(.SecretAccessKey)\nexport AWS_SESSION_TOKEN=\(.SessionToken)\n"')

      $HOME/bin/aws-nuke --access-key-id "$AWS_ACCESS_KEY_ID" \
        --secret-access-key "$AWS_SECRET_ACCESS_KEY" \
        --session-token "$AWS_SESSION_TOKEN" \
        --config nuke-config.yml \
        --force
      #        --no-dry-run
      echo "END: nuke ${dir_name}-development"
    else
      echo "Skipped nuking ${dir_name}-development because of the env variable NUKE_SKIP_ENVIRONMENTS=${NUKE_SKIP_ENVIRONMENTS}"
    fi
  else
    echo "No development workspace was found to nuke in $d"
  fi
done
