#!/usr/bin/env bash
#
# Mint a short-lived Amazon Managed Grafana (AMG) service account token so the
# Grafana Terraform provider can manage Grafana-internal objects (teams, data
# sources, permissions) — see grafana-objects.tf and cloud-platform#8509.
#
# AMG service account tokens are short-lived (max 30 days), so one is minted per
# run rather than stored. The AMG workspace is discovered by name from
# WORKSPACE_NAME, so no extra inputs are needed, and this no-ops (exit 0) where
# there is no AMG workspace or iac-grafana-objects service account. If both
# exist but the token mint itself fails, that is a real error and the script
# exits non-zero.
#
# On success it exports GRAFANA_AUTH (the token) and TF_VAR_grafana_url (the
# workspace endpoint) to GITHUB_ENV for later steps in the same job.
#
# Required environment:
#   WORKSPACE_NAME  Terraform workspace name; the AMG workspace is expected to be
#                   named "${WORKSPACE_NAME}-observability".
#   GITHUB_ENV      Path GitHub Actions reads env exports from (set by the runner).
#   GITHUB_RUN_ID, GITHUB_JOB  Used to name the minted token for traceability.

set -euo pipefail

amg_name="${WORKSPACE_NAME}-observability"

ws_id=$(aws grafana list-workspaces \
  --query "workspaces[?name=='${amg_name}'].id | [0]" --output text)
if [ -z "${ws_id}" ] || [ "${ws_id}" = "None" ]; then
  echo "No AMG workspace named ${amg_name}; skipping Grafana token."
  exit 0
fi

sa_id=$(aws grafana list-workspace-service-accounts --workspace-id "${ws_id}" \
  --query "serviceAccounts[?name=='iac-grafana-objects'].id | [0]" --output text)
if [ -z "${sa_id}" ] || [ "${sa_id}" = "None" ]; then
  echo "No iac-grafana-objects service account on ${amg_name}; skipping Grafana token."
  exit 0
fi

endpoint=$(aws grafana describe-workspace --workspace-id "${ws_id}" \
  --query 'workspace.endpoint' --output text)

# Both the plan and apply roles can mint tokens (plan role granted
# grafana:CreateWorkspaceServiceAccountToken in
# ministryofjustice/modernisation-platform#14006). The workspace and the
# iac-grafana-objects service account both exist at this point, so a mint
# failure here is a real error (API/permissions/throttling), not an expected
# no-op — fail loudly rather than plan/apply with the Grafana provider silently
# unauthenticated.
if ! token=$(aws grafana create-workspace-service-account-token \
  --workspace-id "${ws_id}" --service-account-id "${sa_id}" \
  --name "tf-${GITHUB_RUN_ID}-${GITHUB_JOB}" --seconds-to-live 3600 \
  --query 'serviceAccountToken.key' --output text 2>&1); then
  echo "::error::Failed to mint AMG token for ${amg_name}: ${token}"
  exit 1
fi

echo "::add-mask::${token}"
echo "GRAFANA_AUTH=${token}" >> "${GITHUB_ENV}"
echo "TF_VAR_grafana_url=${endpoint}" >> "${GITHUB_ENV}"
echo "Grafana provider configured for ${amg_name} (token valid 1h)."
