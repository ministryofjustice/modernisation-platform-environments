#!/usr/bin/env python3
"""
LinOTP 3.x Automated Configuration Script

Configures LinOTP via REST API after initial bootstrap:
- LDAP UserIdResolver (Active Directory integration)
- Realm creation and default realm assignment
- Authentication policies
- Token enrollment policies

Idempotent: safe to run multiple times, skips existing configuration.
"""

import os
import sys
import json
import time
import logging
import requests
from urllib.parse import urljoin

logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s [%(levelname)s] %(message)s'
)
logger = logging.getLogger(__name__)

# Configuration from environment variables
LINOTP_URL = os.getenv('LINOTP_URL', 'http://localhost:5000')
LINOTP_ADMIN_USER = os.getenv('LINOTP_ADMIN_USER', 'admin')
LINOTP_ADMIN_PASSWORD = os.getenv('LINOTP_ADMIN_PASSWORD')

# Active Directory configuration
AD_URI = os.getenv('AD_LDAP_URI')  # e.g., ldaps://10.200.1.10:636
AD_BASE_DN = os.getenv('AD_BASE_DN')  # e.g., DC=laa-workspaces,DC=local
AD_BIND_DN = os.getenv('AD_BIND_DN')  # e.g., CN=linotp-svc,OU=Service Accounts,DC=laa-workspaces,DC=local
AD_BIND_PASSWORD = os.getenv('AD_BIND_PASSWORD')
AD_USER_FILTER = os.getenv('AD_USER_FILTER', '(&(sAMAccountName=%s)(objectClass=user))')
AD_SEARCH_FILTER = os.getenv('AD_SEARCH_FILTER', '(sAMAccountName=*)')

# LinOTP configuration
RESOLVER_NAME = os.getenv('LINOTP_RESOLVER_NAME', 'ad-resolver')
REALM_NAME = os.getenv('LINOTP_REALM_NAME', 'laa-workspaces')


class LinOTPConfigError(Exception):
    """Custom exception for LinOTP configuration errors"""
    pass


class LinOTPClient:
    """Client for LinOTP REST API"""

    def __init__(self, url, username, password):
        self.url = url.rstrip('/')
        self.username = username
        self.password = password
        self.session = requests.Session()
        self.session.headers.update({'Content-Type': 'application/x-www-form-urlencoded'})
        self.authenticated = False

    def login(self):
        """Authenticate with LinOTP and establish session"""
        login_url = urljoin(self.url, '/manage/login')
        try:
            response = self.session.post(
                login_url,
                data={
                    'username': self.username,
                    'password': self.password
                },
                timeout=30
            )
            response.raise_for_status()
            self.authenticated = True
            logger.info("Successfully authenticated with LinOTP")
            return True
        except requests.exceptions.RequestException as e:
            logger.error(f"Login failed: {e}")
            raise LinOTPConfigError(f"Login failed: {e}")

    def _request(self, method, endpoint, data=None, params=None):
        """Make HTTP request to LinOTP API"""
        if not self.authenticated:
            self.login()

        url = urljoin(self.url, endpoint)
        try:
            response = self.session.request(
                method=method,
                url=url,
                data=data,
                params=params,
                timeout=30
            )
            response.raise_for_status()

            result = response.json()

            # Check LinOTP-specific response structure
            if not result.get('result', {}).get('status', False):
                error_msg = result.get('result', {}).get('error', {}).get('message', 'Unknown error')
                raise LinOTPConfigError(f"LinOTP API error: {error_msg}")

            return result
        except requests.exceptions.RequestException as e:
            logger.error(f"HTTP request failed: {e}")
            raise LinOTPConfigError(f"HTTP request failed: {e}")
        except json.JSONDecodeError as e:
            logger.error(f"Failed to parse JSON response: {e}")
            raise LinOTPConfigError(f"Failed to parse JSON response: {e}")

    def get(self, endpoint, params=None):
        """GET request"""
        return self._request('GET', endpoint, params=params)

    def post(self, endpoint, data=None):
        """POST request"""
        return self._request('POST', endpoint, data=data)

    def resolver_exists(self, resolver_name):
        """Check if resolver exists"""
        try:
            response = self.get('/system/getResolvers')
            resolvers = response.get('result', {}).get('value', {})
            return resolver_name in resolvers
        except Exception as e:
            logger.warning(f"Failed to check if resolver exists: {e}")
            return False

    def realm_exists(self, realm_name):
        """Check if realm exists"""
        try:
            response = self.get('/system/getRealms')
            realms = response.get('result', {}).get('value', {})
            return realm_name.lower() in {k.lower() for k in realms.keys()}
        except Exception as e:
            logger.warning(f"Failed to check if realm exists: {e}")
            return False

    def policy_exists(self, policy_name):
        """Check if policy exists"""
        try:
            response = self.get('/system/getPolicy', params={'name': policy_name})
            policies = response.get('result', {}).get('value', {})
            return policy_name in policies
        except Exception as e:
            logger.warning(f"Failed to check if policy exists: {e}")
            return False


