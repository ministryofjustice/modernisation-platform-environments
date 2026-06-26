#!/bin/bash

set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  scripts/upload-multipart-parts.sh <multipart-response.json> <local-file> [output-dir]

Description:
  Reads a multipart upload response JSON, splits the local file using the
  advertised part size, uploads each presigned part URL contained in the
  response, and writes the collected ETags to an output JSON file.

Notes:
  - This uploads only the part URLs present in the supplied response file.
  - If the response contains the initial 10 parts, this script uploads only
    those 10 parts. Request more part URLs from the API and run again for the
    remaining parts.
  - Presigned URLs expire. If uploads fail with signature/expiry errors, fetch
    fresh part URLs first.
EOF
}

if [ "$#" -lt 2 ] || [ "$#" -gt 3 ]; then
  usage >&2
  exit 1
fi

if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
  usage
  exit 0
fi

RESPONSE_JSON="$1"
LOCAL_FILE="$2"
OUTPUT_DIR="${3:-/tmp/multipart-upload-$(date +%s)}"

if [ ! -f "$RESPONSE_JSON" ]; then
  echo "Response JSON file not found: $RESPONSE_JSON" >&2
  exit 1
fi

if [ ! -f "$LOCAL_FILE" ]; then
  echo "Local file not found: $LOCAL_FILE" >&2
  exit 1
fi

if ! command -v python3 >/dev/null 2>&1; then
  echo "python3 is required" >&2
  exit 1
fi

if ! command -v curl >/dev/null 2>&1; then
  echo "curl is required" >&2
  exit 1
fi

mkdir -p "$OUTPUT_DIR"
PARTS_DIR="$OUTPUT_DIR/parts"
UPLOADS_DIR="$OUTPUT_DIR/uploads"
mkdir -p "$PARTS_DIR" "$UPLOADS_DIR"

RESPONSE_META_RAW="$(
  RESPONSE_JSON_PATH="$RESPONSE_JSON" python3 <<'PY'
import json
import os
import sys

path = os.environ["RESPONSE_JSON_PATH"]
with open(path, "r", encoding="utf-8") as fh:
    data = json.load(fh)

if "multipart" in data:
    multipart = data["multipart"]
    transfer_ticket = data.get("transferTicket", "")
    upload_id = multipart.get("uploadId", "")
    part_size = int(multipart["partSizeBytes"])
    parts = multipart.get("initialParts", [])
elif "parts" in data:
    transfer_ticket = data.get("transferTicket", "")
    upload_id = data.get("uploadId", "")
    part_size = None
    parts = data["parts"]
else:
    raise SystemExit("Response JSON does not contain multipart.initialParts or parts")

if not parts:
    raise SystemExit("No parts found in response JSON")

part_numbers = [int(part["partNumber"]) for part in parts]

print(transfer_ticket)
print(upload_id)
print("" if part_size is None else str(part_size))
print(",".join(str(number) for number in part_numbers))
PY
)"

TRANSFER_TICKET="$(printf '%s\n' "$RESPONSE_META_RAW" | sed -n '1p')"
UPLOAD_ID="$(printf '%s\n' "$RESPONSE_META_RAW" | sed -n '2p')"
PART_SIZE_BYTES="$(printf '%s\n' "$RESPONSE_META_RAW" | sed -n '3p')"
PART_NUMBERS_CSV="$(printf '%s\n' "$RESPONSE_META_RAW" | sed -n '4p')"

if [ -z "$PART_SIZE_BYTES" ]; then
  echo "This response does not include partSizeBytes. Use the original transfer-ticket response for splitting." >&2
  exit 1
fi

echo "Splitting $LOCAL_FILE into ${PART_SIZE_BYTES}-byte chunks under $PARTS_DIR" >&2
split -b "$PART_SIZE_BYTES" "$LOCAL_FILE" "$PARTS_DIR/part-"

ETAGS_JSON="$OUTPUT_DIR/etags.json"

RESPONSE_JSON_PATH="$RESPONSE_JSON" \
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

if "multipart" in data:
    parts = data["multipart"].get("initialParts", [])
else:
    parts = data["parts"]

chunk_files = sorted(parts_dir.glob("part-*"))
if not chunk_files:
    raise SystemExit("No split chunk files found")

results = []
for part in parts:
    part_number = int(part["partNumber"])
    chunk_index = part_number - 1
    if chunk_index >= len(chunk_files):
        raise SystemExit(f"Missing chunk file for part {part_number}")

    chunk_file = chunk_files[chunk_index]
    header_file = uploads_dir / f"part-{part_number}.headers"

    print(f"Uploading part {part_number} from {chunk_file}", file=sys.stderr)
    with header_file.open("w", encoding="utf-8") as header_fh:
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
        raise SystemExit(f"ETag not found in response headers for part {part_number}")

    results.append({
        "partNumber": part_number,
        "eTag": etag,
        "chunkFile": str(chunk_file),
    })

with etags_path.open("w", encoding="utf-8") as fh:
    json.dump(
        {
            "transferTicket": data.get("transferTicket", ""),
            "uploadId": data.get("uploadId", data.get("multipart", {}).get("uploadId", "")),
            "parts": results,
        },
        fh,
        indent=2,
    )

print(f"Wrote ETags to {etags_path}", file=sys.stderr)
PY

echo >&2
echo "Upload batch complete." >&2
echo "Transfer ticket: ${TRANSFER_TICKET}" >&2
echo "Upload ID: ${UPLOAD_ID}" >&2
echo "Uploaded part numbers: ${PART_NUMBERS_CSV}" >&2
echo "ETag manifest: ${ETAGS_JSON}" >&2
