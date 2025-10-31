###############################
#  SECOND CLOUDFRONT – HTTP-only to replace nginx server in old DSD AWS account
#  DNS records managed by
###############################

# -------------------------------------------------
# 1. ACM Certificate (HTTP-only domains only)
# -------------------------------------------------
resource "aws_acm_certificate" "http_redirect_cert" {
  provider          = aws.us-east-1
  domain_name       = "ahmlr.gov.uk"  # any one of the HTTP domains
  validation_method = "DNS"

  subject_alternative_names = local.is-production ? local.cloudfront_nginx_sans : local.cloudfront_nginx_nonprod_sans

  tags = {
    Name        = "tribunals-http-redirect-cert"
    Environment = local.environment
  }

  lifecycle {
    create_before_destroy = true
  }
}

# -------------------------------------------------
# 2. OUTPUT: DNS Validation Records
# -------------------------------------------------
output "cert_validation_records" {
  description = <<EOF
Give these to the external AWS account admins.
They must create **CNAME** records in their Route 53 zone.
EOF

  value = [
    for dvo in aws_acm_certificate.http_redirect_cert.domain_validation_options : {
      domain = dvo.domain_name
      name   = dvo.resource_record_name
      type   = dvo.resource_record_type
      value  = dvo.resource_record_value
    }
  ]
}

# -------------------------------------------------
# 3. CloudFront Distribution – HTTP only
# -------------------------------------------------
resource "aws_cloudfront_distribution" "tribunals_http_redirect" {
  provider = aws.us-east-1

  enabled             = true
  is_ipv6_enabled     = true
  comment             = "HTTP-only → HTTPS redirect (external DNS)"
  price_class         = "PriceClass_All"
  http_version        = "http2"

  # Reuse the same domain list as aliases
  aliases = aws_acm_certificate.http_redirect_cert.subject_alternative_names

  # Use the **new dedicated certificate**
  viewer_certificate {
    acm_certificate_arn      = aws_acm_certificate.http_redirect_cert.arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  # Dummy origin (never hit)
  origin {
    domain_name = "dummy-http-redirect.s3.amazonaws.com"
    origin_id   = "dummy-http-origin"

    s3_origin_config {
      origin_access_identity = ""
    }
  }

  default_cache_behavior {
    target_origin_id       = "dummy-http-origin"
    viewer_protocol_policy = "redirect-to-https"

    allowed_methods = ["GET", "HEAD", "OPTIONS"]
    cached_methods  = ["GET", "HEAD"]

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    min_ttl     = 0
    default_ttl = 0
    max_ttl     = 0

    # Reuse existing Lambda@Edge
    lambda_function_association {
      event_type   = "viewer-request"
      lambda_arn   = aws_lambda_function.tribunals_redirect_lambda.qualified_arn
      include_body = false
    }
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  tags = {
    Name        = "tribunals-http-redirect"
    Environment = local.environment
  }

  # Wait for cert to be issued before creating distribution
  depends_on = [
    aws_acm_certificate.http_redirect_cert,
    aws_lambda_function.cloudfront_redirect_lambda,
    aws_lambda_permission.allow_cloudfront
  ]
}

# -------------------------------------------------
# 4. OUTPUT: CloudFront Domain Name (for final CNAME)
# -------------------------------------------------
output "http_redirect_distribution_domain" {
  description = "CNAME target for HTTP domains (give to external DNS admins)"
  value       = aws_cloudfront_distribution.tribunals_http_redirect.domain_name
}