def validate_config():
    """Validate required configuration"""
    required_vars = {
        'LINOTP_ADMIN_PASSWORD': LINOTP_ADMIN_PASSWORD,
        'AD_LDAP_URI': AD_URI,
        'AD_BASE_DN': AD_BASE_DN,
        'AD_BIND_DN': AD_BIND_DN,
        'AD_BIND_PASSWORD': AD_BIND_PASSWORD,
    }

    missing = [k for k, v in required_vars.items() if not v]
    if missing:
        raise LinOTPConfigError(f"Missing required environment variables: {', '.join(missing)}")

    logger.info("Configuration validated")


def wait_for_linotp(client, max_attempts=30, delay=10):
    """Wait for LinOTP to be ready"""
    logger.info(f"Waiting for LinOTP at {LINOTP_URL}...")

    for attempt in range(1, max_attempts + 1):
        try:
            # Try to login - this will test if LinOTP is ready and authenticate
            client.login()
            # Test if API is working
            response = client.get('/system/getResolvers')
            logger.info("LinOTP is ready and authenticated")
            return True
        except Exception as e:
            if attempt == max_attempts:
                raise LinOTPConfigError(f"LinOTP not ready after {max_attempts} attempts: {e}")
            logger.info(f"Attempt {attempt}/{max_attempts}: LinOTP not ready yet, retrying in {delay}s...")
            time.sleep(delay)

    return False


def create_ldap_resolver(client):
    """Create LDAP UserIdResolver for Active Directory"""
    if client.resolver_exists(RESOLVER_NAME):
        logger.info(f"Resolver '{RESOLVER_NAME}' already exists, skipping creation")
        return

    logger.info(f"Creating LDAP resolver '{RESOLVER_NAME}'...")

    # LinOTP LDAP resolver configuration
    resolver_config = {
        'resolver': RESOLVER_NAME,
        'type': 'ldapresolver',
        f'LDAPURI': AD_URI,
        f'LDAPBASE': AD_BASE_DN,
        f'BINDDN': AD_BIND_DN,
        f'BINDPW': AD_BIND_PASSWORD,
        f'LDAPSEARCHFILTER': AD_SEARCH_FILTER,
        f'LDAPFILTER': AD_USER_FILTER,
        f'LOGINNAMEATTRIBUTE': 'sAMAccountName',
        f'USERINFO': json.dumps({
            'username': 'sAMAccountName',
            'phone': 'telephoneNumber',
            'mobile': 'mobile',
            'email': 'mail',
            'surname': 'sn',
            'givenname': 'givenName',
            'description': 'description'
        }),
        f'TIMEOUT': '5',
        f'SIZELIMIT': '500',
        f'NOREFERRALS': 'True',
        f'CACERTIFICATE': '',  # Add if using self-signed cert
    }

    try:
        client.post('/system/setResolver', data=resolver_config)
        logger.info(f"LDAP resolver '{RESOLVER_NAME}' created successfully")
    except Exception as e:
        raise LinOTPConfigError(f"Failed to create LDAP resolver: {e}")


def create_realm(client):
    """Create realm and assign resolver"""
    if client.realm_exists(REALM_NAME):
        logger.info(f"Realm '{REALM_NAME}' already exists, skipping creation")
        return

    logger.info(f"Creating realm '{REALM_NAME}'...")

    realm_config = {
        'realm': REALM_NAME,
        'resolvers': RESOLVER_NAME
    }

    try:
        client.post('/system/setRealm', data=realm_config)
        logger.info(f"Realm '{REALM_NAME}' created successfully")
    except Exception as e:
        raise LinOTPConfigError(f"Failed to create realm: {e}")


