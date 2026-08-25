#!/bin/bash

set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  scripts/poll-clean-file-notification.sh --queue-url <queue-url> [--profile <aws-profile>] [--region <aws-region>] [--delete]

Description:
  Polls an SQS queue for one clean-file-ready notification message and prints
  the JSON payload to stdout. By default the message is left on the queue.

Options:
  --queue-url  Full SQS queue URL to poll.
  --profile    AWS profile to use.
  --region     AWS region (defaults to eu-west-2).
  --delete     Delete the received message after printing it.
EOF
}

QUEUE_URL=""
AWS_PROFILE=""
AWS_REGION="eu-west-2"
DELETE_MESSAGE="false"

while [ "$#" -gt 0 ]; do
  case "$1" in
    --queue-url)
      QUEUE_URL="$2"
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
    --delete)
      DELETE_MESSAGE="true"
      shift
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

if [ -z "$QUEUE_URL" ]; then
  echo "--queue-url is required" >&2
  exit 1
fi

if ! command -v aws >/dev/null 2>&1; then
  echo "aws CLI is required" >&2
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
AWS_CMD+=(--region "$AWS_REGION")

MESSAGE_JSON="$("${AWS_CMD[@]}" sqs receive-message \
  --queue-url "$QUEUE_URL" \
  --max-number-of-messages 1 \
  --message-attribute-names All \
  --attribute-names All \
  --wait-time-seconds 5 \
  --output json)"

RECEIPT_HANDLE_FILE="$(mktemp)"
MESSAGE_JSON="$MESSAGE_JSON" RECEIPT_HANDLE_FILE="$RECEIPT_HANDLE_FILE" python3 - <<'PY'
import json
import os
import sys

data = json.loads(os.environ["MESSAGE_JSON"])
messages = data.get("Messages", [])
if not messages:
    print("No messages available", file=sys.stderr)
    raise SystemExit(1)

message = messages[0]
body = message.get("Body", "")

try:
    parsed_body = json.loads(body)
except json.JSONDecodeError:
    parsed_body = body

print(json.dumps(parsed_body, indent=2, sort_keys=True))
with open(os.environ["RECEIPT_HANDLE_FILE"], "w", encoding="utf-8") as handle:
    handle.write(message.get("ReceiptHandle", ""))
PY

RECEIPT_HANDLE="$(cat "$RECEIPT_HANDLE_FILE")"
rm -f "$RECEIPT_HANDLE_FILE"

if [ "$DELETE_MESSAGE" = "true" ]; then
  if [ -n "$RECEIPT_HANDLE" ]; then
    "${AWS_CMD[@]}" sqs delete-message --queue-url "$QUEUE_URL" --receipt-handle "$RECEIPT_HANDLE" >/dev/null
  fi
fi
