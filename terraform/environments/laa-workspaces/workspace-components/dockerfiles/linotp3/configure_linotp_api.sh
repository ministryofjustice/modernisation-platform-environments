#!/bin/bash
set -e

# LinOTP Configuration Script using REST API (curl-based)
# Runs after LinOTP bootstrap to configure LDAP, realms, and policies

echo "============================================================"
echo "LinOTP Automated Configuration (REST API)"
echo "============================================================"

LINOTP_URL="${LINOTP_URL:-http://localhost:5000}"
COOKIE_JAR="/tmp/linotp-cookies.txt"

# Wait for LinOTP to be ready
echo "Waiting for LinOTP to be ready..."
for i in {1..30}; do
    if curl -sf "$LINOTP_URL/manage/" > /dev/null 2>&1; then
        echo "LinOTP is ready"
        break
    fi
    echo "Attempt $i/30: LinOTP not ready yet, retrying in 10s..."
    sleep 10
done

# Helper function to make API calls
# LinOTP 3.x admin API accessed from localhost doesn't require authentication
api_call() {
    local endpoint="$1"
    shift
    local response
    response=$(curl -sf "$LINOTP_URL$endpoint" "$@" 2>&1)
    local exit_code=$?
    if [ $exit_code -ne 0 ]; then
        echo "ERROR: API call to $endpoint failed (exit code: $exit_code)"
        echo "Response: $response"
        return $exit_code
    fi
    echo "$response"
    return 0
}

# Check if resource exists
resolver_exists() {
    api_call "/system/getResolvers" | grep -q "\"$1\""
}

realm_exists() {
    api_call "/system/getRealms" | grep -qi "\"$1\""
}

policy_exists() {
    api_call "/system/getPolicy?name=$1" | grep -q "\"$1\""
}

##############################################
### Step 1: LDAP Resolver
##############################################

echo ""
echo "--- Step 1: LDAP Resolver ---"

if resolver_exists "$LINOTP_RESOLVER_NAME"; then
    echo "Resolver '$LINOTP_RESOLVER_NAME' already exists, skipping creation"
else
    echo "Creating LDAP resolver '$LINOTP_RESOLVER_NAME'..."

    api_call "/system/setResolver" \
        --data-urlencode "resolver=$LINOTP_RESOLVER_NAME" \
        --data-urlencode "type=ldapresolver" \
        --data-urlencode "LDAPURI=$AD_LDAP_URI" \
        --data-urlencode "LDAPBASE=$AD_BASE_DN" \
        --data-urlencode "BINDDN=$AD_BIND_DN" \
        --data-urlencode "BINDPW=$AD_BIND_PASSWORD" \
        --data-urlencode "LDAPSEARCHFILTER=$AD_SEARCH_FILTER" \
        --data-urlencode "LDAPFILTER=$AD_USER_FILTER" \
        --data-urlencode "LOGINNAMEATTRIBUTE=sAMAccountName" \
        --data-urlencode "USERINFO={\"username\":\"sAMAccountName\",\"phone\":\"telephoneNumber\",\"mobile\":\"mobile\",\"email\":\"mail\",\"surname\":\"sn\",\"givenname\":\"givenName\",\"description\":\"description\"}" \
        --data-urlencode "TIMEOUT=5" \
        --data-urlencode "SIZELIMIT=500" \
        --data-urlencode "NOREFERRALS=True" > /dev/null

    if [ $? -eq 0 ]; then
        echo "LDAP resolver '$LINOTP_RESOLVER_NAME' created successfully"
    else
        echo "ERROR: Failed to create LDAP resolver"
        exit 1
    fi
fi

##############################################
### Step 2: Realm Configuration
##############################################

echo ""
echo "--- Step 2: Realm Configuration ---"

if realm_exists "$LINOTP_REALM_NAME"; then
    echo "Realm '$LINOTP_REALM_NAME' already exists, skipping creation"
else
    echo "Creating realm '$LINOTP_REALM_NAME'..."

    api_call "/system/setRealm" \
        --data-urlencode "realm=$LINOTP_REALM_NAME" \
        --data-urlencode "resolvers=$LINOTP_RESOLVER_NAME" > /dev/null

    if [ $? -eq 0 ]; then
        echo "Realm '$LINOTP_REALM_NAME' created successfully"
    else
        echo "ERROR: Failed to create realm"
        exit 1
    fi
fi

# Set as default realm
echo "Setting '$LINOTP_REALM_NAME' as default realm..."
api_call "/system/setDefaultRealm" \
    --data-urlencode "DefaultRealm=$LINOTP_REALM_NAME" > /dev/null

##############################################
### Step 3: Policy Configuration
##############################################

echo ""
echo "--- Step 3: Policy Configuration ---"

# Authentication policy
if policy_exists "radius_auth"; then
    echo "Policy 'radius_auth' already exists, skipping creation"
else
    echo "Creating authentication policy 'radius_auth'..."
    api_call "/system/setPolicy" \
        --data-urlencode "name=radius_auth" \
        --data-urlencode "scope=authentication" \
        --data-urlencode "action=otppin=1" \
        --data-urlencode "user=*" \
        --data-urlencode "realm=$LINOTP_REALM_NAME" \
        --data-urlencode "active=True" > /dev/null

    echo "Authentication policy 'radius_auth' created successfully"
fi

# Enrollment policy
if policy_exists "self_enrollment"; then
    echo "Policy 'self_enrollment' already exists, skipping creation"
else
    echo "Creating enrollment policy 'self_enrollment'..."
    api_call "/system/setPolicy" \
        --data-urlencode "name=self_enrollment" \
        --data-urlencode "scope=enrollment" \
        --data-urlencode "action=maxtoken=5, tokenissuer=LAA WorkSpaces MFA" \
        --data-urlencode "user=*" \
        --data-urlencode "realm=$LINOTP_REALM_NAME" \
        --data-urlencode "active=True" > /dev/null

    echo "Enrollment policy 'self_enrollment' created successfully"
fi

# Self-service policy
if policy_exists "selfservice_portal"; then
    echo "Policy 'selfservice_portal' already exists, skipping creation"
else
    echo "Creating self-service policy 'selfservice_portal'..."
    api_call "/system/setPolicy" \
        --data-urlencode "name=selfservice_portal" \
        --data-urlencode "scope=selfservice" \
        --data-urlencode "action=enrollHMAC, setOTPPIN, setMOTPPIN, resync, disable, delete, history" \
        --data-urlencode "user=*" \
        --data-urlencode "realm=$LINOTP_REALM_NAME" \
        --data-urlencode "active=True" > /dev/null

    echo "Self-service policy 'selfservice_portal' created successfully"
fi

echo ""
echo "============================================================"
echo "✅ LinOTP configuration completed successfully"
echo "============================================================"
