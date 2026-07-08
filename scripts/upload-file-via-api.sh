#!/bin/bash

set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  scripts/upload-file-via-api.sh \
    --api-endpoint <https-url> \
    --client-id <client-id> \
    --file <local-file> \
    --content-type <mime-type> \
    [--basic-username <username> --basic-password <password> | --bearer-token <token>] \
    [--requested-expiry-seconds <seconds>] \
    [--output-dir <dir>]

Description:
  Requests an upload ticket from the Integration Hub API and performs the
  complete upload flow automatically:
  - single PUT uploads for smaller files
  - multipart upload initiation, part URL pagination, part uploads, and final
    completion for larger files

Outputs:
  Writes request/response artifacts under the chosen output directory and prints
  a short completion summary to stderr.
EOF
}

if [ "$#" -eq 0 ]; then
  usage >&2
  exit 1
fi

API_ENDPOINT=""
CLIENT_ID=""
LOCAL_FILE=""
CONTENT_TYPE=""
BASIC_USERNAME=""
BASIC_PASSWORD=""
BEARER_TOKEN=""
REQUESTED_EXPIRY_SECONDS="3600"
OUTPUT_DIR=""

while [ "$#" -gt 0 ]; do
  case "$1" in
    --api-endpoint)
      API_ENDPOINT="$2"
      shift 2
      ;;
    --client-id)
      CLIENT_ID="$2"
      shift 2
      ;;
    --file)
      LOCAL_FILE="$2"
      shift 2
      ;;
    --content-type)
      CONTENT_TYPE="$2"
      shift 2
      ;;
    --basic-username)
      BASIC_USERNAME="$2"
      shift 2
      ;;
    --basic-password)
      BASIC_PASSWORD="$2"
      shift 2
      ;;
    --bearer-token)
      BEARER_TOKEN="$2"
      shift 2
      ;;
    --requested-expiry-seconds)
      REQUESTED_EXPIRY_SECONDS="$2"
      shift 2
      ;;
    --output-dir)
      OUTPUT_DIR="$2"
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

if [ -z "$API_ENDPOINT" ] || [ -z "$CLIENT_ID" ] || [ -z "$LOCAL_FILE" ] || [ -z "$CONTENT_TYPE" ]; then
  echo "--api-endpoint, --client-id, --file, and --content-type are required" >&2
  exit 1
fi

if [ ! -f "$LOCAL_FILE" ]; then
  echo "Local file not found: $LOCAL_FILE" >&2
  exit 1
fi

if [ -n "$BEARER_TOKEN" ] && { [ -n "$BASIC_USERNAME" ] || [ -n "$BASIC_PASSWORD" ]; }; then
  echo "Use either bearer auth or basic auth, not both" >&2
  exit 1
fi

if [ -n "$BASIC_USERNAME" ] && [ -z "$BASIC_PASSWORD" ]; then
  echo "--basic-password is required when using --basic-username" >&2
  exit 1
fi

if [ -z "$BEARER_TOKEN" ] && [ -z "$BASIC_USERNAME" ]; then
  echo "Provide either --bearer-token or --basic-username/--basic-password" >&2
  exit 1
fi

if ! command -v curl >/dev/null 2>&1; then
  echo "curl is required" >&2
  exit 1
fi

if ! command -v python3 >/dev/null 2>&1; then
  echo "python3 is required" >&2
  exit 1
fi

if [ -z "$OUTPUT_DIR" ]; then
  OUTPUT_DIR="/tmp/api-upload-$(date +%s)"
fi

mkdir -p "$OUTPUT_DIR"

file_size_bytes() {
  local file_path="$1"
  if stat -f%z "$file_path" >/dev/null 2>&1; then
    stat -f%z "$file_path"
  else
    stat -c%s "$file_path"
  fi
}

FILE_SIZE_BYTES="$(file_size_bytes "$LOCAL_FILE")"
FILE_BASENAME="$(basename "$LOCAL_FILE")"

AUTH_ARGS=()
if [ -n "$BEARER_TOKEN" ]; then
  AUTH_ARGS=(-H "authorization: Bearer $BEARER_TOKEN")
