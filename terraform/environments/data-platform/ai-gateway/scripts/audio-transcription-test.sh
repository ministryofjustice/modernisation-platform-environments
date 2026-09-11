#!/usr/bin/env bash

if [[ -z "${AWS_SSO_PROFILE}" ]]; then
  echo "AWS_SSO_PROFILE not set, please run 'aws-sso exec ...' for example 'aws-sso exec --profile data-platform-development:platform-engineer-admin'"
  exit 1
fi

AUDIO_FILE="$1"
MODEL="${2:-gemini-3-5-transcribe-preview}"

if [[ -z "${AUDIO_FILE}" || ! -f "${AUDIO_FILE}" ]]; then
  echo "Usage: $0 <path-to-audio-file> [model]"
  echo "e.g. $0 sample.wav gemini-3-5-transcribe-preview"
  exit 1
fi

FORMAT="${AUDIO_FILE##*.}"

ENVIRONMENT="$(cut -d: -f1 <<< "${AWS_SSO_PROFILE#data-platform-}")"

if [[ "${ENVIRONMENT}" == "production" ]]; then
  AI_GATEWAY_URL="https://ai-gateway.justice.gov.uk"
  AI_GATEWAY_ADMIN_URL="https://admin.ai-gateway.justice.gov.uk"
else
  AI_GATEWAY_URL="https://${ENVIRONMENT}.ai-gateway.justice.gov.uk"
  AI_GATEWAY_ADMIN_URL="https://admin.${ENVIRONMENT}.ai-gateway.justice.gov.uk"
fi

AI_GATEWAY_MASTER_KEY=$(aws secretsmanager get-secret-value --secret-id ai-gateway/litellm-master-key --query SecretString --output text)

AUDIO_BASE64=$(base64 -w0 "${AUDIO_FILE}")

jq -n --arg model "${MODEL}" --arg audio "${AUDIO_BASE64}" --arg format "${FORMAT}" \
  '{model: $model, messages: [{role: "user", content: [{type: "input_audio", input_audio: {data: $audio, format: $format}}]}]}' \
  | curl \
    --silent \
    --request POST \
    --url "${AI_GATEWAY_URL}/chat/completions" \
    --header "Content-Type: application/json" \
    --header "Authorization: Bearer ${AI_GATEWAY_MASTER_KEY}" \
    --data @- | jq .
