#!/bin/bash

failed_envs=()
for d in terraform/environments/*; do
  exit_code=0
  dir_name=$(basename "$d")
  echo "Search for development workspace to perform terraform apply in $d"
  bash scripts/terraform-init.sh "$d" || exit_code=$?
  tf_workspaces=$(terraform -chdir="$d" workspace list) || exit_code=$?
  if [ $exit_code -ne 0 ]; then
    failed_envs+=("$dir_name")
  else
    if [[ "$tf_workspaces" == *"${dir_name}-development"* ]]; then
      if [[ "$NUKE_SKIP_ENVIRONMENTS" != *"${dir_name}-development"* ]]; then
        if [[ "$NUKE_DO_NOT_RECREATE_ENVIRONMENTS" != *"${dir_name}-development"* ]]; then
          echo "BEGIN: terraform apply ${dir_name}-development"
          terraform -chdir="$d" workspace select "${dir_name}-development" || exit_code=$?
          bash scripts/terraform-apply.sh "$d" || exit_code=$?
          if [ $exit_code -ne 0 ]; then
            failed_envs+=("${dir_name}-development")
          fi
          echo "END: terraform apply ${dir_name}-development"
        else
          echo "Skipped terraform apply for ${dir_name}-development because of the env variable NUKE_DO_NOT_RECREATE_ENVIRONMENTS=${NUKE_DO_NOT_RECREATE_ENVIRONMENTS}"
        fi
      else
        echo "Skipped terraform apply for ${dir_name}-development because of the env variable NUKE_SKIP_ENVIRONMENTS=${NUKE_SKIP_ENVIRONMENTS}"
      fi
    else
      echo "No development workspace was found to perform terraform apply in $d"
    fi
  fi
done

if [ ${#failed_envs[@]} -ne 0 ]; then
  echo "ERROR: could not perform terraform apply for environments: ${failed_envs[@]}"
  echo "Refer to previous errors for details."
  exit 1
fi
