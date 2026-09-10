#!/usr/bin/env bash
set -euo pipefail

# Exercises the Bedrock batch inference path end-to-end against a live AI Gateway:
# upload input file -> create batch -> poll until terminal -> download output.
# Bedrock batch inference jobs require a minimum of 100 records, hence the size
# of batch-inference-sample.jsonl alongside this script.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INPUT_FILE="${SCRIPT_DIR}/batch-inference-sample.jsonl"
OUTPUT_FILE="${SCRIPT_DIR}/batch-inference-output.jsonl"
MODEL="bedrock-batch-claude-haiku-4-5"
POLL_INTERVAL_SECONDS=10

GREEN="\033[0;32m"
RED="\033[0;31m"
YELLOW="\033[0;33m"
RESET="\033[0m"

info() { echo -e "${YELLOW}==>${RESET} $1"; }
pass() { echo -e "${GREEN}✓${RESET} $1"; }
fail() { echo -e "${RED}✗${RESET} $1"; exit 1; }

if [[ -z "${AWS_SSO_PROFILE:-}" ]]; then
  fail "AWS_SSO_PROFILE not set, please run 'aws-sso exec ...' for example 'aws-sso exec --profile data-platform-development:platform-engineer-admin'"
fi

if [[ ! -f "${INPUT_FILE}" ]]; then
  fail "Sample batch input file not found at ${INPUT_FILE}"
fi

ENVIRONMENT="$(cut -d: -f1 <<< "${AWS_SSO_PROFILE#data-platform-}")"

if [[ "${ENVIRONMENT}" == "production" ]]; then
  AI_GATEWAY_URL="https://ai-gateway.justice.gov.uk"
else
  AI_GATEWAY_URL="https://${ENVIRONMENT}.ai-gateway.justice.gov.uk"
fi

AI_GATEWAY_MASTER_KEY=$(aws secretsmanager get-secret-value --secret-id ai-gateway/litellm-master-key --query SecretString --output text)

info "Uploading ${INPUT_FILE} for model ${MODEL}"
UPLOAD_RESPONSE=$(curl --silent --fail \
  --request POST \
  --url "${AI_GATEWAY_URL}/files" \
  --header "Authorization: Bearer ${AI_GATEWAY_MASTER_KEY}" \
  --form "purpose=batch" \
  --form "target_model_names=${MODEL}" \
  --form "file=@${INPUT_FILE};type=application/jsonl")

INPUT_FILE_ID=$(jq -r '.id // empty' <<< "${UPLOAD_RESPONSE}")
[[ -n "${INPUT_FILE_ID}" ]] || fail "File upload failed: ${UPLOAD_RESPONSE}"
pass "Uploaded input file: ${INPUT_FILE_ID}"

info "Creating batch job"
BATCH_RESPONSE=$(curl --silent --fail \
  --request POST \
  --url "${AI_GATEWAY_URL}/batches" \
  --header "Authorization: Bearer ${AI_GATEWAY_MASTER_KEY}" \
  --header "Content-Type: application/json" \
  --data "$(jq -n --arg input_file_id "${INPUT_FILE_ID}" '{input_file_id: $input_file_id, endpoint: "/v1/chat/completions", completion_window: "24h"}')")

BATCH_ID=$(jq -r '.id // empty' <<< "${BATCH_RESPONSE}")
[[ -n "${BATCH_ID}" ]] || fail "Batch creation failed: ${BATCH_RESPONSE}"
pass "Created batch: ${BATCH_ID}"

info "Polling batch status every ${POLL_INTERVAL_SECONDS}s (Bedrock batch jobs run asynchronously and can take a while)"
STATUS_RESPONSE=""
STATUS=""
while true; do
  STATUS_RESPONSE=$(curl --silent --fail \
    --request GET \
    --url "${AI_GATEWAY_URL}/batches/${BATCH_ID}" \
    --header "Authorization: Bearer ${AI_GATEWAY_MASTER_KEY}")
  STATUS=$(jq -r '.status // empty' <<< "${STATUS_RESPONSE}")
  echo "  status: ${STATUS}"
  case "${STATUS}" in
    completed | failed | expired | cancelled) break ;;
  esac
  sleep "${POLL_INTERVAL_SECONDS}"
done

[[ "${STATUS}" == "completed" ]] || fail "Batch did not complete successfully (status: ${STATUS}): ${STATUS_RESPONSE}"
pass "Batch completed"

OUTPUT_FILE_ID=$(jq -r '.output_file_id // empty' <<< "${STATUS_RESPONSE}")
[[ -n "${OUTPUT_FILE_ID}" ]] || fail "Completed batch has no output_file_id: ${STATUS_RESPONSE}"

info "Downloading output file: ${OUTPUT_FILE_ID}"
curl --silent --fail \
  --request GET \
  --url "${AI_GATEWAY_URL}/files/${OUTPUT_FILE_ID}/content" \
  --header "Authorization: Bearer ${AI_GATEWAY_MASTER_KEY}" \
  --header "custom-llm-provider: bedrock" \
  --output "${OUTPUT_FILE}"

pass "Saved output to ${OUTPUT_FILE}"
