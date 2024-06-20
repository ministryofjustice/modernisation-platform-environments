locals {
  s3_origin_id   = "portalerrorpagebucketorigin"
  cloudfront_url = local.environment == "production" ? "tbd.service.justice.gov.uk" : "mp-${local.application_name}.${data.aws_route53_zone.external.name}"
  cloudfront_domain_types = { for dvo in aws_acm_certificate.cloudfront.domain_validation_options : dvo.domain_name => {
    name   = dvo.resource_record_name
    record = dvo.resource_record_value
    type   = dvo.resource_record_type
    }
  }
  cloudfront_domain_name_main   = [for k, v in local.cloudfront_domain_types : v.name if k == "modernisation-platform.service.justice.gov.uk"]
  cloudfront_domain_name_sub    = [for k, v in local.cloudfront_domain_types : v.name if k != "modernisation-platform.service.justice.gov.uk"]
  cloudfront_domain_record_main = [for k, v in local.cloudfront_domain_types : v.record if k == "modernisation-platform.service.justice.gov.uk"]
  cloudfront_domain_record_sub  = [for k, v in local.cloudfront_domain_types : v.record if k != "modernisation-platform.service.justice.gov.uk"]
  cloudfront_domain_type_main   = [for k, v in local.cloudfront_domain_types : v.type if k == "modernisation-platform.service.justice.gov.uk"]
  cloudfront_domain_type_sub    = [for k, v in local.cloudfront_domain_types : v.type if k != "modernisation-platform.service.justice.gov.uk"]
}

### Cloudfront Secret Creation
resource "random_password" "cloudfront" {
  length  = 16
  special = false
}

resource "aws_secretsmanager_secret" "cloudfront" {
  name        = "cloudfront-v1-secret-${local.application_name}"
  description = "Simple secret created by Terraform"
}

resource "aws_secretsmanager_secret_version" "cloudfront" {
  secret_id     = aws_secretsmanager_secret.cloudfront.id
  secret_string = random_password.cloudfront.result
}

# Importing the AWS secrets created previously using arn.
data "aws_secretsmanager_secret" "cloudfront" {
  arn = aws_secretsmanager_secret.cloudfront.arn
}

# Importing the AWS secret version created previously using arn.
data "aws_secretsmanager_secret_version" "cloudfront" {
  secret_id = data.aws_secretsmanager_secret.cloudfront.arn
}

### Cloudfront S3 bucket creation
resource "aws_s3_bucket" "cloudfront" {
  bucket = "laa-${local.application_name}-cloudfront-logging-${local.environment}"
  tags = merge(
    local.tags,
    {
      Name = "laa-${local.application_name}-cloudfront-logging-${local.environment}"
    }
  )
  # TODO Set prevent_destroy to true to stop Terraform destroying this resource in the future if required
  lifecycle {
    prevent_destroy = false
  }
}

resource "aws_s3_bucket" "portalerrorpagebucket" {
  bucket = "laa-${local.application_name}-errorpagebucket-${local.environment}"
  tags = merge(
    local.tags,
    {
      Name = "laa-${local.application_name}-errorpagebucket-${local.environment}"
    }
  )
  # TODO Set prevent_destroy to true to stop Terraform destroying this resource in the future if required
  lifecycle {
    prevent_destroy = false
  }
}

