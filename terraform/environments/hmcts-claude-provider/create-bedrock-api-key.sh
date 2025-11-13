#!/bin/bash
set -e

# Script to create a Bedrock API key by assuming the BedrockAPIKeyCreator role
# This bypasses the common_policy deny on IAM user creation

ROLE_ARN="arn:aws:iam::313941174580:role/BedrockAPIKeyCreator"
REGION="eu-west-1"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
USER_NAME="BedrockAPIKey-hmcts-claude-${TIMESTAMP}"

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

# Create IAM user with timestamp
echo "Creating IAM user: $USER_NAME"
aws iam create-user --user-name "$USER_NAME"

# Attach the Bedrock access policy to the user
echo "Attaching Bedrock policy to user..."
POLICY_ARN="arn:aws:iam::313941174580:policy/HMCTSClaudeBedrockPolicy"
aws iam attach-user-policy \
  --user-name "$USER_NAME" \
  --policy-arn "$POLICY_ARN"

# Create service-specific credential for Bedrock
echo "Creating Bedrock API key (service-specific credential with 90-day expiry)..."
RESULT=$(aws iam create-service-specific-credential \
  --user-name "$USER_NAME" \
  --service-name bedrock.amazonaws.com \
  --credential-age-days 90 2>&1)

# Check if the command succeeded
if [ $? -ne 0 ]; then
  echo ""
  echo "ERROR: Failed to create service-specific credential"
  echo "$RESULT"
  exit 1
fi

# Extract and display the credentials
SERVICE_USER_NAME=$(echo "$RESULT" | jq -r '.ServiceSpecificCredential.ServiceUserName')
SERVICE_PASSWORD=$(echo "$RESULT" | jq -r '.ServiceSpecificCredential.ServiceCredentialSecret')

# Verify we got valid credentials
if [ "$SERVICE_PASSWORD" = "null" ] || [ -z "$SERVICE_PASSWORD" ]; then
  echo ""
  echo "ERROR: Failed to extract credentials from response"
  echo "Raw response:"
  echo "$RESULT"
  exit 1
fi

echo ""
echo "=========================================="
echo "Bedrock API Key Created Successfully!"
echo "=========================================="
echo ""
echo "Bearer Token: $SERVICE_PASSWORD"
echo "Service User Name: $SERVICE_USER_NAME"
echo ""
echo "=========================================="
echo "Claude Code Configuration"
echo "=========================================="
echo ""
echo "Add the following to your ~/.bashrc or ~/.zshrc:"
echo ""
echo "# Claude Code Bedrock Configuration"
echo "export CLAUDE_CODE_MAX_OUTPUT_TOKENS=4096"
echo "export MAX_THINKING_TOKENS=1024"
echo "export ANTHROPIC_MODEL='eu.anthropic.claude-sonnet-4-5-20250929-v1:0'"
echo "export ANTHROPIC_SMALL_FAST_MODEL='eu.anthropic.claude-3-haiku-20240307-v1:0'"
echo "export CLAUDE_CODE_USE_BEDROCK=1"
echo "export AWS_BEARER_TOKEN_BEDROCK='$SERVICE_PASSWORD'"
echo ""
echo "Then run: source ~/.bashrc (or source ~/.zshrc)"
echo ""
echo "IMPORTANT: Save this bearer token securely!"
echo "You will not be able to retrieve it again."
echo "=========================================="
