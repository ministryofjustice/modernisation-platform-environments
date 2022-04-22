#!/bin/bash

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

nuked_envs=()
skipped_envs=()
failed_envs=()
for d in terraform/environments/*; do
  dir_name=$(basename "$d")
  if [[ "$NUKE_SKIP_ENVIRONMENTS" != *"${dir_name},"* ]]; then
    echo "Search for development workspace to nuke in $d"
    exit_code=0
    bash scripts/terraform-init.sh "$d" || exit_code=$?
    tf_workspaces=$(terraform -chdir="$d" workspace list) || exit_code=$?
    if [ $exit_code -ne 0 ]; then
      failed_envs+=("$dir_name")
    else
      if [[ "$tf_workspaces" == *"${dir_name}-development"* ]]; then
        if [[ "$NUKE_SKIP_ENVIRONMENTS" != *"${dir_name}-development,"* ]]; then
          echo "BEGIN: nuke ${dir_name}-development"
          dir_name_upper_case=$(echo "${dir_name^^}" | tr '-' '_')
          acc_id_var_name="${dir_name_upper_case}_DEVELOPMENT_ACCID"
          acc_id=${!acc_id_var_name} # Evaluate the variable name stored in acc_id_var_name
          eval $(aws sts assume-role --role-arn "arn:aws:iam::${acc_id}:role/MemberInfrastructureAccess" --role-session-name "${dir_name_upper_case}_DEVELOPMENT_ACCID_SESSION" | jq -r '.Credentials | "export AWS_ACCESS_KEY_ID=\(.AccessKeyId)\nexport AWS_SECRET_ACCESS_KEY=\(.SecretAccessKey)\nexport AWS_SESSION_TOKEN=\(.SessionToken)\n"')

          $HOME/bin/aws-nuke --access-key-id "$AWS_ACCESS_KEY_ID" \
            --secret-access-key "$AWS_SECRET_ACCESS_KEY" \
            --session-token "$AWS_SESSION_TOKEN" \
            --config nuke-config.yml \
            --force \
            --no-dry-run || exit_code=$?

          if [ $exit_code -ne 0 ]; then
            failed_envs+=("${dir_name}-development")
          else
            nuked_envs+=("${dir_name}-development")
          fi
          echo "END: nuke ${dir_name}-development"
        else
          echo "Skipped nuking ${dir_name}-development because of the env variable NUKE_SKIP_ENVIRONMENTS=${NUKE_SKIP_ENVIRONMENTS}"
          skipped_envs+=("${dir_name}-development")
        fi
      else
        echo "No development workspace was found to nuke in $d"
      fi
    fi
  else
    echo "Skipped nuking ${dir_name} because of the env variable NUKE_SKIP_ENVIRONMENTS=${NUKE_SKIP_ENVIRONMENTS}"
    skipped_envs+=("${dir_name}")
  fi
done

echo "Nuke complete: ${#nuked_envs[@]} nuked, ${#skipped_envs[@]} skipped, ${#failed_envs[@]} failed."

if [ ${#nuked_envs[@]} -ne 0 ]; then
  echo "Nuked environments: ${nuked_envs[@]}"
fi

if [ ${#skipped_envs[@]} -ne 0 ]; then
  echo "Skipped environments: ${skipped_envs[@]}"
fi

if [ ${#failed_envs[@]} -ne 0 ]; then
  echo "ERROR: could not nuke environments: ${failed_envs[@]}"
  echo "Refer to previous errors for details."
  exit 1
fi
