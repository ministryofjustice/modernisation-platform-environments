"""
OAuth callback handler for Azure Entra ID.
Exchanges authorization code for tokens and validates JWT.
"""
import json
import os
import urllib.parse
import urllib.request
from typing import Dict, Any
import jwt
from jwt import PyJWKClient


def handler(event: Dict[str, Any], context: Any) -> Dict[str, Any]:
    """
    Lambda handler for OAuth callback.
    Exchanges auth code for tokens, validates JWT, and redirects to portal.
    """
    print(f"Event: {json.dumps(event)}")
    
    # Extract authorization code from query string
    query_params = event.get('queryStringParameters', {}) or {}
    code = query_params.get('code')
    error = query_params.get('error')
    
    if error:
        return {
            'statusCode': 401,
            'headers': {'Content-Type': 'text/html'},
            'body': f'<html><body><h1>Authentication Error</h1><p>{error}</p></body></html>'
        }
    
    if not code:
        return {
            'statusCode': 400,
            'headers': {'Content-Type': 'text/html'},
            'body': '<html><body><h1>Bad Request</h1><p>No authorization code received</p></body></html>'
        }
    
    # Exchange authorization code for tokens
    tenant_id = os.environ['AZURE_TENANT_ID']
    client_id = os.environ['AZURE_CLIENT_ID']
    client_secret = os.environ['AZURE_CLIENT_SECRET']
    redirect_uri = os.environ['CALLBACK_URL']
    
    token_url = f"https://login.microsoftonline.com/{tenant_id}/oauth2/v2.0/token"
    token_data = {
        'client_id': client_id,
        'client_secret': client_secret,
        'code': code,
        'redirect_uri': redirect_uri,
        'grant_type': 'authorization_code'
    }
    
    try:
        token_request = urllib.request.Request(
            token_url,
            data=urllib.parse.urlencode(token_data).encode('utf-8'),
            headers={'Content-Type': 'application/x-www-form-urlencoded'}
        )
        
        with urllib.request.urlopen(token_request) as response:
            token_response = json.loads(response.read().decode('utf-8'))
        
        id_token = token_response.get('id_token')
        
        if not id_token:
            raise Exception('No id_token in response')
        
        # Validate JWT
        jwks_url = f"https://login.microsoftonline.com/{tenant_id}/discovery/v2.0/keys"
        jwks_client = PyJWKClient(jwks_url)
        signing_key = jwks_client.get_signing_key_from_jwt(id_token)
        
        decoded_token = jwt.decode(
            id_token,
            signing_key.key,
            algorithms=["RS256"],
            audience=client_id,
            issuer=f"https://login.microsoftonline.com/{tenant_id}/v2.0"
        )
        
        print(f"Authenticated user: {decoded_token.get('preferred_username')}")
        
        # Redirect to portal
        portal_url = os.environ['PORTAL_URL']
        
        return {
            'statusCode': 302,
            'headers': {
                'Location': portal_url,
                'Content-Type': 'text/html'
            },
            'body': ''
        }
        
    except Exception as e:
        print(f"Error exchanging code or validating token: {str(e)}")
        return {
            'statusCode': 401,
            'headers': {'Content-Type': 'text/html'},
            'body': f'<html><body><h1>Authentication Failed</h1><p>Unable to verify credentials: {str(e)}</p></body></html>'
        }

