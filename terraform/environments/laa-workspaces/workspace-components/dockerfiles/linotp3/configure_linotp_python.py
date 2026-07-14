#!/usr/bin/env python3
"""
LinOTP Automated Configuration Script

Configures LinOTP with LDAP resolver, realm, and policies on container startup.
Idempotent - safe to run multiple times, only creates missing configuration.

Configuration is stored in RDS database and persists across container restarts.
"""

import os
import sys
import time

def wait_for_linotp():
    """Wait for LinOTP to be ready."""
    import urllib.request
    import urllib.error

    print("Waiting for LinOTP to be ready...")
    for attempt in range(1, 31):
        try:
            urllib.request.urlopen('http://localhost:5000/manage/', timeout=5)
            print("LinOTP is ready")
            return True
        except (urllib.error.URLError, TimeoutError):
            print(f"Attempt {attempt}/30: LinOTP not ready yet, retrying in 10s...")
            time.sleep(10)

    print("ERROR: LinOTP failed to start after 5 minutes")
    return False


def configure_linotp():
    """Configure LinOTP resolver, realm, and policies."""

    # Import LinOTP modules within Flask shell context
    from linotp.lib import resolver, realm
    from linotp.lib.config import getLinotpConfig, storeConfig

    print("\n" + "=" * 60)
    print("LinOTP Automated Configuration (Python)")
    print("=" * 60)

    # Get environment variables
    resolver_name = os.environ.get('LINOTP_RESOLVER_NAME', 'ad-resolver')
    realm_name = os.environ.get('LINOTP_REALM_NAME', 'laa-workspaces')

    # ==========================================
    # Step 1: Check and create LDAP resolver
    # ==========================================
    print(f"\n--- Step 1: LDAP Resolver '{resolver_name}' ---")

    config = getLinotpConfig()
    resolver_key = f'linotp.ldapresolver.LDAPURI.{resolver_name}'

    if resolver_key in config:
        print(f"✓ Resolver '{resolver_name}' already exists, skipping creation")
    else:
        print(f"Creating LDAP resolver '{resolver_name}'...")

        # Build resolver configuration
        resolver_config = {
            f'linotp.ldapresolver.LDAPURI.{resolver_name}': os.environ['AD_LDAP_URI'],
            f'linotp.ldapresolver.LDAPBASE.{resolver_name}': os.environ['AD_BASE_DN'],
            f'linotp.ldapresolver.BINDDN.{resolver_name}': os.environ['AD_BIND_DN'],
            f'linotp.ldapresolver.BINDPW.{resolver_name}': os.environ['AD_BIND_PASSWORD'],
            f'linotp.ldapresolver.LOGINNAMEATTRIBUTE.{resolver_name}': 'sAMAccountName',
            f'linotp.ldapresolver.LDAPFILTER.{resolver_name}': os.environ['AD_USER_FILTER'],
            f'linotp.ldapresolver.LDAPSEARCHFILTER.{resolver_name}': os.environ['AD_SEARCH_FILTER'],
            f'linotp.ldapresolver.TIMEOUT.{resolver_name}': '5',
            f'linotp.ldapresolver.SIZELIMIT.{resolver_name}': '500',
            f'linotp.ldapresolver.NOREFERRALS.{resolver_name}': 'True',
        }

        # Write resolver config to database
        for key, value in resolver_config.items():
            storeConfig(key, value)

        print(f"✓ Resolver '{resolver_name}' created successfully")

    # ==========================================
    # Step 2: Check and create realm
    # ==========================================
    print(f"\n--- Step 2: Realm '{realm_name}' ---")

    config = getLinotpConfig()
    realm_resolver_key = f'linotp.useridresolver.group.{realm_name}'

    if realm_resolver_key in config:
        print(f"✓ Realm '{realm_name}' already exists, skipping creation")
    else:
        print(f"Creating realm '{realm_name}' and linking resolver...")

        # Link resolver to realm
        resolver_spec = f'useridresolver.LDAPIdResolver.IdResolver.{resolver_name}'
        storeConfig(realm_resolver_key, resolver_spec)

        # Create realm in database
        realm.createDBRealm(realm_name)

        # Set as default realm
        realm.setDefaultRealm(realm_name, check_if_exists=False)

        print(f"✓ Realm '{realm_name}' created and set as default")

    # ==========================================
    # Step 3: Check and create policies
    # ==========================================
    print(f"\n--- Step 3: Policies ---")

    policies = [
        {
            'name': 'Limit_to_one_token',
            'scope': 'enrollment',
            'action': 'maxtoken=1',
            'user': '*',
            'realm': realm_name,
            'client': '*',
            'time': '* * * * * *;',
        },
        {
            'name': 'OTP_to_authenticate',
            'scope': 'authentication',
            'action': 'otppin=token_pin',
            'user': '*',
            'realm': realm_name,
            'client': '*',
            'time': '* * * * * *;',
        },
        {
            'name': 'selfservice_enrollment',
            'scope': 'selfservice',
            'action': 'webprovisionGOOGLE, enrollTOTP',
            'user': '*',
            'realm': realm_name,
            'client': '*',
            'time': '* * * * * *;',
        },
    ]

    config = getLinotpConfig()

    for policy in policies:
        policy_name = policy['name']
        policy_key = f'linotp.Policy.{policy_name}.scope'

        if policy_key in config:
            print(f"  ✓ Policy '{policy_name}' already exists, skipping")
        else:
            print(f"  Creating policy '{policy_name}'...")

            policy_config = {
                f'linotp.Policy.{policy_name}.realm': policy['realm'],
                f'linotp.Policy.{policy_name}.action': policy['action'],
                f'linotp.Policy.{policy_name}.scope': policy['scope'],
                f'linotp.Policy.{policy_name}.active': 'True',
                f'linotp.Policy.{policy_name}.client': policy['client'],
                f'linotp.Policy.{policy_name}.user': policy['user'],
                f'linotp.Policy.{policy_name}.time': policy['time'],
            }

            for key, value in policy_config.items():
                storeConfig(key, value)

            print(f"  ✓ Policy '{policy_name}' created")

    print("\n" + "=" * 60)
    print("✅ LinOTP configuration completed successfully")
    print("=" * 60)


if __name__ == '__main__':
    try:
        # Wait for LinOTP to be ready
        if not wait_for_linotp():
            sys.exit(1)

        # Run configuration
        configure_linotp()

    except Exception as e:
        print(f"\n❌ ERROR: Configuration failed")
        print(f"Error: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)
