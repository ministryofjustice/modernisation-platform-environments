### CLOUDFRONT WAITING ROOM / AUTHENTICATION FLOW
# This provides a waiting room experience with Azure Entra ID authentication
# before redirecting users to WorkSpaces Web portal

####################
# CloudFront Function: redirect to Azure Entra ID authorize endpoint
####################
resource "aws_cloudfront_function" "redirect_to_auth" {
  count = local.create_resources ? 1 : 0

  name    = "${local.application_name}-redirect-to-entra-auth-${local.environment}"
  runtime = "cloudfront-js-2.0"
  comment = "Redirect users to Azure Entra ID for authentication"

  code = <<-EOT
function handler(event) {
  var request = event.request;
  var qs = request.querystring || {};

  // -- helpers ---------------------------------------------------------
  function randomBytes(n) {
    var arr = new Array(n);
    for (var i = 0; i < n; i++) {
      arr[i] = Math.floor(Math.random() * 256);
    }
    return new Uint8Array(arr);
  }

  function base64UrlFromBytes(bytes) {
    var b64 = Buffer.from(bytes).toString('base64');
    // remove padding
    while (b64.length && b64.charAt(b64.length - 1) === '=') {
      b64 = b64.slice(0, -1);
    }
    // replace + and / without using regex
    return b64.split('+').join('-').split('/').join('_');
  }

  // compute SHA256 and return base64url
  var crypto = require('crypto');
  function sha256Base64Url(inputStr) {
    var hash = crypto.createHash('sha256').update(inputStr, 'utf8').digest('base64');
    while (hash.length && hash.charAt(hash.length - 1) === '=') {
      hash = hash.slice(0, -1);
    }
    return hash.split('+').join('-').split('/').join('_');
  }

  // -- PKCE + state generation ----------------------------------------
  var verifierBytes = randomBytes(32);
  var code_verifier = base64UrlFromBytes(verifierBytes);

  var code_challenge = sha256Base64Url(code_verifier);

  var stateBytes = randomBytes(16);
  var state = base64UrlFromBytes(stateBytes);

  // -- build authorize URL --------------------------------------------
  var authorize = "https://login.microsoftonline.com/${local.azure_config.tenant_id}/oauth2/v2.0/authorize";

  // Use the existing CloudFront distribution domain as the redirect_uri
  // (assumes aws_cloudfront_distribution.waiting_room already exists in state)
  var cfDomain = "${aws_cloudfront_distribution.waiting_room[0].domain_name}";
  var redirectUri = "https://" + cfDomain + "/callback";

  var params = [];
  params.push("client_id=${local.azure_config.client_id}");
  params.push("response_type=code");
  params.push("redirect_uri=" + encodeURIComponent(redirectUri));
  params.push("scope=" + encodeURIComponent("openid profile email offline_access"));
  params.push("state=" + encodeURIComponent(state));
  params.push("code_challenge=" + encodeURIComponent(code_challenge));
  params.push("code_challenge_method=S256");

  if (qs.login_hint && qs.login_hint.value) {
    var loginHint = qs.login_hint.value;
    if (loginHint.indexOf('%') === -1) loginHint = encodeURIComponent(loginHint);
    params.push("login_hint=" + loginHint);
  }

  var redirectUrl = authorize + "?" + params.join("&");

  // -- cookies --------------------------------------------------------
  var maxAge = 300; // seconds
  var cookieAttrs = "; Path=/; Secure; HttpOnly; SameSite=None; Max-Age=" + maxAge;

  var pkceCookie = "pkce_ver=" + encodeURIComponent(code_verifier) + cookieAttrs;
  var stateCookie = "oauth_state=" + encodeURIComponent(state) + cookieAttrs;

  var response = {
    statusCode: 302,
    statusDescription: "Found",
    headers: {
      "location": { "value": redirectUrl },
      "cache-control": { "value": "no-store, no-cache" }
    },
    cookies: {
      "pkce_ver": { "value": pkceCookie },
      "oauth_state": { "value": stateCookie }
    }
  };

  return response;
}
EOT

  publish = true
}
####################
# CloudFront distribution
####################
resource "aws_cloudfront_distribution" "waiting_room" {
  count = local.create_resources ? 1 : 0

  # S3 origin for waiting room static site
  origin {
    domain_name = aws_s3_bucket.waiting_room[0].bucket_regional_domain_name
    origin_id   = "s3-waiting-room"

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.waiting_room[0].cloudfront_access_identity_path
    }
  }

  # API Gateway origin for callback handling
  origin {
    domain_name = replace(aws_apigatewayv2_api.callback[0].api_endpoint, "https://", "")
    origin_id   = "api-gateway-origin"

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "https-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  enabled             = true
  is_ipv6_enabled     = true
  comment             = "LAA WorkSpaces Web waiting room and authentication"
  default_root_object = "index.html"
  price_class         = "PriceClass_100"

  ####################
  # Special behavior to forward /callback to API Gateway (must come BEFORE default_cache_behavior)
  ####################
  ordered_cache_behavior {
    path_pattern     = "/callback*"
    target_origin_id = "api-gateway-origin"

    allowed_methods = ["GET", "HEAD", "OPTIONS", "POST", "PUT", "PATCH", "DELETE"]
    cached_methods  = ["GET", "HEAD"]

    # Forward cookies & querystrings so Lambda can read pkce_ver and oauth_state
    forwarded_values {
      query_string = true
      cookies {
        forward = "all"
      }
    }

    viewer_protocol_policy = "redirect-to-https"

    # Turn off caching for auth callback responses (Set-Cookie / redirect)
    min_ttl     = 0
    default_ttl = 0
    max_ttl     = 0

    compress = false
  }

  default_cache_behavior {
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "s3-waiting-room"
    viewer_protocol_policy = "redirect-to-https"
    compress               = true

    forwarded_values {
      query_string = true
      cookies {
        forward = "none"
      }
    }

    min_ttl     = 0
    default_ttl = 3600
    max_ttl     = 86400

    # Attach the CloudFront Function to the viewer-request event
    function_association {
      event_type   = "viewer-request"
      function_arn = aws_cloudfront_function.redirect_to_auth[0].arn
    }
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  tags = merge(
    local.tags,
    {
      Name = "laa-workspaces-waiting-room-cf"
    }
  )
}
