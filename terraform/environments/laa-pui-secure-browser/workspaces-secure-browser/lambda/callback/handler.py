"""
Lambda OAuth callback (Azure) — expects pkce_ver and oauth_state cookies set by the CloudFront Function.

Environment variables required:
  - AZURE_TENANT_ID
  - AZURE_CLIENT_ID
  - AZURE_CLIENT_SECRET  (optional; include only if using confidential client)
  - CALLBACK_URL         (the redirect_uri used in the authorize flow)
  - PORTAL_URL           (where to redirect after successful auth)
"""

import os
import json
import urllib.parse
import urllib.request
from typing import Dict, Any
from http import cookies
import jwt
from jwt import PyJWKClient

def parse_cookies_from_event(event: Dict[str, Any]) -> Dict[str, str]:
    """
    Robust cookie parsing: supports API Gateway v2 'cookies' array or legacy 'headers' cookie header.
    Returns dict of cookie-name -> value (URL-decoded).
    """
    cookie_header = ''
    # API Gateway v2 may provide a 'cookies' list
    if isinstance(event.get('cookies'), list) and event.get('cookies'):
        cookie_header = '; '.join(event['cookies'])
    else:
        headers = event.get('headers') or {}
        cookie_header = headers.get('cookie') or headers.get('Cookie') or ''

    if not cookie_header:
        return {}

    jar = cookies.SimpleCookie()
    jar.load(cookie_header)
    return {k: urllib.parse.unquote(v.value) for k, v in jar.items()}

def handler(event: Dict[str, Any], context: Any) -> Dict[str, Any]:
    try:
        # Minimal logging for observability only (avoid logging tokens/code)
        print("OAuth callback invoked")

        qs = event.get('queryStringParameters') or {}
        code = qs.get('code')
        error = qs.get('error')
        state_param = qs.get('state')

        if error:
            return {
                'statusCode': 401,
                'headers': {'Content-Type': 'text/html'},
                'body': f'<html><body><h1>Authentication Error</h1><p>{urllib.parse.quote_plus(error)}</p></body></html>'
            }

        if not code:
            return {
                'statusCode': 400,
                'headers': {'Content-Type': 'text/html'},
                'body': '<html><body><h1>Bad Request</h1><p>No authorization code received</p></body></html>'
            }

        tenant_id = os.environ['AZURE_TENANT_ID']
        client_id = os.environ['AZURE_CLIENT_ID']
        client_secret = os.environ.get('AZURE_CLIENT_SECRET')
        redirect_uri = os.environ['CALLBACK_URL']
        portal_url = os.environ['PORTAL_URL']

        # parse cookies
        cookies_dict = parse_cookies_from_event(event)
        expected_state = cookies_dict.get('oauth_state')
        code_verifier = cookies_dict.get('pkce_ver')

        # validate state
        if expected_state:
            if not state_param or state_param != expected_state:
                print("State mismatch or missing (possible CSRF)")
                return {
                    'statusCode': 401,
                    'headers': {'Content-Type': 'text/html'},
                    'body': '<html><body><h1>Authentication Failed</h1><p>Invalid state</p></body></html>'
                }
        else:
            # If you didn't set state cookie for some reason, fail closed
            print("No state cookie present; rejecting")
            return {
                'statusCode': 401,
                'headers': {'Content-Type': 'text/html'},
                'body': '<html><body><h1>Authentication Failed</h1><p>Missing state</p></body></html>'
            }

        if not code_verifier:
            print("Missing pkce_ver cookie (code_verifier)")
            return {
                'statusCode': 400,
                'headers': {'Content-Type': 'text/html'},
                'body': '<html><body><h1>Bad Request</h1><p>Missing PKCE verifier</p></body></html>'
            }

        # Exchange code for tokens
        token_url = f"https://login.microsoftonline.com/{tenant_id}/oauth2/v2.0/token"
        token_data = {
            'client_id': client_id,
            'grant_type': 'authorization_code',
            'code': code,
            'redirect_uri': redirect_uri,
            'code_verifier': code_verifier
        }
        if client_secret:
            token_data['client_secret'] = client_secret

        data = urllib.parse.urlencode(token_data).encode('utf-8')
        req = urllib.request.Request(token_url, data=data,
                                     headers={'Content-Type': 'application/x-www-form-urlencoded'})

        try:
            with urllib.request.urlopen(req) as resp:
                body = resp.read().decode('utf-8')
                token_response = json.loads(body)
        except urllib.error.HTTPError as he:
            # read body safely (don't leak secrets)
            err = he.read().decode('utf-8') if hasattr(he, 'read') else str(he)
            print("Token endpoint returned error")
            return {
                'statusCode': 502,
                'headers': {'Content-Type': 'text/html'},
                'body': '<html><body><h1>Authentication Failed</h1><p>Token exchange error</p></body></html>'
            }

        id_token = token_response.get('id_token')
        if not id_token:
            print("No id_token in token response")
            return {
                'statusCode': 401,
                'headers': {'Content-Type': 'text/html'},
                'body': '<html><body><h1>Authentication Failed</h1><p>No id_token returned</p></body></html>'
            }

        # Validate id_token signature and claims
        jwks_url = f"https://login.microsoftonline.com/{tenant_id}/discovery/v2.0/keys"
        jwks_client = PyJWKClient(jwks_url)
        signing_key = jwks_client.get_signing_key_from_jwt(id_token)

        decoded = jwt.decode(
            id_token,
            signing_key.key,
            algorithms=["RS256"],
            audience=client_id,
            issuer=f"https://login.microsoftonline.com/{tenant_id}/v2.0"
        )

        # Success: pick a stable identifier for logs / session
        username = decoded.get('preferred_username') or decoded.get('upn') or decoded.get('email')
        print(f"Authenticated: {username}")

        # Clear cookies (delete pkce_ver and oauth_state)
        expires = 'Thu, 01 Jan 1970 00:00:00 GMT'
        clear_pkce = f"pkce_ver=deleted; Path=/; Expires={expires}; Secure; HttpOnly; SameSite=None"
        clear_state = f"oauth_state=deleted; Path=/; Expires={expires}; Secure; HttpOnly; SameSite=None"
        # Note: some API Gateway setups want multiValueHeaders for Set-Cookie; using a single header with comma-separated cookies works in many environments.
        # If you need strict multi header behavior, set multiValueHeaders: {'Set-Cookie': [clear_pkce, clear_state]}
        return {
            'statusCode': 302,
            'headers': {
                'Location': portal_url,
                'Set-Cookie': f"{clear_pkce}, {clear_state}",
                'Cache-Control': 'no-store, no-cache'
            },
            'body': ''
        }

    except Exception as e:
        print("Unexpected error in callback:", str(e))
        return {
            'statusCode': 500,
            'headers': {'Content-Type': 'text/html'},
            'body': '<html><body><h1>Authentication Failed</h1><p>Internal error</p></body></html>'
        }
