###############################
#  Third CLOUDFRONT deployment–
#  HTTP-only this serves the remaining entries in the old nginx AWS deployment
#  which were stored in the _compiled configuration file.0
#  Creating this to avoid regenrating the Certificate in Production which would involve
#  re-validating the 40+ SAN certificate records
#  Force redeployment to preprod
###############################

# -------------------------------------------------
# 1. ACM Certificate (HTTP-only domains only)
# -------------------------------------------------
resource "aws_acm_certificate" "http_cloudfront_nginx_compiled" {
  provider          = aws.us-east-1
  domain_name       = local.is-production ? "courts.gov.uk" : "${local.environment}.courts.gov.uk"
  validation_method = "DNS"

  # SANS are dynamically calculated in platform_locals dependent on environment
  subject_alternative_names = local.cloudfront_nginx_sans_compiled

  tags = {
    Name        = "tribunals-http-redirect-cert-compiled"
    Environment = local.environment
  }

  lifecycle {
    create_before_destroy = true
  }
}

# -------------------------------------------------
# 2. OUTPUT: DNS Validation Records
# -------------------------------------------------
output "cert_validation_compiled_records" {
  description = <<EOF
Give these to the external AWS account admins.
They must create **CNAME** records in their Route 53 zone.
EOF

  value = [
    for dvo in aws_acm_certificate.http_cloudfront_nginx_compiled.domain_validation_options : {
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
#tfsec:ignore:AVD-AWS-0012
resource "aws_cloudfront_distribution" "tribunals_http_redirect_compiled" {
  #checkov:skip=CKV_AWS_34: This distribution intentionally allows HTTP; Lambda@Edge handles all HTTP→HTTPS redirects for legacy domains.
  #checkov:skip=CKV_AWS_86:"Access logging not required for this distribution"
  #checkov:skip=CKV_AWS_374:"Geo restriction not needed for this public service"
  #checkov:skip=CKV_AWS_305:"Default root object not required as this is an API distribution"
  #checkov:skip=CKV_AWS_310:"Single origin is sufficient for this use case"
  #checkov:skip=CKV2_AWS_32: Distribution is only used for HTTP->HTTPS redirects via Lambda@Edge; no content is served.
  #checkov:skip=CKV2_AWS_47:"Skip Log4j protection as it is handled via WAF"
  #checkov:skip=CKV2_AWS_46:"Origin Access Identity not applicable as origin is ALB, not S3"

  web_acl_id = aws_wafv2_web_acl.tribunals_web_acl.arn

  logging_config {
    include_cookies = false
    bucket          = aws_s3_bucket.cf_redirect_logs.bucket_domain_name
    prefix          = "cloudfront-redirect-logs-v2/"
  }

  # Aliases are dynamically calculated in platform_locals dependent on environment
  aliases = local.cloudfront_nginx_sans_compiled

  origin {
    domain_name = "dummy-http-redirect.s3.amazonaws.com"
    origin_id   = "dummy-http-origin"

    s3_origin_config {
      origin_access_identity = ""
    }
  }

  default_cache_behavior {
    target_origin_id       = "dummy-http-origin"
    viewer_protocol_policy = "allow-all" # Required: Lambda@Edge redirects HTTP to HTTPS targets

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
      lambda_arn   = aws_lambda_function.cloudfront_redirect_lambda.qualified_arn
      include_body = false
    }
  }

  enabled         = true
  is_ipv6_enabled = true
  comment         = "cloudfront-redirect-compiled-${local.environment}"
  price_class     = "PriceClass_All"
  http_version    = "http2"


  # Use the **new dedicated certificate**
  viewer_certificate {
    acm_certificate_arn      = aws_acm_certificate.http_cloudfront_nginx_compiled.arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  tags = {
    Name        = "tribunals-http-redirect-compiled"
    Environment = local.environment
  }

  # Wait for cert to be issued before creating distribution
  depends_on = [
    aws_acm_certificate.http_cloudfront_nginx_compiled,
    aws_lambda_function.cloudfront_redirect_lambda,
    aws_s3_bucket.cf_redirect_logs,
    aws_lambda_permission.allow_http_cloudfront_compiled,
    aws_lambda_permission.allow_replicator
  ]
}

# -------------------------------------------------
# 4. OUTPUT: CloudFront Domain Name (for final CNAME)
# -------------------------------------------------
output "http_redirect_compiled_distribution_domain" {
  description = "CNAME target for HTTP domains (give to external DNS admins)"
  value       = aws_cloudfront_distribution.tribunals_http_redirect_compiled.domain_name
}

resource "aws_ssm_parameter" "cloudfront_distribution_compiled_id" {
  #checkov:skip=CKV2_AWS_34: "AWS SSM Parameter should be Encrypted"
  name  = "/${local.environment}/cloudfront-distribution-compiled-id"
  type  = "String"
  value = aws_cloudfront_distribution.tribunals_http_redirect_compiled.id
}
