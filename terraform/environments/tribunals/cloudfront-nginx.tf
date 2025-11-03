###############################
#  SECOND CLOUDFRONT – HTTP-only to replace nginx server in old DSD AWS account
#  DNS records managed by
###############################

# -------------------------------------------------
# 1. ACM Certificate (HTTP-only domains only)
# -------------------------------------------------
resource "aws_acm_certificate" "http_cloudfront_nginx" {
  provider          = aws.us-east-1
  domain_name       = local.is-production ? "ahmlr.gov.uk" : "dev.ahmlr.gov.uk"
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
    for dvo in aws_acm_certificate.http_cloudfront_nginx.domain_validation_options : {
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

  enabled             = true
  is_ipv6_enabled     = true
  comment             = "HTTP-only → HTTPS redirect (external DNS)"
  price_class         = "PriceClass_All"
  http_version        = "http2"

  # Reuse the same domain list as aliases
  aliases = aws_acm_certificate.http_cloudfront_nginx.subject_alternative_names

  # Use the **new dedicated certificate**
  viewer_certificate {
    acm_certificate_arn      = aws_acm_certificate.http_cloudfront_nginx.arn
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
    viewer_protocol_policy = "allow-all"

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

  # -------------------------------------------------
  # LOGGING – S3 bucket in same region as dist (us-east-1)
  # -------------------------------------------------
  logging_config {
    include_cookies = false
    bucket          = aws_s3_bucket.cf_logs.bucket_domain_name
    prefix          = "http-redirect/"
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
    aws_acm_certificate.http_cloudfront_nginx,
    aws_lambda_function.cloudfront_redirect_lambda,
    aws_s3_bucket.cf_logs
  ]
}

# -------------------------------------------------
# 4. OUTPUT: CloudFront Domain Name (for final CNAME)
# -------------------------------------------------
output "http_redirect_distribution_domain" {
  description = "CNAME target for HTTP domains (give to external DNS admins)"
  value       = aws_cloudfront_distribution.tribunals_http_redirect.domain_name
}

# -------------------------------------------------
# S3 Bucket for CloudFront Logs
# -------------------------------------------------
resource "aws_s3_bucket" "cf_logs" {
  provider = aws.us-east-1
  bucket   = "tribunals-http-redirect-logs-dev-${data.aws_caller_identity.current.account_id}"
}

resource "aws_s3_bucket_versioning" "cf_logs" {
  provider = aws.us-east-1
  bucket   = aws_s3_bucket.cf_logs.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "cf_logs" {
  provider = aws.us-east-1
  bucket   = aws_s3_bucket.cf_logs.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Block public access
resource "aws_s3_bucket_public_access_block" "cf_logs" {
  provider                = aws.us-east-1
  bucket                  = aws_s3_bucket.cf_logs.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}