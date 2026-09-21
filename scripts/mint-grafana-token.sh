#!/usr/bin/env bash
#
# Mint a short-lived Amazon Managed Grafana (AMG) service account token so the
# Grafana Terraform provider can manage Grafana-internal objects (teams, data
# sources, permissions) — see grafana-objects.tf and cloud-platform#8509.
#
# AMG service account tokens are short-lived (1h here, AMG max 30 days), so one
# is minted per run rather than stored. The AMG workspace is discovered by name
# from WORKSPACE_NAME, so no extra inputs are needed, and this no-ops (exit 0)
# where there is no AMG workspace or iac-grafana-objects service account. If
# both exist but the token mint itself fails, that is a real error and the
# script exits non-zero.
#
# Token quota: AMG caps the number of tokens per service account and counts
# EXPIRED tokens against that cap until they are deleted, so minting without
# deleting eventually wedges the pipeline. Two things prevent that:
#   1. This script prunes already-expired tokens before minting (self-healing,
#      covers runs that died before their cleanup step ran).
#   2. delete-grafana-token.sh removes this run's token, called from an
#      `if: always()` step at the end of the job.
#
# On success it exports to GITHUB_ENV, for later steps in the same job:
#   GRAFANA_AUTH               the token (masked in logs)
#   TF_VAR_grafana_url         the workspace endpoint
#   GRAFANA_WORKSPACE_ID       \
#   GRAFANA_SERVICE_ACCOUNT_ID  } consumed by delete-grafana-token.sh
#   GRAFANA_TOKEN_ID           /
#
# Required environment:
#   WORKSPACE_NAME  Terraform workspace name; the AMG workspace is expected to be
#                   named "${WORKSPACE_NAME}-observability".
#   GITHUB_ENV      Path GitHub Actions reads env exports from (set by the runner).
#   GITHUB_RUN_ID, GITHUB_JOB  Used to name the minted token for traceability.
#
# CI-only: assumes GNU date (for token expiry comparison) and GITHUB_ENV.

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

#------------------------------------------------------------------------------
# Prune expired tokens so they stop consuming the per-service-account quota.
#
# Only ALREADY-EXPIRED tokens are deleted. An expired token is useless to any
# holder, so this is safe even when another job is mid-run: that job's token is
# still valid and is therefore left alone.
#
# Deliberately non-fatal. Pruning is hygiene, not the job's purpose, and the
# pipeline roles may not yet hold grafana:DeleteWorkspaceServiceAccountToken.
#------------------------------------------------------------------------------
prune_expired_tokens() {
  local now expired_ids id expires expires_epoch
  now=$(date -u +%s)

  if ! expired_ids=$(aws grafana list-workspace-service-account-tokens \
    --workspace-id "${ws_id}" --service-account-id "${sa_id}" \
    --query 'serviceAccountTokens[].[id,expiresAt]' --output text 2>&1); then
    echo "Note: could not list AMG tokens for pruning (${expired_ids}); continuing."
    return 0
  fi

  local pruned=0
  while IFS=$'\t' read -r id expires; do
    [ -n "${id:-}" ] || continue
    # Skip anything whose expiry we cannot parse rather than guessing.
    expires_epoch=$(date -u -d "${expires}" +%s 2>/dev/null) || continue
    [ "${expires_epoch}" -lt "${now}" ] || continue
    if aws grafana delete-workspace-service-account-token \
      --workspace-id "${ws_id}" --service-account-id "${sa_id}" \
      --token-id "${id}" >/dev/null 2>&1; then
      pruned=$((pruned + 1))
    else
      echo "Note: could not delete expired AMG token ${id}; continuing."
    fi
  done <<< "${expired_ids}"

  [ "${pruned}" -eq 0 ] || echo "Pruned ${pruned} expired AMG token(s) from ${amg_name}."
}

prune_expired_tokens || echo "Note: AMG token pruning failed; continuing."

#------------------------------------------------------------------------------
# Mint this run's token.
#
# Both the plan and apply roles can mint tokens (plan role granted
# grafana:CreateWorkspaceServiceAccountToken in
# ministryofjustice/modernisation-platform#14006). The workspace and the
# iac-grafana-objects service account both exist at this point, so a mint
# failure here is a real error (API/permissions/quota/throttling), not an
# expected no-op — fail loudly rather than plan/apply with the Grafana provider
# silently unauthenticated.
#
# id and key are read from one call: the id is needed to delete the token in the
# job's cleanup step, and CreateWorkspaceServiceAccountToken returns the key
# only once, so it cannot be looked up again afterwards.
#------------------------------------------------------------------------------
if ! token_fields=$(aws grafana create-workspace-service-account-token \
  --workspace-id "${ws_id}" --service-account-id "${sa_id}" \
  --name "tf-${GITHUB_RUN_ID}-${GITHUB_JOB}" --seconds-to-live 3600 \
  --query 'serviceAccountToken.[id,key]' --output text 2>&1); then
  echo "::error::Failed to mint AMG token for ${amg_name}: ${token_fields}"
  exit 1
fi

token_id=$(printf '%s' "${token_fields}" | cut -f1)
token=$(printf '%s' "${token_fields}" | cut -f2)
echo "::add-mask::${token}"

if [ -z "${token}" ] || [ "${token}" = "None" ]; then
  echo "::error::AMG returned an empty token for ${amg_name}."
  exit 1
fi

{
  echo "GRAFANA_AUTH=${token}"
  echo "TF_VAR_grafana_url=${endpoint}"
  echo "GRAFANA_WORKSPACE_ID=${ws_id}"
  echo "GRAFANA_SERVICE_ACCOUNT_ID=${sa_id}"
  echo "GRAFANA_TOKEN_ID=${token_id}"
} >> "${GITHUB_ENV}"

echo "Grafana provider configured for ${amg_name} (token ${token_id}, valid 1h)."
