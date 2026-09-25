#!/usr/bin/env bash
#
# Delete the AMG service account token minted by mint-grafana-token.sh for this
# job, so it stops consuming the per-service-account token quota.
#
# AMG counts EXPIRED tokens against the quota until they are deleted, so a
# pipeline that mints per run without deleting eventually fails to mint at all.
# Call this from a step with `if: always()` so the token is removed even when the
# Terraform plan or apply failed.
#
# Deliberately never fails the job: by the time this runs the real work is done,
# and the pipeline roles may not yet hold
# grafana:DeleteWorkspaceServiceAccountToken. Leftovers are cleaned up by the
# expired-token prune in mint-grafana-token.sh on a later run.
#
# Reads the identifiers exported to GITHUB_ENV by mint-grafana-token.sh. If they
# are absent the mint was skipped or failed, and this exits quietly.

set -uo pipefail

ws_id="${GRAFANA_WORKSPACE_ID:-}"
sa_id="${GRAFANA_SERVICE_ACCOUNT_ID:-}"
token_id="${GRAFANA_TOKEN_ID:-}"

if [ -z "${ws_id}" ] || [ -z "${sa_id}" ] || [ -z "${token_id}" ]; then
  echo "No AMG token was minted in this job; nothing to clean up."
  exit 0
fi

if err=$(aws grafana delete-workspace-service-account-token \
  --workspace-id "${ws_id}" --service-account-id "${sa_id}" \
  --token-id "${token_id}" 2>&1); then
  echo "Deleted AMG token ${token_id}."
else
  echo "Note: could not delete AMG token ${token_id} (${err})."
  echo "It will be pruned on a later run once expired."
fi

exit 0
