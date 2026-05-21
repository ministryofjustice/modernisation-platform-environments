#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 2 ]]; then
  echo "Usage: $0 <api-key> <environment>" >&2
  echo "  environment: development, test, preproduction, production" >&2
  exit 1
fi

API_KEY="$1"
ENV="$2"

curl https://${ENV}.ai-gateway.justice.gov.uk/chat/completions \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer ${API_KEY}" \
  -d '{"model":"bedrock-claude-opus-4-7","messages":[{"role":"user","content":"This is a test script. Please ignore."}]}'
