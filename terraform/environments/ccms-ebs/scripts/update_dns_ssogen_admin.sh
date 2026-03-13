#!/bin/bash
set -euo pipefail

HOST_1="$1"
PORT="$2"
HOST_2="$3"
HOSTED_ZONE_ID="$5"
CHANGE_FILE="$6"

function check_port() {
    host=$1
    port=$2

    echo "Checking $host:$port ..."
    timeout 3 bash -c "cat < /dev/null > /dev/tcp/$host/$port" 2>/dev/null

    if [ $? -eq 0 ]; then
        echo "SUCCESS: $host:$port is reachable."
        return 0
    else
        echo "FAIL: $host:$port is NOT reachable."
        return 1
    fi
}

echo "=== Starting backend checks ==="

if check_port "$HOST_1" "$PORT"; then
    echo "Backend 1 healthy → Updating DNS to backend 1"
    sed -i "s|REPLACE_IP|$HOST_1|" "$CHANGE_FILE"

elif check_port "$HOST_2" "$PORT"; then
    echo "Backend 2 healthy → Updating DNS to backend 2"
    sed -i "s|REPLACE_IP|$HOST_2|" "$CHANGE_FILE"

else
    echo "ERROR: Neither backend is reachable. Aborting DNS update."
    exit 1
fi

echo "Applying DNS update..."
aws route53 change-resource-record-sets \
--hosted-zone-id "$HOSTED_ZONE_ID" \
--change-batch "file://$CHANGE_FILE"

echo "DNS update submitted OK."