resource "aws_s3_bucket_ownership_controls" "cloudfront" {
  bucket = aws_s3_bucket.cloudfront.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

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

resource "aws_s3_bucket_public_access_block" "cloudfront" {
  bucket                  = aws_s3_bucket.cloudfront.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
  # TODO Set prevent_destroy to true to stop Terraform destroying this resource in the future if required
  lifecycle {
    prevent_destroy = false
  }
}

resource "aws_cloudfront_origin_access_identity" "portalerrorpagebucket" {
  comment = "portalerrorpagebucket"
}

data "aws_iam_policy_document" "portal_error_page_bucket_policy" {
  statement {
    sid = "1"

    actions = [
      "s3:GetObject",
    ]

    resources = [
      aws_s3_bucket.portalerrorpagebucket.id,
    ]
  }
}

resource "aws_cloudfront_distribution" "external" {
  http_version = "http2"
  origin {
    domain_name = aws_lb.external.dns_name
    origin_id   = aws_lb.external.id
    custom_origin_config {
      http_port                = 80 # This port was not defined in CloudFormation, but should not be used anyways, only required by Terraform
      https_port               = 443
      origin_protocol_policy   = "https-only"
      origin_ssl_protocols     = ["TLSv1.2"]
      origin_read_timeout      = 60
      origin_keepalive_timeout = 60
    }
    origin_shield {
      enabled              = false
      origin_shield_region = "eu-west-2"
    }
    custom_header {
      name  = local.custom_header
      value = data.aws_secretsmanager_secret_version.cloudfront.secret_string
    }
  }
  origin {
    domain_name = aws_s3_bucket.portalerrorpagebucket.bucket_regional_domain_name
    origin_id   = local.s3_origin_id
    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.portalerrorpagebucket.cloudfront_access_identity_path
    }
    origin_shield {
      enabled              = false
      origin_shield_region = "eu-west-2"
    }
  }
  enabled = true
  aliases = ["mp-portal.${data.aws_route53_zone.external.name}"]
  default_cache_behavior {
    target_origin_id = aws_lb.external.id
    smooth_streaming = false
    default_ttl      = 0
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["HEAD", "GET"]
    forwarded_values {
      query_string = true
      cookies {
        forward = "all"
      }
    }
    viewer_protocol_policy = "redirect-to-https"
  }

  ordered_cache_behavior {
    target_origin_id = local.s3_origin_id
    smooth_streaming = false
    path_pattern     = "/error-pages/*"
    min_ttl          = 0
    default_ttl      = 0
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["HEAD", "GET"]
    forwarded_values {
      query_string = false
      cookies {
        forward = "all"
      }
    }
    viewer_protocol_policy = "redirect-to-https"
  }

  ordered_cache_behavior {
    target_origin_id = aws_lb.external.id
    smooth_streaming = false
    path_pattern     = "*.png"
    min_ttl          = 0
    default_ttl      = 0
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["HEAD", "GET"]
    forwarded_values {
      query_string = false
      headers      = ["Host", "User-Agent"]
      cookies {
        forward = "all"
      }
    }
    viewer_protocol_policy = "redirect-to-https"
  }

  ordered_cache_behavior {
    target_origin_id = aws_lb.external.id
    smooth_streaming = false
    path_pattern     = "*.jpg"
    min_ttl          = 0
    default_ttl      = 0
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["HEAD", "GET"]
    forwarded_values {
      query_string = false
      headers      = ["Host", "User-Agent"]
      cookies {
        forward = "all"
      }
    }
    viewer_protocol_policy = "redirect-to-https"
  }

  ordered_cache_behavior {
    target_origin_id = aws_lb.external.id
    smooth_streaming = false
    path_pattern     = "*.gif"
    min_ttl          = 0
    default_ttl      = 0
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["HEAD", "GET"]
    forwarded_values {
      query_string = false
      headers      = ["Host", "User-Agent"]
      cookies {
        forward = "all"
      }
    }
    viewer_protocol_policy = "redirect-to-https"
  }

  ordered_cache_behavior {
    target_origin_id = aws_lb.external.id
    smooth_streaming = false
    path_pattern     = "*.css"
    min_ttl          = 0
    default_ttl      = 0
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["HEAD", "GET"]
    forwarded_values {
      query_string = false
      headers      = ["Host", "User-Agent"]
      cookies {
        forward = "all"
      }
    }
    viewer_protocol_policy = "redirect-to-https"
  }

  ordered_cache_behavior {
    target_origin_id = aws_lb.external.id
    smooth_streaming = false
    path_pattern     = "*.js"
    min_ttl          = 0
    default_ttl      = 0
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["HEAD", "GET"]
    forwarded_values {
      query_string = false
      headers      = ["Host", "User-Agent"]
      cookies {
        forward = "all"
      }
    }
    viewer_protocol_policy = "redirect-to-https"
  }

  price_class = "PriceClass_100"

  viewer_certificate {
    acm_certificate_arn      = aws_acm_certificate.cloudfront.arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2018"
  }

  logging_config {
    include_cookies = false
    bucket          = aws_s3_bucket.cloudfront.bucket_domain_name
    prefix          = local.application_name
  }
  web_acl_id = aws_wafv2_web_acl.wafv2_acl.arn

  custom_error_response {
    error_code            = 404
    response_code         = 404
    response_page_path    = "/error-pages/not_found.html"
    error_caching_min_ttl = 5
  }

  custom_error_response {
    error_code            = 502
    response_code         = 502
    response_page_path    = "/error-pages/error.html"
    error_caching_min_ttl = 5
  }

  custom_error_response {
    error_code            = 503
    response_code         = 503
    response_page_path    = "/error-pages/error.html"
    error_caching_min_ttl = 5
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
      locations        = []
    }
  }

  is_ipv6_enabled = true

  tags = local.tags
}

resource "aws_acm_certificate" "cloudfront" {
  domain_name               = local.application_data.accounts[local.environment].mp_domain_name
  validation_method         = "DNS"
  provider                  = aws.us-east-1
  subject_alternative_names = local.environment == "production" ? null : [local.cloudfront_url]
  tags                      = local.tags
  # TODO Set prevent_destroy to true to stop Terraform destroying this resource in the future if required
  lifecycle {
    prevent_destroy = false
  }
}

resource "aws_route53_record" "cloudfront_external_validation" {
  provider = aws.core-network-services

  count           = local.environment == "production" ? 0 : 1
  allow_overwrite = true
  name            = local.cloudfront_domain_name_main[0]
  records         = local.cloudfront_domain_record_main
  ttl             = 60
  type            = local.cloudfront_domain_type_main[0]
  zone_id         = data.aws_route53_zone.network-services.zone_id
}

resource "aws_route53_record" "cloudfront_external_validation_subdomain" {
  provider = aws.core-vpc

  count           = local.environment == "production" ? 0 : 1
  allow_overwrite = true
  name            = local.cloudfront_domain_name_sub[0]
  records         = local.cloudfront_domain_record_sub
  ttl             = 60
  type            = local.cloudfront_domain_type_sub[0]
  zone_id         = data.aws_route53_zone.external.zone_id
}

resource "aws_acm_certificate_validation" "cloudfront" {
  provider                = aws.us-east-1
  certificate_arn         = aws_acm_certificate.cloudfront.arn
  validation_record_fqdns = [local.cloudfront_domain_name_main[0], local.cloudfront_domain_name_sub[0]]
}