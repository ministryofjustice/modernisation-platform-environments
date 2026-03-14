#!/bin/bash
set -euo pipefail
HOST_A="$1"; PORT_A="$2"; HOST_B="$3"; PORT_B="$4"; PARAM_NAME="$5"; REGION="$6"

check_tcp () {
  local host="$1"; local port="$2"
  timeout 3 bash -c "cat < /dev/null > /dev/tcp/${host}/${port}" 2>/dev/null
}

SELECTED=""
if check_tcp "$HOST_A" "$PORT_A"; then
  SELECTED="$HOST_A"
elif check_tcp "$HOST_B" "$PORT_B"; then
  SELECTED="$HOST_B"
else
  echo "Neither backend reachable" >&2
  exit 1
fi

aws ssm put-parameter \
  --name "$PARAM_NAME" \
  --value "$SELECTED" \
  --type String \
  --overwrite \
  --region "$REGION"

echo "Stored $SELECTED in $PARAM_NAME"