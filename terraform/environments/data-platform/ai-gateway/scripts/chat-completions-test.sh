#!/usr/bin/env bash

if [[ -z "${AWS_SSO_PROFILE}" ]]; then
  echo "AWS_SSO_PROFILE not set, please run 'aws-sso exec ...' for example 'aws-sso exec --profile data-platform-development:platform-engineer-admin'"
  exit 1
fi

ENVIRONMENT="$(cut -d: -f1 <<< "${AWS_SSO_PROFILE#data-platform-}")"

if [[ "${ENVIRONMENT}" == "production" ]]; then
  AI_GATEWAY_URL="https://ai-gateway.justice.gov.uk"
  AI_GATEWAY_ADMIN_URL="https://admin.ai-gateway.justice.gov.uk"
else
  AI_GATEWAY_URL="https://${ENVIRONMENT}.ai-gateway.justice.gov.uk"
  AI_GATEWAY_ADMIN_URL="https://admin.${ENVIRONMENT}.ai-gateway.justice.gov.uk"
fi

AI_GATEWAY_MASTER_KEY=$(aws secretsmanager get-secret-value --secret-id ai-gateway/litellm-master-key --query SecretString --output text)

curl \
  --silent \
  --request POST \
  --url "${AI_GATEWAY_URL}/chat/completions" \
  --header "Content-Type: application/json" \
  --header "Authorization: Bearer ${AI_GATEWAY_MASTER_KEY}" \
  --data '{"model":"bedrock-claude-haiku-4-5","messages":[{"role":"user","content":"PING 🏓"}]}' | jq .
