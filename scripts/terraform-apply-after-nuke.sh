#!/bin/bash

set -euo pipefail

for d in terraform/environments/*; do
  dir_name=$(basename "$d")
  dir_name_upper_case=${dir_name^^}
  echo "Search for development workspace to perform terraform apply in $d"
  bash scripts/terraform-init.sh "$d"
  tf_workspaces=$(terraform -chdir="$d" workspace list)
  if [[ "$tf_workspaces" == *"${dir_name}-development"* ]]; then
    if [[ "$NUKE_SKIP_ENVIRONMENTS" != *"${dir_name}-development"* ]]; then
      echo "BEGIN: terraform apply ${dir_name}-development"
      terraform -chdir="$d" workspace select "${dir_name}-development"
      bash scripts/terraform-apply.sh "$d"
      echo "END: terraform apply ${dir_name}-development"
    else
      echo "Skipped terraform apply for ${dir_name}-development because of the env variable NUKE_SKIP_ENVIRONMENTS=${NUKE_SKIP_ENVIRONMENTS}"
    fi
  else
    echo "No development workspace was found to perform terraform apply in $d"
  fi
done