else
  AUTH_ARGS=(-u "${BASIC_USERNAME}:${BASIC_PASSWORD}")
fi

TRANSFER_TICKET_REQUEST_JSON="$OUTPUT_DIR/transfer-ticket-request.json"
TRANSFER_TICKET_RESPONSE_JSON="$OUTPUT_DIR/transfer-ticket-response.json"

python3 - "$CLIENT_ID" "$FILE_BASENAME" "$CONTENT_TYPE" "$FILE_SIZE_BYTES" "$REQUESTED_EXPIRY_SECONDS" > "$TRANSFER_TICKET_REQUEST_JSON" <<'PY'
import json
import sys

client_id, file_name, content_type, size_bytes, requested_expiry = sys.argv[1:]

payload = {
    "clientId": client_id,
    "fileName": file_name,
    "contentType": content_type,
    "sizeBytes": int(size_bytes),
    "requestedExpirySeconds": int(requested_expiry),
}

print(json.dumps(payload, indent=2))
PY

echo "Requesting upload ticket from ${API_ENDPOINT}/transfer-tickets" >&2
curl --fail-with-body --silent --show-error \
  "${AUTH_ARGS[@]}" \
  -H "content-type: application/json" \
  -X POST "${API_ENDPOINT}/transfer-tickets" \
  --data @"$TRANSFER_TICKET_REQUEST_JSON" \
  > "$TRANSFER_TICKET_RESPONSE_JSON"

UPLOAD_MODE="$(RESPONSE_JSON_PATH="$TRANSFER_TICKET_RESPONSE_JSON" python3 <<'PY'
import json
import os

with open(os.environ["RESPONSE_JSON_PATH"], "r", encoding="utf-8") as fh:
    data = json.load(fh)

if "upload" in data:
    print("single")
elif "multipart" in data:
    print("multipart")
else:
    raise SystemExit("Unknown transfer-ticket response shape")
PY
)"

if [ "$UPLOAD_MODE" = "single" ]; then
  SINGLE_UPLOAD_URL_FILE="$OUTPUT_DIR/single-upload-url.txt"
  SINGLE_UPLOAD_HEADERS_FILE="$OUTPUT_DIR/single-upload-headers.json"

  RESPONSE_JSON_PATH="$TRANSFER_TICKET_RESPONSE_JSON" python3 <<'PY' > "$SINGLE_UPLOAD_URL_FILE"
import json
import os

with open(os.environ["RESPONSE_JSON_PATH"], "r", encoding="utf-8") as fh:
    data = json.load(fh)

print(data["upload"]["url"], end="")
PY

  RESPONSE_JSON_PATH="$TRANSFER_TICKET_RESPONSE_JSON" python3 <<'PY' > "$SINGLE_UPLOAD_HEADERS_FILE"
import json
import os

with open(os.environ["RESPONSE_JSON_PATH"], "r", encoding="utf-8") as fh:
    data = json.load(fh)

print(json.dumps(data["upload"].get("headers", {}), indent=2))
PY

  mapfile_headers="$(
    RESPONSE_JSON_PATH="$TRANSFER_TICKET_RESPONSE_JSON" python3 <<'PY'
import json
import os

with open(os.environ["RESPONSE_JSON_PATH"], "r", encoding="utf-8") as fh:
    data = json.load(fh)

for key, value in data["upload"].get("headers", {}).items():
    print(f"{key}\t{value}")
PY
  )"

  CURL_SINGLE_ARGS=()
  while IFS=$'\t' read -r header_name header_value; do
    [ -z "$header_name" ] && continue
    CURL_SINGLE_ARGS+=(-H "${header_name}: ${header_value}")
  done <<EOF
$mapfile_headers
EOF

  echo "Uploading single object to S3" >&2
  curl --fail-with-body --silent --show-error \
    -X PUT \
    --upload-file "$LOCAL_FILE" \
    "${CURL_SINGLE_ARGS[@]}" \
    "$(cat "$SINGLE_UPLOAD_URL_FILE")" \
    > /dev/null

  echo "Single upload complete." >&2
  echo "Transfer ticket response: $TRANSFER_TICKET_RESPONSE_JSON" >&2
  exit 0