def set_default_realm(client):
    """Set default realm"""
    logger.info(f"Setting '{REALM_NAME}' as default realm...")

    try:
        client.post('/system/setDefaultRealm', data={'DefaultRealm': REALM_NAME})
        logger.info(f"Default realm set to '{REALM_NAME}'")
    except Exception as e:
        raise LinOTPConfigError(f"Failed to set default realm: {e}")


def create_authentication_policy(client):
    """Create authentication policy"""
    policy_name = 'radius_auth'

    if client.policy_exists(policy_name):
        logger.info(f"Policy '{policy_name}' already exists, skipping creation")
        return

    logger.info(f"Creating authentication policy '{policy_name}'...")

    policy_config = {
        'name': policy_name,
        'scope': 'authentication',
        'action': 'otppin=1',
        'user': '*',
        'realm': REALM_NAME,
        'client': '',  # All clients
        'active': 'True'
    }

    try:
        client.post('/system/setPolicy', data=policy_config)
        logger.info(f"Authentication policy '{policy_name}' created successfully")
    except Exception as e:
        raise LinOTPConfigError(f"Failed to create authentication policy: {e}")


def create_enrollment_policy(client):
    """Create token enrollment policy"""
    policy_name = 'self_enrollment'

    if client.policy_exists(policy_name):
        logger.info(f"Policy '{policy_name}' already exists, skipping creation")
        return

    logger.info(f"Creating enrollment policy '{policy_name}'...")

    policy_config = {
        'name': policy_name,
        'scope': 'enrollment',
        'action': 'maxtoken=5, tokenissuer=LAA WorkSpaces MFA',
        'user': '*',
        'realm': REALM_NAME,
        'active': 'True'
    }

    try:
        client.post('/system/setPolicy', data=policy_config)
        logger.info(f"Enrollment policy '{policy_name}' created successfully")
    except Exception as e:
        raise LinOTPConfigError(f"Failed to create enrollment policy: {e}")


def create_selfservice_policy(client):
    """Create self-service portal policy"""
    policy_name = 'selfservice_portal'

    if client.policy_exists(policy_name):
        logger.info(f"Policy '{policy_name}' already exists, skipping creation")
        return

    logger.info(f"Creating self-service policy '{policy_name}'...")

    policy_config = {
        'name': policy_name,
        'scope': 'selfservice',
        'action': 'enrollHMAC, setOTPPIN, setMOTPPIN, resync, disable, delete, history',
        'user': '*',
        'realm': REALM_NAME,
        'active': 'True'
    }

    try:
        client.post('/system/setPolicy', data=policy_config)
        logger.info(f"Self-service policy '{policy_name}' created successfully")
    except Exception as e:
        raise LinOTPConfigError(f"Failed to create self-service policy: {e}")


def main():
    """Main configuration workflow"""
    logger.info("=" * 60)
    logger.info("LinOTP Automated Configuration")
    logger.info("=" * 60)

    try:
        # Validate configuration
        validate_config()

        # Initialize client
        client = LinOTPClient(LINOTP_URL, LINOTP_ADMIN_USER, LINOTP_ADMIN_PASSWORD)

        # Wait for LinOTP to be ready
        wait_for_linotp(client)

        # Configuration steps
        logger.info("\n--- Step 1: LDAP Resolver ---")
        create_ldap_resolver(client)

        logger.info("\n--- Step 2: Realm Configuration ---")
        create_realm(client)
        set_default_realm(client)

        logger.info("\n--- Step 3: Policy Configuration ---")
        create_authentication_policy(client)
        create_enrollment_policy(client)
        create_selfservice_policy(client)

        logger.info("\n" + "=" * 60)
        logger.info("✅ LinOTP configuration completed successfully")
        logger.info("=" * 60)

        return 0

    except LinOTPConfigError as e:
        logger.error(f"Configuration failed: {e}")
        return 1
    except Exception as e:
        logger.error(f"Unexpected error: {e}", exc_info=True)
        return 1


if __name__ == '__main__':
    sys.exit(main())
