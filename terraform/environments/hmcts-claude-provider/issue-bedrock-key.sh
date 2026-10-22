#!/usr/bin/env bash
set -euo pipefail

# Issues a Bedrock API key to one named person, so invocation logs attribute usage to them.
# Each person gets their own IAM user (BedrockAPIKey-<name>) and their own revocable credential.

ACCOUNT_ID="313941174580"
ROLE_ARN="arn:aws:iam::${ACCOUNT_ID}:role/BedrockAPIKeyCreator"
POLICY_ARN="arn:aws:iam::${ACCOUNT_ID}:policy/HMCTSClaudeBedrockPolicy"
PROFILE="${AWS_PROFILE:-hmcts-claude-provider-development}"
SERVICE="bedrock.amazonaws.com"
CREDENTIAL_AGE_DAYS=90

usage() {
  cat >&2 <<EOF
Usage: $(basename "$0") <name> [--rotate] [--revoke]

  <name>     the person's username, lowercase, e.g. linus.norton
  --rotate   replace an existing credential (the old one stops working)
  --revoke   delete the person's credentials and exit, issuing nothing

Examples:
  $(basename "$0") linus.norton
  $(basename "$0") linus.norton --rotate
  $(basename "$0") someone.leaving --revoke
EOF
  exit 1
}

NAME=""
ROTATE=false
REVOKE=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --rotate) ROTATE=true ;;
    --revoke) REVOKE=true ;;
    -h | --help) usage ;;
    -*) echo "Unknown option: $1" >&2; usage ;;
    *) [[ -n "$NAME" ]] && usage; NAME="$1" ;;
  esac
  shift
done

[[ -n "$NAME" ]] || usage

if ! [[ "$NAME" =~ ^[a-z0-9]+([.-][a-z0-9]+)*$ ]]; then
  echo "Name must be lowercase letters, digits, dots and dashes, e.g. linus.norton" >&2
  exit 1
fi

USER_NAME="BedrockAPIKey-${NAME}"

for tool in aws jq; do
  command -v "$tool" >/dev/null || { echo "$tool is required" >&2; exit 1; }
done

echo "Assuming BedrockAPIKeyCreator (bypasses the common_policy deny on IAM user creation)..."
CREDS=$(aws sts assume-role \
  --role-arn "$ROLE_ARN" \
  --role-session-name "issue-bedrock-key-$(date +%s)" \
  --profile "$PROFILE" \
  --query 'Credentials.[AccessKeyId,SecretAccessKey,SessionToken]' \
  --output text)

AWS_ACCESS_KEY_ID=$(awk '{print $1}' <<<"$CREDS")
AWS_SECRET_ACCESS_KEY=$(awk '{print $2}' <<<"$CREDS")
AWS_SESSION_TOKEN=$(awk '{print $3}' <<<"$CREDS")
export AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_SESSION_TOKEN
unset AWS_PROFILE

existing_credential_ids() {
  aws iam list-service-specific-credentials \
    --user-name "$USER_NAME" \
    --service-name "$SERVICE" \
    --query 'ServiceSpecificCredentials[].ServiceSpecificCredentialId' \
    --output text 2>/dev/null || true
}

delete_credentials() {
  local ids="$1" id
  for id in $ids; do
    echo "  Deleting credential $id"
    aws iam delete-service-specific-credential \
      --user-name "$USER_NAME" --service-specific-credential-id "$id"
  done
}

if [[ "$REVOKE" == true ]]; then
  if ! aws iam get-user --user-name "$USER_NAME" >/dev/null 2>&1; then
    echo "No IAM user $USER_NAME - nothing to revoke"
    exit 0
  fi
  IDS=$(existing_credential_ids)
  if [[ -z "${IDS// /}" ]]; then
    echo "No Bedrock credentials for $USER_NAME"
  else
    delete_credentials "$IDS"
    echo "Revoked. $NAME can no longer call Bedrock."
  fi
  echo "The IAM user remains, so past usage stays attributable in the invocation logs."
  exit 0
fi

if aws iam get-user --user-name "$USER_NAME" >/dev/null 2>&1; then
  echo "IAM user $USER_NAME already exists"
else
  echo "Creating IAM user $USER_NAME"
  aws iam create-user \
    --user-name "$USER_NAME" \
    --tags "Key=owner,Value=${NAME}" "Key=purpose,Value=claude-code" >/dev/null
fi

aws iam attach-user-policy --user-name "$USER_NAME" --policy-arn "$POLICY_ARN"

IDS=$(existing_credential_ids)
if [[ -n "${IDS// /}" ]]; then
  if [[ "$ROTATE" == true ]]; then
    echo "Rotating: removing existing credentials"
    delete_credentials "$IDS"
  else
    echo "" >&2
    echo "$NAME already has a Bedrock credential:" >&2
    aws iam list-service-specific-credentials \
      --user-name "$USER_NAME" --service-name "$SERVICE" \
      --query 'ServiceSpecificCredentials[].{Id:ServiceSpecificCredentialId,Status:Status,Created:CreateDate,Expires:ExpirationDate}' \
      --output table >&2
    echo "Re-run with --rotate to replace it, or --revoke to remove it." >&2
    exit 1
  fi
fi

echo "Creating Bedrock credential (expires after ${CREDENTIAL_AGE_DAYS} days)"
RESULT=$(aws iam create-service-specific-credential \
  --user-name "$USER_NAME" \
  --service-name "$SERVICE" \
  --credential-age-days "$CREDENTIAL_AGE_DAYS")

TOKEN=$(jq -r '.ServiceSpecificCredential | .ServiceCredentialSecret // .ServicePassword // empty' <<<"$RESULT")
EXPIRES=$(jq -r '.ServiceSpecificCredential.ExpirationDate // "unknown"' <<<"$RESULT")

if [[ -z "$TOKEN" ]]; then
  echo "Could not read the credential from the API response - check your AWS CLI version" >&2
  exit 1
fi

cat <<EOF

==========================================================
Bedrock API key issued to ${NAME}
==========================================================
IAM user: ${USER_NAME}
Expires:  ${EXPIRES}

Send the following to ${NAME} over a secure channel. It cannot be
retrieved again - re-run with --rotate if it is lost.

# Claude Code on Bedrock
export AWS_REGION=eu-west-2
export CLAUDE_CODE_USE_BEDROCK=1
export AWS_BEARER_TOKEN_BEDROCK='${TOKEN}'
export ANTHROPIC_DEFAULT_OPUS_MODEL='anthropic.claude-opus-5-5'
export ANTHROPIC_DEFAULT_SONNET_MODEL='anthropic.claude-sonnet-5'
export ANTHROPIC_DEFAULT_HAIKU_MODEL='eu.anthropic.claude-haiku-4-5-20251001-v1:0'

Usage by this person appears in the invocation logs as:
  arn:aws:iam::${ACCOUNT_ID}:user/${USER_NAME}
==========================================================
EOF