fi

PARTS_DIR="$OUTPUT_DIR/parts"
UPLOADS_DIR="$OUTPUT_DIR/uploads"
mkdir -p "$PARTS_DIR" "$UPLOADS_DIR"

PART_SIZE_BYTES="$(RESPONSE_JSON_PATH="$TRANSFER_TICKET_RESPONSE_JSON" python3 <<'PY'
import json
import os

with open(os.environ["RESPONSE_JSON_PATH"], "r", encoding="utf-8") as fh:
    data = json.load(fh)

print(data["multipart"]["partSizeBytes"], end="")
PY
)"

TOTAL_PARTS="$(RESPONSE_JSON_PATH="$TRANSFER_TICKET_RESPONSE_JSON" python3 <<'PY'
import json
import os

with open(os.environ["RESPONSE_JSON_PATH"], "r", encoding="utf-8") as fh:
    data = json.load(fh)

print(data["multipart"]["totalParts"], end="")
PY
)"

INITIAL_BATCH_SIZE="$(RESPONSE_JSON_PATH="$TRANSFER_TICKET_RESPONSE_JSON" python3 <<'PY'
import json
import os

with open(os.environ["RESPONSE_JSON_PATH"], "r", encoding="utf-8") as fh:
    data = json.load(fh)

print(len(data["multipart"].get("initialParts", [])), end="")
PY
)"

TRANSFER_TICKET_ID="$(RESPONSE_JSON_PATH="$TRANSFER_TICKET_RESPONSE_JSON" python3 <<'PY'
import json
import os

with open(os.environ["RESPONSE_JSON_PATH"], "r", encoding="utf-8") as fh:
    data = json.load(fh)

print(data["transferTicket"], end="")
PY
)"

echo "Splitting $LOCAL_FILE into ${PART_SIZE_BYTES}-byte chunks" >&2
split -b "$PART_SIZE_BYTES" "$LOCAL_FILE" "$PARTS_DIR/part-"

ALL_PARTS_JSON="$OUTPUT_DIR/all-parts.json"
cp "$TRANSFER_TICKET_RESPONSE_JSON" "$ALL_PARTS_JSON"

NEXT_START=$((INITIAL_BATCH_SIZE + 1))
while [ "$NEXT_START" -le "$TOTAL_PARTS" ]; do
  NEXT_END=$((NEXT_START + INITIAL_BATCH_SIZE - 1))
  if [ "$NEXT_END" -gt "$TOTAL_PARTS" ]; then
    NEXT_END="$TOTAL_PARTS"
  fi

  PARTS_REQUEST_JSON="$OUTPUT_DIR/parts-${NEXT_START}-${NEXT_END}-request.json"
  PARTS_RESPONSE_JSON="$OUTPUT_DIR/parts-${NEXT_START}-${NEXT_END}-response.json"

  python3 - "$NEXT_START" "$NEXT_END" > "$PARTS_REQUEST_JSON" <<'PY'
import json
import sys

start, end = sys.argv[1:]
print(json.dumps({
    "partNumberStart": int(start),
    "partNumberEnd": int(end),
}, indent=2))
PY

  echo "Requesting part URLs ${NEXT_START}-${NEXT_END}" >&2
  curl --fail-with-body --silent --show-error \
    "${AUTH_ARGS[@]}" \
    -H "content-type: application/json" \
    -X POST "${API_ENDPOINT}/transfer-tickets/${TRANSFER_TICKET_ID}/parts" \
    --data @"$PARTS_REQUEST_JSON" \
    > "$PARTS_RESPONSE_JSON"

  MERGED_PARTS_JSON="$OUTPUT_DIR/all-parts-next.json"
  python3 - "$ALL_PARTS_JSON" "$PARTS_RESPONSE_JSON" > "$MERGED_PARTS_JSON" <<'PY'
import json
import sys

existing_path, new_path = sys.argv[1:]
with open(existing_path, "r", encoding="utf-8") as fh:
    existing = json.load(fh)
