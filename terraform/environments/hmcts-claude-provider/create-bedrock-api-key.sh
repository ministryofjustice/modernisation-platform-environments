#!/bin/bash
set -e

# Script to create Bedrock API keys by assuming the BedrockAPIKeyCreator role
# This bypasses the common_policy deny on IAM user creation

ROLE_ARN="arn:aws:iam::313941174580:role/BedrockAPIKeyCreator"
REGION="eu-west-1"
NUM_KEYS=${1:-20}  # Default to 20 keys, or pass as first argument

echo "Assuming BedrockAPIKeyCreator role..."
CREDENTIALS=$(aws sts assume-role \
  --role-arn "$ROLE_ARN" \
  --role-session-name "bedrock-api-key-creation-$(date +%s)" \
  --profile hmcts-claude-provider-development \
  --query 'Credentials.[AccessKeyId,SecretAccessKey,SessionToken]' \
  --output text)

if [ -z "$CREDENTIALS" ]; then
  echo "Error: Failed to assume role"
  exit 1
fi

# Parse credentials
export AWS_ACCESS_KEY_ID=$(echo "$CREDENTIALS" | awk '{print $1}')
export AWS_SECRET_ACCESS_KEY=$(echo "$CREDENTIALS" | awk '{print $2}')
export AWS_SESSION_TOKEN=$(echo "$CREDENTIALS" | awk '{print $3}')

echo "Successfully assumed role"
echo ""
echo "Creating $NUM_KEYS Bedrock API keys..."
echo ""

POLICY_ARN="arn:aws:iam::313941174580:policy/HMCTSClaudeBedrockPolicy"

# Arrays to store results
declare -a TOKENS
declare -a USERNAMES
FAILED=0

for i in $(seq 1 $NUM_KEYS); do
  TIMESTAMP=$(date +%Y%m%d-%H%M%S)
  USER_NAME="BedrockAPIKey-hmcts-claude-${TIMESTAMP}-${i}"

  echo "[$i/$NUM_KEYS] Creating user: $USER_NAME"

  # Create IAM user
  if ! aws iam create-user --user-name "$USER_NAME" > /dev/null 2>&1; then
    echo "  ERROR: Failed to create user $USER_NAME"
    ((FAILED++))
    continue
  fi

  # Attach policy
  if ! aws iam attach-user-policy --user-name "$USER_NAME" --policy-arn "$POLICY_ARN" 2>/dev/null; then
    echo "  ERROR: Failed to attach policy to $USER_NAME"
    ((FAILED++))
    continue
  fi

  # Create service-specific credential
  RESULT=$(aws iam create-service-specific-credential \
    --user-name "$USER_NAME" \
    --service-name bedrock.amazonaws.com \
    --credential-age-days 90 2>&1)

  if [ $? -ne 0 ]; then
    echo "  ERROR: Failed to create credential for $USER_NAME"
    ((FAILED++))
    continue
  fi

  SERVICE_PASSWORD=$(echo "$RESULT" | jq -r '.ServiceSpecificCredential.ServiceCredentialSecret')
  SERVICE_USER_NAME=$(echo "$RESULT" | jq -r '.ServiceSpecificCredential.ServiceUserName')

  if [ "$SERVICE_PASSWORD" = "null" ] || [ -z "$SERVICE_PASSWORD" ]; then
    echo "  ERROR: Failed to extract credential for $USER_NAME"
    ((FAILED++))
    continue
  fi

  TOKENS+=("$SERVICE_PASSWORD")
  USERNAMES+=("$SERVICE_USER_NAME")
  echo "  SUCCESS"

  # Small delay to ensure unique timestamps
  sleep 1
done

echo ""
echo "=========================================="
echo "Bedrock API Keys Created"
echo "=========================================="
echo "Successfully created: ${#TOKENS[@]} keys"
echo "Failed: $FAILED"
echo ""
echo "=========================================="
echo "Bearer Tokens"
echo "=========================================="
echo ""

for i in "${!TOKENS[@]}"; do
  echo "Key $((i+1)): ${TOKENS[$i]}"
done

echo ""
echo "=========================================="
echo "CSV Format (for easy import)"
echo "=========================================="
echo ""
echo "username,bearer_token"
for i in "${!TOKENS[@]}"; do
  echo "${USERNAMES[$i]},${TOKENS[$i]}"
done

echo ""
echo "=========================================="
echo "Claude Code Configuration (use any token)"
echo "=========================================="
echo ""
echo "# IMPORTANT: AWS_REGION must be set - Claude Code doesn't read ~/.aws/config"
echo "export AWS_REGION=eu-west-1"
echo ""
echo "# Option 1: Claude Opus 4.6 (EU inference - recommended)"
echo "export ANTHROPIC_MODEL='eu.anthropic.claude-opus-4-6-v1'"
echo ""
echo "# Option 2: Claude Sonnet 4.6 (EU inference)"
echo "export ANTHROPIC_MODEL='eu.anthropic.claude-sonnet-4-6'"
echo ""
echo "# Option 3: Claude Sonnet 4.5 (EU inference)"
echo "# export ANTHROPIC_MODEL='eu.anthropic.claude-sonnet-4-5-20250929-v1:0'"
echo ""
echo "# Option 4: Claude Opus 4.5 (EU inference)"
echo "# export ANTHROPIC_MODEL='eu.anthropic.claude-opus-4-5-20251101-v1:0'"
echo ""
echo "# Common settings"
echo "export CLAUDE_CODE_USE_BEDROCK=1"
echo "export ANTHROPIC_SMALL_FAST_MODEL='eu.anthropic.claude-haiku-4-5-20251001-v1:0'"
echo "export AWS_BEARER_TOKEN_BEDROCK='<paste-one-of-the-tokens-above>'"
echo ""
echo "IMPORTANT: Save these bearer tokens securely!"
echo "You will not be able to retrieve them again."
echo "=========================================="
