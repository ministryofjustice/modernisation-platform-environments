import base64
import binascii
import hmac
import json
import os
from pathlib import Path

import boto3


def _resolve_openapi_path():
    candidate_paths = [
        Path(__file__).with_name("openapi.yaml"),
        Path(__file__).resolve().parents[2] / "openapi.yaml",
    ]
    for candidate in candidate_paths:
        if candidate.exists():
            return candidate
    return candidate_paths[0]


OPENAPI_PATH = _resolve_openapi_path()
SECRETS_MANAGER = boto3.client("secretsmanager")
DOCS_BASIC_AUTH_SECRET_ID = os.environ["DOCS_BASIC_AUTH_SECRET_ID"]


def _response(status_code, body, content_type, extra_headers=None):
    headers = {
        "cache-control": "no-store",
        "content-type": content_type,
        "x-content-type-options": "nosniff",
    }
    headers.update(extra_headers or {})
    return {
        "statusCode": status_code,
        "headers": headers,
        "body": body,
    }


def _unauthorized():
    return _response(
        401,
        "Authentication required",
        "text/plain; charset=utf-8",
        {"www-authenticate": 'Basic realm="Integration Hub API Docs", charset="UTF-8"'},
    )


def _get_header(event, header_name):
    headers = (event or {}).get("headers") or {}
    for key, value in headers.items():
        if key.lower() == header_name.lower():
            return value
    return None


def _load_secret_json(secret_id):
    try:
        response = SECRETS_MANAGER.get_secret_value(SecretId=secret_id)
        secret_string = response.get("SecretString") or ""
        return json.loads(secret_string) if secret_string else {}
    except Exception:
        return {}


def _is_authorized(event):
    authorization = _get_header(event, "authorization")
    if not authorization:
        return False

    try:
        scheme, token = authorization.split(" ", 1)
    except ValueError:
        return False

    if scheme.lower() != "basic":
        return False

    try:
        username, password = base64.b64decode(token.strip()).decode("utf-8").split(":", 1)
    except (ValueError, UnicodeDecodeError, binascii.Error):
        return False

    secret = _load_secret_json(DOCS_BASIC_AUTH_SECRET_ID)
    expected_username = str(secret.get("username", ""))
    expected_password = str(secret.get("password", ""))

    if not expected_username or not expected_password or expected_password == "replace-me":
        return False

    return hmac.compare_digest(username, expected_username) and hmac.compare_digest(password, expected_password)


