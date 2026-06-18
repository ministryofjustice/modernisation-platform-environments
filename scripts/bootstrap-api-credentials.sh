#!/bin/bash

set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  scripts/bootstrap-api-credentials.sh user --secret-id <secret-id> [--username <username>] [--role-name <role-name>] [--profile <aws-profile>] [--region <aws-region>]
  scripts/bootstrap-api-credentials.sh system --secret-id <secret-id> [--token-id <token-id>] [--role-name <role-name>] [--profile <aws-profile>] [--region <aws-region>]

Description:
  Generates a strong API credential outside Terraform state, writes it to the
  target AWS Secrets Manager secret, and prints only the sensitive handover
  value to stdout.

Modes:
  user
    Writes JSON in this shape:
      {"username":"...","password":"...","roleName":"..."}
    Prints only the generated password to stdout.

  system
    Writes JSON in this shape:
      {"tokenId":"...","bearerToken":"...","roleName":"..."}
    Prints only the bearer token value to hand over to the client in this form:
      <tokenId>.<bearerToken>

Notes:
  - If username, token-id, or role-name are omitted, the script will try to
    read them from the current secret value first.
  - Progress messages are sent to stderr so stdout stays safe for one-time
    capture of the handover value.
EOF
}

if [ "$#" -lt 1 ]; then
  usage >&2
  exit 1
fi

if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
  usage
  exit 0
fi

MODE="$1"
shift

SECRET_ID=""
USERNAME=""
TOKEN_ID=""
ROLE_NAME=""
AWS_PROFILE=""
AWS_REGION=""

while [ "$#" -gt 0 ]; do
  case "$1" in
    --secret-id|--secret-name)
      SECRET_ID="$2"
      shift 2
      ;;
    --username)
      USERNAME="$2"
      shift 2
      ;;
    --token-id)
      TOKEN_ID="$2"
      shift 2
      ;;
    --role-name)
      ROLE_NAME="$2"
      shift 2
      ;;
    --profile)
      AWS_PROFILE="$2"
      shift 2
      ;;
    --region)
      AWS_REGION="$2"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

if [ -z "$SECRET_ID" ]; then
  echo "--secret-id is required" >&2
  exit 1
fi

if [ "$MODE" != "user" ] && [ "$MODE" != "system" ]; then
  echo "Mode must be 'user' or 'system'" >&2
  exit 1
fi

if ! command -v aws >/dev/null 2>&1; then
  echo "aws CLI is required" >&2
  exit 1
fi

if ! command -v openssl >/dev/null 2>&1; then
  echo "openssl is required" >&2
  exit 1
fi

if ! command -v python3 >/dev/null 2>&1; then
  echo "python3 is required" >&2
  exit 1
fi

AWS_CMD=(aws)
if [ -n "$AWS_PROFILE" ]; then
  AWS_CMD+=(--profile "$AWS_PROFILE")
fi
if [ -n "$AWS_REGION" ]; then
  AWS_CMD+=(--region "$AWS_REGION")
fi

generate_secret_value() {
  local length="$1"
  openssl rand -base64 64 | tr -d '\n=' | tr '/+' '_-' | cut -c1-"$length"
}

read_secret_field() {
  local secret_json="$1"
  local field_name="$2"

  SECRET_JSON="$secret_json" python3 - "$field_name" <<'PY'
import json
import os
import sys

field_name = sys.argv[1]
secret_json = os.environ.get("SECRET_JSON", "")
if not secret_json:
    sys.exit(0)

try:
    data = json.loads(secret_json)
except json.JSONDecodeError as exc:
    raise SystemExit(f"SecretString is not valid JSON: {exc}")

value = data.get(field_name, "")
if value is None:
    value = ""

print(value, end="")
PY
}

build_secret_json() {
  local mode="$1"
  local identifier="$2"
  local role_name="$3"
  local secret_value="$4"

  python3 - "$mode" "$identifier" "$role_name" "$secret_value" <<'PY'
import json
import sys

mode, identifier, role_name, secret_value = sys.argv[1:]
if mode == "user":
    payload = {
        "username": identifier,
        "password": secret_value,
        "roleName": role_name,
    }
else:
    payload = {
        "tokenId": identifier,
        "bearerToken": secret_value,
        "roleName": role_name,
    }

print(json.dumps(payload, separators=(",", ":")), end="")
PY
}

echo "Reading secret container metadata from Secrets Manager" >&2
CURRENT_SECRET_JSON="$("${AWS_CMD[@]}" secretsmanager get-secret-value --secret-id "$SECRET_ID" --query SecretString --output text)"
if [ "$CURRENT_SECRET_JSON" = "None" ] || [ "$CURRENT_SECRET_JSON" = "null" ]; then
  CURRENT_SECRET_JSON=""
fi
if [ "$MODE" = "user" ]; then
  USERNAME="${USERNAME:-$(read_secret_field "$CURRENT_SECRET_JSON" "username")}"
  ROLE_NAME="${ROLE_NAME:-$(read_secret_field "$CURRENT_SECRET_JSON" "roleName")}"

  if [ -z "$USERNAME" ]; then
    echo "Username is missing. Pass --username or store it in the current secret JSON." >&2
    exit 1
  fi
  if [ -z "$ROLE_NAME" ]; then
    echo "Role name is missing. Pass --role-name or store it in the current secret JSON." >&2
    exit 1
  fi

  PASSWORD="$(generate_secret_value 40)"
  SECRET_STRING="$(build_secret_json user "$USERNAME" "$ROLE_NAME" "$PASSWORD")"

  echo "Writing generated user password to $SECRET_ID" >&2
  "${AWS_CMD[@]}" secretsmanager put-secret-value \
    --secret-id "$SECRET_ID" \
    --secret-string "$SECRET_STRING" \
    >/dev/null

  echo "Username: $USERNAME" >&2
  echo "Role name: $ROLE_NAME" >&2
  printf '%s\n' "$PASSWORD"
  exit 0
fi

TOKEN_ID="${TOKEN_ID:-$(read_secret_field "$CURRENT_SECRET_JSON" "tokenId")}"
ROLE_NAME="${ROLE_NAME:-$(read_secret_field "$CURRENT_SECRET_JSON" "roleName")}"

if [ -z "$TOKEN_ID" ]; then
  echo "Token ID is missing. Pass --token-id or store it in the current secret JSON." >&2
  exit 1
fi
if [ -z "$ROLE_NAME" ]; then
  echo "Role name is missing. Pass --role-name or store it in the current secret JSON." >&2
  exit 1
fi

BEARER_TOKEN="$(generate_secret_value 48)"
SECRET_STRING="$(build_secret_json system "$TOKEN_ID" "$ROLE_NAME" "$BEARER_TOKEN")"

echo "Writing generated system bearer token to $SECRET_ID" >&2
"${AWS_CMD[@]}" secretsmanager put-secret-value \
  --secret-id "$SECRET_ID" \
  --secret-string "$SECRET_STRING" \
  >/dev/null

echo "Token ID: $TOKEN_ID" >&2
echo "Role name: $ROLE_NAME" >&2
printf '%s.%s\n' "$TOKEN_ID" "$BEARER_TOKEN"
