"""
Callback handler after JWT authorization.
Simply redirects authenticated user to WorkSpaces Web portal.
"""
import json
import os
from typing import Dict, Any


def handler(event: Dict[str, Any], context: Any) -> Dict[str, Any]:
    """
    Lambda handler for authenticated callback.
    API Gateway JWT authorizer has already validated the token.
    """
    print(f"Event: {json.dumps(event)}")
    
    # JWT is already validated by API Gateway authorizer
    # Just redirect to the portal
    portal_url = os.environ['PORTAL_URL']
    
    return {
        'statusCode': 302,
        'headers': {
            'Location': portal_url,
            'Content-Type': 'text/html'
        },
        'body': ''
    }
