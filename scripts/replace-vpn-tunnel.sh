#!/bin/bash
set -e
set -o pipefail
export AWS_PAGER=""

# Script to replace VPN tunnel and accept maintenance updates
# Usage: scripts/replace-vpn-tunnel.sh <vpn_id> 

VPN_ID=$1

# Find VPN tunnels for the given VPN ID
# aws ec2 describe-vpn-connections \
#     --filters "Name=vpn-connection-id,Values=$VPN_ID" 

OutsideIPAddresses=($(aws ec2 describe-vpn-connections \
    --filters "Name=vpn-connection-id,Values=$VPN_ID" \
    --query "VpnConnections[0].Options.TunnelOptions[*].OutsideIpAddress" \
    --output text))

# echo "Outside IP Address 1: ${OutsideIPAddresses[0]}"
# echo "Outside IP Address 2: ${OutsideIPAddresses[1]}"

# Replace VPN tunnel 1
echo "Replacing 1st VPN tunnel..."
aws ec2 replace-vpn-tunnel \
    --vpn-connection-id "$VPN_ID" \
    --vpn-tunnel-outside-ip-address "${OutsideIPAddresses[0]}" \
    --apply-pending-maintenance
sleep 15

echo "Waiting for tunnel 1 to finish replacing..."
while true; do
    STATUS=$(aws ec2 describe-vpn-connections \
        --filters "Name=vpn-connection-id,Values=$VPN_ID" \
        --query "VpnConnections[0].VgwTelemetry[0].Status" \
        --output text)
    if [[ "$STATUS" == "UP" ]]; then
        echo "Tunnel 1 is UP."
        break
    fi
    echo "Tunnel 1 status: $STATUS. Waiting 1 minute..."
    sleep 60
done

# Replace VPN tunnel 2
echo "Replacing 2nd VPN tunnel..."
aws ec2 replace-vpn-tunnel \
    --vpn-connection-id "$VPN_ID" \
    --vpn-tunnel-outside-ip-address "${OutsideIPAddresses[1]}" \
    --apply-pending-maintenance
sleep 15

echo "Waiting for tunnel 2 to finish replacing..."
while true; do
    STATUS=$(aws ec2 describe-vpn-connections \
        --filters "Name=vpn-connection-id,Values=$VPN_ID" \
        --query "VpnConnections[0].VgwTelemetry[1].Status" \
        --output text)
    if [[ "$STATUS" == "UP" ]]; then
        echo "Tunnel 2 is UP."
        break
    fi
    echo "Tunnel 2 status: $STATUS. Waiting 1 minute..."
    sleep 60
done
echo "Both VPN tunnels have been successfully replaced and are UP."