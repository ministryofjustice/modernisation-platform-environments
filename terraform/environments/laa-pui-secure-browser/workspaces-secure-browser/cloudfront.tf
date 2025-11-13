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
      
      // Generate PKCE code_verifier and code_challenge
      function generateCodeVerifier() {
        var array = new Uint8Array(32);
        crypto.getRandomValues(array);
        var verifier = base64URLEncode(array);
        return verifier;
      }
      
      function base64URLEncode(buffer) {
        var str = String.fromCharCode.apply(null, buffer);
        var base64 = btoa(str);
        return base64.replace(/\+/g, '-').replace(/\//g, '_').replace(/=/g, '');
      }
      
      async function sha256(plain) {
        var encoder = new TextEncoder();
        var data = encoder.encode(plain);
        var hashBuffer = await crypto.subtle.digest('SHA-256', data);
        return new Uint8Array(hashBuffer);
      }
      
      async function generateCodeChallenge(verifier) {
        var hashed = await sha256(verifier);
        return base64URLEncode(hashed);
      }
      
      var codeVerifier = generateCodeVerifier();
      var codeChallenge = await generateCodeChallenge(codeVerifier);
      
      // Build Azure Entra ID authorization URL with PKCE
      var authorize = "https://login.microsoftonline.com/${local.azure_config.tenant_id}/oauth2/v2.0/authorize";
      var redirectUri = "${aws_apigatewayv2_api.callback[0].api_endpoint}/callback";
      var redirectUri = "https://" + cloudfrontDomain + "/callback.html";
      var params = [];
      
      params.push("client_id=${local.azure_config.client_id}");
      params.push("response_type=code");
      params.push("redirect_uri=" + encodeURIComponent(redirectUri));
      params.push("scope=" + encodeURIComponent("openid profile email"));
      params.push("code_challenge=" + codeChallenge);
      params.push("code_challenge_method=S256");
      params.push("state=" + Math.random().toString(36).substring(2));
      
      // Pass through login_hint if present
      if (qs.login_hint && qs.login_hint.value) {
        var loginHint = qs.login_hint.value;
        if (loginHint.indexOf('%') === -1) {
          loginHint = encodeURIComponent(loginHint);
        }
        params.push("login_hint=" + loginHint);
      }
      
      var redirectUrl = authorize + "?" + params.join("&");

      // Store code_verifier in httpOnly cookie
      var response = {
        statusCode: 302,
        statusDescription: "Found",
        headers: {
          "location": { "value": redirectUrl },
          "set-cookie": { 
            "value": "code_verifier=" + codeVerifier + "; Secure; HttpOnly; SameSite=Lax; Max-Age=600; Path=/"
          }
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

  origin {
    domain_name = aws_s3_bucket.waiting_room[0].bucket_regional_domain_name
    origin_id   = "s3-waiting-room"

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.waiting_room[0].cloudfront_access_identity_path
    }
  }

  enabled             = true
  is_ipv6_enabled     = true
  comment             = "LAA WorkSpaces Web waiting room and authentication"
  default_root_object = "index.html"
  price_class         = "PriceClass_100"

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
