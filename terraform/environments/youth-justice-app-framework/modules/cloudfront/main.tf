#tfsec:ignore:AVD-AWS-0013:TODO Will be addressed as part of https://dsdmoj.atlassian.net/browse/LASB-3390
resource "aws_cloudfront_distribution" "external" {
  #checkov:skip=CKV2_AWS_32:TODO Will be addressed as part of https://dsdmoj.atlassian.net/browse/LASB-3390
  #checkov:skip=CKV2_AWS_46:TODO Will be addressed as part of https://dsdmoj.atlassian.net/browse/LASB-3390
  #checkov:skip=CKV2_AWS_47:TODO Will be addressed as part of https://dsdmoj.atlassian.net/browse/LASB-3390
  #checkov:skip=CKV_AWS_305:TODO Will be addressed as part of https://dsdmoj.atlassian.net/browse/LASB-3390
  #checkov:skip=CKV_AWS_310:TODO Will be addressed as part of https://dsdmoj.atlassian.net/browse/LASB-3390
  # http_version = "http2"
  origin {
    domain_name = var.alb_dns
    origin_id   = var.alb_dns
    custom_origin_config {
      http_port                = 80 # This port was not defined in CloudFormation, but should not be used anyways, only required by Terraform
      https_port               = 443
      origin_protocol_policy   = "match-viewer"
      origin_ssl_protocols     = ["TLSv1.2"]
      origin_read_timeout      = 120
      origin_keepalive_timeout = 60
    }
    custom_header {
      name  = "X-Custom-Header"
      value = "${var.project_name}-cloudfront-custom-2024"
    }
  }
  enabled = "true"
  aliases = [var.cloudfront_alias]
  default_cache_behavior {
    target_origin_id           = var.alb_dns
    allowed_methods            = local.cloudfront_default_cache_behavior["allowed_methods"]
    cached_methods             = local.cloudfront_default_cache_behavior["cached_methods"]
    viewer_protocol_policy     = local.cloudfront_default_cache_behavior["viewer_protocol_policy"]
    cache_policy_id            = "4135ea2d-6df8-44a3-9df3-4b5a84be39ad"
    origin_request_policy_id   = aws_cloudfront_origin_request_policy.headers_policy.id
    response_headers_policy_id = aws_cloudfront_response_headers_policy.strict_transport_security.id
  }

  ordered_cache_behavior {
    path_pattern     = "/custom-503.html"
    target_origin_id = "s3-error-page"

    viewer_protocol_policy = "redirect-to-https"

    allowed_methods = ["GET", "HEAD"]
    cached_methods  = ["GET", "HEAD"]

    cache_policy_id            = "4135ea2d-6df8-44a3-9df3-4b5a84be39ad" # Managed-CachingDisabled
    origin_request_policy_id   = "88a5eaf4-2fd4-4709-b370-b4c650ea3fcf" # Managed-CORS-S3Origin
    response_headers_policy_id = aws_cloudfront_response_headers_policy.strict_transport_security.id

    compress = true
  }


  price_class = "PriceClass_100"

  viewer_certificate {
    acm_certificate_arn      = aws_acm_certificate.domain_cert.arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  logging_config {
    include_cookies = false
    bucket          = aws_s3_bucket.cloudfront.bucket_domain_name
    prefix          = ""
  }

  web_acl_id = var.waf_web_acl_arn

  # This is a required block in Terraform. Here we are having no geo restrictions.
  restrictions {
    geo_restriction {
      restriction_type = "whitelist"
      locations        = ["GB", "IE", "FR"]
    }
  }

  # Custom error pages
  origin {
    domain_name = aws_s3_bucket.error_page.bucket_regional_domain_name
    origin_id   = "s3-error-page"

    s3_origin_config {
      # This is still required by Terraform (even though unused)
      origin_access_identity = ""
    }

    origin_access_control_id = aws_cloudfront_origin_access_control.s3_oac.id
  }

  default_root_object = "index.html"

  custom_error_response {
    error_code            = 503
    response_code         = 200
    response_page_path    = "/custom-503.html"
    error_caching_min_ttl = 300
  }

  custom_error_response {
    error_code            = 504
    response_code         = 200
    response_page_path    = "/custom-503.html"
    error_caching_min_ttl = 300
  }
  #   is_ipv6_enabled = true

  tags = var.tags

}

resource "aws_s3_bucket" "cloudfront" {
  #checkov:skip=CKV_AWS_145: Use default encryption, todo add a ticket to change this later
  #checkov:skip=CKV_AWS_144: "Cross-region replication is not required"
  #checkov:skip=CKV_AWS_18:  "Bucket access logging is not required"
  #checkov:skip=CKV_AWS_21:  "Bucket versioning is not required"
  #checkov:skip=CKV2_AWS_61:  "lift and shift" todo fix later  
  #checkov:skip=CKV2_AWS_62:  "lift and shift"
  bucket = "${var.project_name}-${var.environment}-cloudfront-logs"
  tags   = var.tags
}

#tfsec:ignore:AVD-AWS-0132:TODO Will be addressed as part of https://dsdmoj.atlassian.net/browse/LASB-3390
resource "aws_s3_bucket_ownership_controls" "cloudfront" {
  #checkov:skip=CKV2_AWS_65:TODO Will be addressed as part of https://dsdmoj.atlassian.net/browse/LASB-3390
  bucket = aws_s3_bucket.cloudfront.id
  rule {
    object_ownership = "ObjectWriter"
  }
}

#tfsec:ignore:AVD-AWS-0132:TODO Will be addressed as part of https://dsdmoj.atlassian.net/browse/LASB-3390
resource "aws_s3_bucket_public_access_block" "cloudfront" {
  bucket = aws_s3_bucket.cloudfront.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
  # TODO Set prevent_destroy to true to stop Terraform destroying this resource in the future if required
  lifecycle {
    prevent_destroy = false
  }
}

resource "aws_cloudfront_origin_request_policy" "headers_policy" {
  name    = "cloudfront-yjaf-headers-policy"
  comment = "Policy to include all viewer headers, all query strings, and no cookies."

  headers_config {
    header_behavior = "allViewer" # This includes all headers sent by the viewer.
  }

  query_strings_config {
    query_string_behavior = "all" # This includes all query strings in the origin request.
  }

  cookies_config {
    cookie_behavior = "none" # This does not include any cookies in the origin request.
  }
}
#trivy:ignore:AVD-AWS-0132 todo fix later
resource "aws_s3_bucket_server_side_encryption_configuration" "cloudfront" {
  bucket = aws_s3_bucket.cloudfront.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
  # TODO Set prevent_destroy to true to stop Terraform destroying this resource in the future if required
  lifecycle {
    prevent_destroy = false
  }
}

resource "aws_cloudfront_response_headers_policy" "strict_transport_security" {
  #checkov:skip=CKV_AWS_259:Todo fix this later
  name    = "Strict-Transport-Security"
  comment = "Policy to enforce Strict-Transport-Security header."

  security_headers_config {
    strict_transport_security {
      access_control_max_age_sec = 31536000 # 1 year in seconds
      override                   = true     # Matches "Origin override"
      preload                    = true     # Now on for pen test
      include_subdomains         = false    # Matches unchecked includeSubDomains
    }
    content_type_options {
      override = true
    }
    xss_protection {
      override   = true
      protection = true
      mode_block = true
    }
    content_security_policy {
      override                = true
      content_security_policy = "default-src 'none'; script-src 'self' 'unsafe-eval' 'unsafe-inline' 'unsafe-hashes' https://public.tableau.com https://maps.googleapis.com https://maps.gstatic.com https://*.yjbservices.yjb.gov.uk; style-src 'self' 'unsafe-inline' https://fonts.googleapis.com; img-src 'self' data: https://*.imgur.com https://maps.gstatic.com https://maps.googleapis.com https://*.yjbservices.yjb.gov.uk; font-src 'self' https://fonts.gstatic.com; connect-src 'self' https://www.gov.uk https://public.tableau.com https://maps.googleapis.com https://maps.gstatic.com https://*.s3.eu-west-2.amazonaws.com https://*.yjbservices.yjb.gov.uk; object-src 'self' blob: https://*.yjbservices.yjb.gov.uk; frame-src 'self' blob: https://public.tableau.com https://maps.googleapis.com https://maps.gstatic.com https://*.yjbservices.yjb.gov.uk https://eu-west-2.quicksight.aws.amazon.com; worker-src blob:; frame-ancestors 'none';"
    }
  }

}


