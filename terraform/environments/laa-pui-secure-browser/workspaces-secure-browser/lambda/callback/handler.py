"""
Lambda OAuth callback (Azure) — robust, debug-friendly drop-in.

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
from http import cookies as http_cookies
import hmac
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

    jar = http_cookies.SimpleCookie()
    jar.load(cookie_header)
    # URL-decode each value (CF function set with encodeURIComponent)
    return {k: urllib.parse.unquote(v.value) for k, v in jar.items()}

def const_time_eq(a: str, b: str) -> bool:
    """Constant-time string comparison; safe if both are str (or None)."""
    if a is None or b is None:
        return False
    return hmac.compare_digest(a.encode('utf-8'), b.encode('utf-8'))

def handler(event: Dict[str, Any], context: Any) -> Dict[str, Any]:
    try:
        # Query params (HTTP API v2): safe to compute first
        qs = event.get('queryStringParameters') or {}
        code = qs.get('code')
        error = qs.get('error')
        state_param = qs.get('state')

        # Lightweight debug (remove or reduce in prod)
        print("DEBUG queryStringParameters:", json.dumps(qs))
        print("DEBUG event.cookies (raw):", json.dumps(event.get('cookies') or []))
        print("DEBUG headers.cookie:", (event.get('headers') or {}).get('cookie'))

        # parse cookies
        cookies_dict = parse_cookies_from_event(event)
        print("DEBUG parsed_cookies:", json.dumps(cookies_dict))

        print("OAuth callback invoked")

        if error:
            # Avoid echoing raw error to the user; encode for HTML safety
            safe_err = urllib.parse.quote_plus(error)
            return {
                'statusCode': 401,
                'headers': {'Content-Type': 'text/html'},
                'body': f'<html><body><h1>Authentication Error</h1><p>{safe_err}</p></body></html>'
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

        expected_state = cookies_dict.get('oauth_state')
        code_verifier = cookies_dict.get('pkce_ver')

        # state must exist and match
        if not expected_state:
            print("No state cookie present; rejecting")
            return {
                'statusCode': 401,
                'headers': {'Content-Type': 'text/html'},
                'body': '<html><body><h1>Authentication Failed</h1><p>Missing state</p></body></html>'
            }

        # Debug the two values so you can inspect logs when mismatch occurs
        print("DEBUG state_param:", state_param)
        print("DEBUG expected_state (from cookie):", expected_state)

        if not state_param or not const_time_eq(state_param, expected_state):
            print("State mismatch or missing (possible CSRF)")
            return {
                'statusCode': 401,
                'headers': {'Content-Type': 'text/html'},
                'body': '<html><body><h1>Authentication Failed</h1><p>Invalid state</p></body></html>'
            }

        if not code_verifier:
            print("Missing pkce_ver cookie (code_verifier)")
            return {
                'statusCode': 400,
                'headers': {'Content-Type': 'text/html'},
                'body': '<html><body><h1>Bad Request</h1><p>Missing PKCE verifier</p></body></html>'
            }

        # Exchange code for tokens (include code_verifier)
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

        req_data = urllib.parse.urlencode(token_data).encode('utf-8')
        req = urllib.request.Request(token_url, data=req_data,
                                     headers={'Content-Type': 'application/x-www-form-urlencoded'})

        try:
            with urllib.request.urlopen(req, timeout=30) as resp:
                body = resp.read().decode('utf-8')
                token_response = json.loads(body)
        except urllib.error.HTTPError as he:
            # token endpoint error; avoid leaking secrets in logs
            errbody = he.read().decode('utf-8') if hasattr(he, 'read') else str(he)
            print("Token endpoint returned error (status)", getattr(he, 'code', 'unknown'))
            print("Token error body (truncated):", (errbody[:400] + '...') if errbody else '')
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

        # Validate id_token
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

        username = decoded.get('preferred_username') or decoded.get('upn') or decoded.get('email')
        print(f"Authenticated: {username}")

        # Clear cookies reliably using multiValueHeaders for Set-Cookie
        expires = 'Thu, 01 Jan 1970 00:00:00 GMT'
        clear_pkce = f"pkce_ver=deleted; Path=/; Expires={expires}; Secure; HttpOnly; SameSite=None"
        clear_state = f"oauth_state=deleted; Path=/; Expires={expires}; Secure; HttpOnly; SameSite=None"

        return {
            'statusCode': 302,
            'multiValueHeaders': {
                'Set-Cookie': [clear_pkce, clear_state],
                'Location': [portal_url],
                'Cache-Control': ['no-store, no-cache']
            },
            'body': ''
        }

    except Exception as e:
        # Keep the error but don't leak sensitive details
        print("Unexpected error in callback:", str(e))
        return {
            'statusCode': 500,
            'headers': {'Content-Type': 'text/html'},
            'body': '<html><body><h1>Authentication Failed</h1><p>Internal error</p></body></html>'
        }
