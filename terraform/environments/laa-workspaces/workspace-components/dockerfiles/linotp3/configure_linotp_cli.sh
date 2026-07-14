#!/bin/bash
set -e

# LinOTP Configuration Script using CLI commands
# Runs after LinOTP bootstrap to configure LDAP, realms, and policies

echo "============================================================"
echo "LinOTP Automated Configuration (CLI)"
echo "============================================================"

# Wait for LinOTP to be ready
echo "Waiting for LinOTP to be ready..."
for i in {1..30}; do
    if curl -sf http://localhost:5000/manage/ > /dev/null 2>&1; then
        echo "LinOTP is ready"
        break
    fi
    echo "Attempt $i/30: LinOTP not ready yet, retrying in 10s..."
    sleep 10
done

# Configuration using linotp CLI commands
echo ""
echo "--- Step 1: LDAP Resolver ---"

# Check if resolver exists
if linotp-cli resolver list 2>/dev/null | grep -q "ad-resolver"; then
    echo "Resolver 'ad-resolver' already exists, skipping creation"
else
    echo "Creating LDAP resolver 'ad-resolver'..."
    linotp-cli resolver create \
        --name ad-resolver \
        --type ldap \
        --uri "$AD_LDAP_URI" \
        --basedn "$AD_BASE_DN" \
        --binddn "$AD_BIND_DN" \
        --bindpw "$AD_BIND_PASSWORD" \
        --searchfilter "$AD_SEARCH_FILTER" \
        --userfilter "$AD_USER_FILTER" \
        --loginattr sAMAccountName \
        --timeout 5 \
        --sizelimit 500

    echo "LDAP resolver 'ad-resolver' created successfully"
fi

echo ""
echo "--- Step 2: Realm Configuration ---"

# Check if realm exists
if linotp-cli realm list 2>/dev/null | grep -q "laa-workspaces"; then
    echo "Realm 'laa-workspaces' already exists, skipping creation"
else
    echo "Creating realm 'laa-workspaces'..."
    linotp-cli realm create \
        --name laa-workspaces \
        --resolvers ad-resolver \
        --default

    echo "Realm 'laa-workspaces' created successfully"
fi

echo ""
echo "--- Step 3: Policy Configuration ---"

# Authentication policy
if linotp-cli policy list 2>/dev/null | grep -q "radius_auth"; then
    echo "Policy 'radius_auth' already exists, skipping creation"
else
    echo "Creating authentication policy 'radius_auth'..."
    linotp-cli policy create \
        --name radius_auth \
        --scope authentication \
        --action "otppin=1" \
        --realm laa-workspaces \
        --user "*"

    echo "Authentication policy 'radius_auth' created successfully"
fi

# Enrollment policy
if linotp-cli policy list 2>/dev/null | grep -q "self_enrollment"; then
    echo "Policy 'self_enrollment' already exists, skipping creation"
else
    echo "Creating enrollment policy 'self_enrollment'..."
    linotp-cli policy create \
        --name self_enrollment \
        --scope enrollment \
        --action "maxtoken=5, tokenissuer=LAA WorkSpaces MFA" \
        --realm laa-workspaces \
        --user "*"

    echo "Enrollment policy 'self_enrollment' created successfully"
fi

# Self-service policy
if linotp-cli policy list 2>/dev/null | grep -q "selfservice_portal"; then
    echo "Policy 'selfservice_portal' already exists, skipping creation"
else
    echo "Creating self-service policy 'selfservice_portal'..."
    linotp-cli policy create \
        --name selfservice_portal \
        --scope selfservice \
        --action "enrollHMAC, setOTPPIN, setMOTPPIN, resync, disable, delete, history" \
        --realm laa-workspaces \
        --user "*"

    echo "Self-service policy 'selfservice_portal' created successfully"
fi

echo ""
echo "============================================================"
echo "✅ LinOTP configuration completed successfully"
echo "============================================================"
