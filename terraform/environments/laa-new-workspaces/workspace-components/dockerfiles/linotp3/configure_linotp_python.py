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

def set_admin_password_internal(db):
    """Set LinOTP admin user password using internal API."""
    admin_user = os.environ.get('LINOTP_ADMIN_USER', 'admin')
    admin_password = os.environ.get('LINOTP_ADMIN_PASSWORD')

    if not admin_password:
        print("WARNING: LINOTP_ADMIN_PASSWORD not set, skipping admin password configuration")
        return False

    print(f"\n--- Setting admin password for user '{admin_user}' ---")

    try:
        from passlib.hash import bcrypt
        from sqlalchemy import text

        # Hash password using bcrypt
        password_hash = bcrypt.hash(admin_password)

        # Delete any existing admin user first
        delete_sql = text("DELETE FROM imported_user WHERE username = :username")
        db.session.execute(delete_sql, {'username': admin_user})

        # Insert admin user into imported_user table (not admin_users!)
        insert_sql = text("""
            INSERT INTO imported_user (groupid, userid, username, password, email)
            VALUES (:groupid, :userid, :username, :password, :email)
        """)

        db.session.execute(
            insert_sql,
            {
                'groupid': 'LinOTP_local_admins',
                'userid': admin_user,
                'username': admin_user,
                'password': password_hash,
                'email': f'{admin_user}@local'
            }
        )
        db.session.commit()

        print(f"✓ Admin password set successfully for user '{admin_user}'")
        return True

    except Exception as e:
        print(f"WARNING: Error setting admin password: {e}")
        import traceback
        traceback.print_exc()
        return False


def configure_linotp():
    """Configure LinOTP resolver, realm, and policies.

    Runs before gunicorn starts (see entrypoint.sh), so it builds its own
    Flask app/DB connection directly instead of waiting on a running
    server. `linotp init database` has already completed synchronously by
    this point, but retry a few times in case the DB connection isn't
    immediately usable yet.
    """
    from linotp.app import create_app

    app = None
    for attempt in range(1, 16):
        try:
            app = create_app()
            break
        except Exception as e:
            print(f"Attempt {attempt}/15: LinOTP app not ready yet ({e}), retrying in 5s...")
            time.sleep(5)

    if app is None:
        print("ERROR: Could not initialise LinOTP app after 75s")
        sys.exit(1)

    with app.app_context():
        # Import LinOTP modules within Flask application context
        from linotp.lib import resolver, realm
        from linotp.lib.config import getLinotpConfig, storeConfig
        from linotp.model import db

        print("\n" + "=" * 60)
        print("LinOTP Automated Configuration (Python)")
        print("=" * 60)

        # Step 0: Set admin password using internal API
        set_admin_password_internal(db)

        _configure_linotp_internal(resolver, realm, getLinotpConfig, storeConfig, db)


def _configure_linotp_internal(resolver, realm, getLinotpConfig, storeConfig, db):
    """Internal configuration logic (runs within Flask context)."""

    # Get environment variables
    resolver_name = os.environ.get('LINOTP_RESOLVER_NAME', 'ad-resolver')
    realm_name = os.environ.get('LINOTP_REALM_NAME', 'laa-workspaces')

    # Build LDAP URI from AD DNS IPs
    ad_dns_ips = os.environ.get('AD_DNS_IPS', '10.200.1.245,10.200.2.11')  # Fallback to dev IPs
    ldap_uris = ', '.join([f'ldap://{ip.strip()}' for ip in ad_dns_ips.split(',')])

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

        # Encrypt the AD bind password using LinOTP's encryption
        from linotp.lib.crypto.encrypted_data import EncryptedData

        # Create encrypted data object - this handles encryption automatically via storeConfig
        bindpw = os.environ['AD_BIND_PASSWORD']

        # Build resolver configuration
        # Note: storeConfig will automatically encrypt sensitive values like BINDPW
        resolver_config = {
            f'linotp.ldapresolver.LDAPURI.{resolver_name}': ldap_uris,
            f'linotp.ldapresolver.LDAPBASE.{resolver_name}': 'OU=Users,OU=LAAWORKSPACES,DC=laa-workspaces,DC=local',
            f'linotp.ldapresolver.BINDDN.{resolver_name}': 'CN=Admin,OU=Users,OU=LAAWORKSPACES,DC=laa-workspaces,DC=local',
            f'linotp.ldapresolver.BINDPW.{resolver_name}': bindpw,
            f'linotp.ldapresolver.LOGINNAMEATTRIBUTE.{resolver_name}': 'sAMAccountName',
            f'linotp.ldapresolver.LDAPFILTER.{resolver_name}': '(&(sAMAccountName=%s)(objectClass=user))',
            f'linotp.ldapresolver.LDAPSEARCHFILTER.{resolver_name}': '(sAMAccountName=*)(objectClass=user)',
            f'linotp.ldapresolver.USERINFO.{resolver_name}': '{ "username": "sAMAccountName", "phone" : "telephoneNumber", "mobile" : "mobile", "email" : "mail", "surname" : "sn", "givenname" : "givenName" }',
            f'linotp.ldapresolver.UIDTYPE.{resolver_name}': 'objectGUID',
            f'linotp.ldapresolver.TIMEOUT.{resolver_name}': '5',
            f'linotp.ldapresolver.SIZELIMIT.{resolver_name}': '500',
            f'linotp.ldapresolver.NOREFERRALS.{resolver_name}': 'True',
            f'linotp.ldapresolver.EnforceTLS.{resolver_name}': 'False',
        }

        # Write resolver config to database
        for key, value in resolver_config.items():
            storeConfig(key, value)

        # Commit to database
        db.session.commit()

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

        # Commit to database
        db.session.commit()

        print(f"✓ Realm '{realm_name}' created")

    # Always reassert the default realm, even when it already existed.
    # The `default` flag on the Realm table can end up unset (e.g. it isn't
    # touched here on restarts since the block above is skipped once the
    # realm exists), which leaves LinOTP with no default realm and RADIUS/PAP
    # auth requests failing. Re-running this is idempotent and safe.
    print(f"Ensuring '{realm_name}' is the default realm...")
    realm.setDefaultRealm(realm_name, check_if_exists=False)
    db.session.commit()
    print(f"✓ Default realm is '{realm_name}'")

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

            # Commit to database
            db.session.commit()

            print(f"  ✓ Policy '{policy_name}' created")

    print("\n" + "=" * 60)
    print("✅ LinOTP configuration completed successfully")
    print("=" * 60)


if __name__ == '__main__':
    try:
        # Run configuration
        configure_linotp()

    except Exception as e:
        print(f"\n❌ ERROR: Configuration failed")
        print(f"Error: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)
