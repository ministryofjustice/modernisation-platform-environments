#!/bin/bash
set -e

# LinOTP Configuration Script using CLI instead of REST API
# Runs after LinOTP bootstrap to configure LDAP, realms, and policies

echo "============================================================"
echo "LinOTP Automated Configuration (CLI-based)"
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

##############################################
### Discover available CLI commands
##############################################
echo ""
echo "--- Discovering LinOTP CLI commands ---"
echo "Available 'linotp' subcommands:"
linotp --help 2>&1 || true

echo ""
echo "Available 'linotp init' subcommands:"
linotp init --help 2>&1 || true

echo ""
echo "Available 'linotp config' subcommands (if exists):"
linotp config --help 2>&1 || true

echo ""
echo "Available 'linotp admin' subcommands (if exists):"
linotp admin --help 2>&1 || true

##############################################
### Try CLI-based configuration
##############################################
echo ""
echo "--- Attempting CLI-based configuration ---"

# Try to create LDAP resolver using CLI (if command exists)
echo "Attempting to create LDAP resolver via CLI..."
linotp resolver create ldap \
    --name "$LINOTP_RESOLVER_NAME" \
    --ldap-uri "$AD_LDAP_URI" \
    --base-dn "$AD_BASE_DN" \
    --bind-dn "$AD_BIND_DN" \
    --bind-password "$AD_BIND_PASSWORD" \
    --search-filter "$AD_SEARCH_FILTER" \
    --user-filter "$AD_USER_FILTER" \
    --login-attribute "sAMAccountName" \
    2>&1 || echo "ERROR: CLI command 'linotp resolver create' does not exist or failed"

# Try to create realm using CLI
echo "Attempting to create realm via CLI..."
linotp realm create \
    --name "$LINOTP_REALM_NAME" \
    --resolver "$LINOTP_RESOLVER_NAME" \
    --default \
    2>&1 || echo "ERROR: CLI command 'linotp realm create' does not exist or failed"

# Try to create policies using CLI
echo "Attempting to create policies via CLI..."
linotp policy create \
    --name "radius_auth" \
    --scope authentication \
    --action "otppin=1" \
    --realm "$LINOTP_REALM_NAME" \
    2>&1 || echo "ERROR: CLI command 'linotp policy create' does not exist or failed"

echo ""
echo "============================================================"
echo "CLI-based configuration exploration completed"
echo "Check logs above to see which commands are available"
echo "============================================================"