def _swagger_html(spec_url):
    return f"""<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <title>Integration Hub API Contract</title>
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/swagger-ui-dist@5/swagger-ui.css" />
    <style>
      :root {{
        color-scheme: light;
        --page-bg: linear-gradient(135deg, #f6f9fc 0%, #eef4f8 42%, #dde8f4 100%);
        --panel-bg: rgba(255, 255, 255, 0.92);
        --panel-border: rgba(22, 56, 89, 0.14);
        --ink: #15324d;
        --ink-soft: #49657d;
        --accent: #0066cc;
        --accent-soft: #dcecff;
        --shadow: 0 24px 60px rgba(17, 39, 60, 0.12);
      }}

      body {{
        margin: 0;
        font-family: "Helvetica Neue", Helvetica, Arial, sans-serif;
        background: var(--page-bg);
        color: var(--ink);
      }}

      .page-shell {{
        min-height: 100vh;
        padding: 32px 20px 40px;
      }}

      .hero {{
        max-width: 1180px;
        margin: 0 auto 24px;
        background: var(--panel-bg);
        border: 1px solid var(--panel-border);
        border-radius: 24px;
        box-shadow: var(--shadow);
        overflow: hidden;
      }}

      .hero-inner {{
        padding: 28px 28px 22px;
        background:
          radial-gradient(circle at top right, rgba(0, 102, 204, 0.15), transparent 32%),
          linear-gradient(180deg, rgba(255, 255, 255, 0.98), rgba(250, 252, 255, 0.92));
      }}

      .eyebrow {{
        display: inline-block;
        padding: 6px 10px;
        border-radius: 999px;
        background: var(--accent-soft);
        color: var(--accent);
        font-size: 12px;
        font-weight: 700;
        letter-spacing: 0.08em;
        text-transform: uppercase;
      }}

      h1 {{
        margin: 14px 0 10px;
        font-size: clamp(2rem, 5vw, 3.25rem);
        line-height: 1;
      }}

      .hero p {{
        margin: 0;
        max-width: 760px;
        color: var(--ink-soft);
        font-size: 1rem;
        line-height: 1.65;
      }}

      .hero-meta {{
        display: grid;
        grid-template-columns: repeat(auto-fit, minmax(220px, 1fr));
        gap: 12px;
        margin-top: 22px;
      }}

      .meta-card {{
        padding: 16px 18px;
        border-radius: 18px;
        background: rgba(255, 255, 255, 0.82);
        border: 1px solid rgba(22, 56, 89, 0.1);
      }}

      .meta-card strong {{
        display: block;
        margin-bottom: 6px;
        font-size: 0.95rem;
      }}

      .meta-card span {{
        color: var(--ink-soft);
        font-size: 0.95rem;
        line-height: 1.5;
      }}

      #swagger-ui {{
        max-width: 1180px;
        margin: 0 auto;
        background: rgba(255, 255, 255, 0.96);
        border: 1px solid var(--panel-border);
        border-radius: 24px;
        box-shadow: var(--shadow);
        overflow: hidden;
      }}

      .swagger-ui .topbar {{
        display: none;
      }}

      .swagger-ui .information-container {{
        padding-bottom: 0;
      }}

      .swagger-ui .scheme-container {{
        box-shadow: none;
        border-top: 1px solid rgba(22, 56, 89, 0.08);
        border-bottom: 1px solid rgba(22, 56, 89, 0.08);
      }}

      .swagger-ui .opblock-tag {{
        border-bottom-color: rgba(22, 56, 89, 0.08);
      }}

      @media (max-width: 720px) {{
        .page-shell {{
          padding: 18px 12px 28px;
        }}

        .hero-inner {{
          padding: 20px 18px 18px;
        }}
      }}
    </style>
  </head>
  <body>
    <div class="page-shell">
      <section class="hero">
        <div class="hero-inner">
          <span class="eyebrow">API Contract</span>
          <h1>Integration Hub Managed File Transfer API</h1>
          <p>
            Interactive Swagger UI for the single-upload and multipart upload contract.
            Access to this page is protected by dedicated HTTP Basic auth, while API
            operations inside the UI continue to use the API's own Basic and Bearer schemes.
          </p>
          <div class="hero-meta">
            <div class="meta-card">
              <strong>Authentication</strong>
              <span>Use the Authorize button for Basic credentials or a Bearer token before trying requests.</span>
            </div>
            <div class="meta-card">
              <strong>Sharing Pattern</strong>
              <span>Host the docs on the same API domain and restrict visibility with basic auth or SSO.</span>
            </div>
            <div class="meta-card">
              <strong>Contract Source</strong>
              <span>The UI loads the bundled OpenAPI definition from <code>{spec_url}</code>.</span>
            </div>
          </div>
        </div>
      </section>
      <div id="swagger-ui"></div>
    </div>
    <script src="https://cdn.jsdelivr.net/npm/swagger-ui-dist@5/swagger-ui-bundle.js"></script>
    <script src="https://cdn.jsdelivr.net/npm/swagger-ui-dist@5/swagger-ui-standalone-preset.js"></script>
    <script>
      window.ui = SwaggerUIBundle({{
        url: "{spec_url}",
        dom_id: "#swagger-ui",
        deepLinking: true,
        displayRequestDuration: true,
        docExpansion: "list",
        filter: true,
        persistAuthorization: true,
        tryItOutEnabled: true,
        defaultModelsExpandDepth: 1,
        presets: [
          SwaggerUIBundle.presets.apis,
          SwaggerUIStandalonePreset
        ],
        layout: "BaseLayout"
      }});
    </script>
  </body>
</html>
"""


def lambda_handler(event, _context):
    path = (event or {}).get("rawPath") or "/docs"

    if not _is_authorized(event):
        return _unauthorized()

    if path in ("/docs", "/docs/"):
        return _response(200, _swagger_html("/openapi.yaml"), "text/html; charset=utf-8")

    if path == "/openapi.yaml":
        return _response(200, OPENAPI_PATH.read_text(encoding="utf-8"), "application/yaml; charset=utf-8")

    return _response(404, "Not found", "text/plain; charset=utf-8")
