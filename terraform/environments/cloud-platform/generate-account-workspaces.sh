#!/bin/bash

set -euo pipefail

# Creates Terraform workspaces for every account in accounts.json.
# Workspaces are created in the cloud-platform Terraform root and in
# every subdirectory under cloud-platform that contains Terraform files.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ACCOUNTS_FILE="${SCRIPT_DIR}/accounts.json"
DRY_RUN=false

usage() {
  cat <<EOF
Usage: $(basename "$0") [--dry-run]

Options:
  --dry-run   Show what would be done without changing Terraform workspaces.
  -h, --help  Show this help message.
EOF
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --dry-run)
      DRY_RUN=true
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1"
      usage
      exit 1
      ;;
  esac
  shift
done

if ! command -v jq >/dev/null 2>&1; then
  echo "jq is required but not installed"
  exit 1
fi

if ! command -v terraform >/dev/null 2>&1; then
  echo "terraform is required but not installed"
  exit 1
fi

if [ ! -f "${ACCOUNTS_FILE}" ]; then
  echo "accounts.json not found at ${ACCOUNTS_FILE}"
  exit 1
fi

terraform_dirs=()

# Include the cloud-platform root if it contains Terraform files.
if compgen -G "${SCRIPT_DIR}/*.tf" >/dev/null; then
  terraform_dirs+=("${SCRIPT_DIR}")
fi

# Include all subfolders under cloud-platform that contain Terraform files.
while IFS= read -r -d '' dir; do
  if compgen -G "${dir}/*.tf" >/dev/null; then
    terraform_dirs+=("${dir}")
  fi
done < <(find "${SCRIPT_DIR}" -mindepth 1 -type d ! -name ".terraform" ! -path "*/.terraform/*" -print0)

if [ "${#terraform_dirs[@]}" -eq 0 ]; then
  echo "No Terraform folders found under ${SCRIPT_DIR}"
  exit 1
fi

# Ensure deterministic ordering and remove duplicates.
sorted_terraform_dirs=()
while IFS= read -r dir; do
  sorted_terraform_dirs+=("${dir}")
done < <(printf '%s\n' "${terraform_dirs[@]}" | sort -u)
terraform_dirs=("${sorted_terraform_dirs[@]}")

accounts=()
while IFS= read -r account; do
  accounts+=("${account}")
done < <(jq -r '.accounts[]' "${ACCOUNTS_FILE}")

if [ "${#accounts[@]}" -eq 0 ]; then
  echo "No accounts found in ${ACCOUNTS_FILE}"
  exit 1
fi

created_count=0
existing_count=0
planned_create_count=0

for dir in "${terraform_dirs[@]}"; do
  echo "Processing Terraform directory: ${dir}"

  if [ "${DRY_RUN}" = true ]; then
    echo "  [DRY RUN] Would ensure Terraform is initialised if required"
  else
    # Initialise if needed before managing workspaces.
    if ! terraform -chdir="${dir}" workspace list >/dev/null 2>&1; then
      terraform -chdir="${dir}" init -input=false -no-color >/dev/null
    fi
  fi

  for account in "${accounts[@]}"; do
    if [ "${DRY_RUN}" = true ]; then
      if terraform -chdir="${dir}" workspace list | sed 's/^[* ]*//' | grep -Fxq "${account}"; then
        echo "  [DRY RUN] Exists: ${account}"
        existing_count=$((existing_count + 1))
      else
        echo "  [DRY RUN] Would create: ${account}"
        planned_create_count=$((planned_create_count + 1))
      fi
    else
      if terraform -chdir="${dir}" workspace select "${account}" >/dev/null 2>&1; then
        echo "  Exists: ${account}"
        existing_count=$((existing_count + 1))
      else
        terraform -chdir="${dir}" workspace new "${account}" >/dev/null
        echo "  Created: ${account}"
        created_count=$((created_count + 1))
      fi
    fi
  done
done

if [ "${DRY_RUN}" = true ]; then
  printf 'Dry run complete: would_create=%s already_exists=%s directories=%s accounts=%s\n' \
    "${planned_create_count}" "${existing_count}" "${#terraform_dirs[@]}" "${#accounts[@]}"
else
  printf 'Terraform workspace creation complete: created=%s already_exists=%s directories=%s accounts=%s\n' \
    "${created_count}" "${existing_count}" "${#terraform_dirs[@]}" "${#accounts[@]}"
fi
