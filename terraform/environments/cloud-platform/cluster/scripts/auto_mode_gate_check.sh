#!/usr/bin/env bash

set -euo pipefail

cluster="$1"
region="$2"

for i in $(seq 1 120); do
  running=0

  for id in $(aws eks list-updates \
    --name "$cluster" \
    --region "$region" \
    --query 'updateIds' \
    --output text | tr '\t' '\n'); do

    [ -z "$id" ] && continue

    status=$(aws eks describe-update \
      --name "$cluster" \
      --update-id "$id" \
      --region "$region" \
      --query 'update.status' \
      --output text 2>/dev/null || echo Unknown)

    [ "$status" = "InProgress" ] && running=$((running + 1))
  done

  [ "$running" -eq 0 ] && exit 0

  sleep 5
done

echo "auto_mode gate: cluster $cluster still updating after timeout" >&2
exit 1