with open(new_path, "r", encoding="utf-8") as fh:
    new_data = json.load(fh)

existing["multipart"]["initialParts"].extend(new_data.get("parts", []))
print(json.dumps(existing, indent=2))
PY
  mv "$MERGED_PARTS_JSON" "$ALL_PARTS_JSON"

  NEXT_START=$((NEXT_END + 1))
done

ETAGS_JSON="$OUTPUT_DIR/etags.json"

RESPONSE_JSON_PATH="$ALL_PARTS_JSON" \
PARTS_DIR_PATH="$PARTS_DIR" \
UPLOADS_DIR_PATH="$UPLOADS_DIR" \
ETAGS_JSON_PATH="$ETAGS_JSON" \
python3 <<'PY'
import json
import os
import subprocess
import sys
from pathlib import Path

response_path = Path(os.environ["RESPONSE_JSON_PATH"])
parts_dir = Path(os.environ["PARTS_DIR_PATH"])
uploads_dir = Path(os.environ["UPLOADS_DIR_PATH"])
etags_path = Path(os.environ["ETAGS_JSON_PATH"])

with response_path.open("r", encoding="utf-8") as fh:
    data = json.load(fh)

parts = sorted(data["multipart"].get("initialParts", []), key=lambda item: int(item["partNumber"]))
chunk_files = sorted(parts_dir.glob("part-*"))
if len(chunk_files) < len(parts):
    raise SystemExit(f"Expected at least {len(parts)} chunk files, found {len(chunk_files)}")

results = []
for part in parts:
    part_number = int(part["partNumber"])
    chunk_file = chunk_files[part_number - 1]
    header_file = uploads_dir / f"part-{part_number}.headers"

    print(f"Uploading part {part_number} from {chunk_file}", file=sys.stderr)
    completed = subprocess.run(
        [
            "curl",
            "--fail-with-body",
            "--silent",
            "--show-error",
            "--request",
            part.get("method", "PUT"),
            "--dump-header",
            str(header_file),
            "--output",
            "/dev/null",
            "--upload-file",
            str(chunk_file),
            part["url"],
        ],
        check=False,
    )

    if completed.returncode != 0:
        raise SystemExit(f"Upload failed for part {part_number}")

    etag = None
    with header_file.open("r", encoding="utf-8") as fh:
        for line in fh:
            if line.lower().startswith("etag:"):
                etag = line.split(":", 1)[1].strip()
                break

    if not etag:
        raise SystemExit(f"ETag not found for part {part_number}")

    results.append({"partNumber": part_number, "eTag": etag})

with etags_path.open("w", encoding="utf-8") as fh:
    json.dump(
        {
            "transferTicket": data["transferTicket"],
            "parts": results,
        },
        fh,
        indent=2,
    )
PY

COMPLETE_REQUEST_JSON="$OUTPUT_DIR/complete-request.json"
COMPLETE_RESPONSE_JSON="$OUTPUT_DIR/complete-response.json"

ETAGS_JSON_PATH="$ETAGS_JSON" python3 <<'PY' > "$COMPLETE_REQUEST_JSON"
import json
import os

with open(os.environ["ETAGS_JSON_PATH"], "r", encoding="utf-8") as fh:
    data = json.load(fh)

print(json.dumps({"parts": data["parts"]}, indent=2))
PY

echo "Completing multipart upload" >&2
curl --fail-with-body --silent --show-error \
  "${AUTH_ARGS[@]}" \
  -H "content-type: application/json" \
  -X POST "${API_ENDPOINT}/transfer-tickets/${TRANSFER_TICKET_ID}/complete" \
  --data @"$COMPLETE_REQUEST_JSON" \
  > "$COMPLETE_RESPONSE_JSON"

echo "Multipart upload complete." >&2
echo "Transfer ticket response: $TRANSFER_TICKET_RESPONSE_JSON" >&2
echo "Combined parts response: $ALL_PARTS_JSON" >&2
echo "ETag manifest: $ETAGS_JSON" >&2
echo "Complete response: $COMPLETE_RESPONSE_JSON" >&2
