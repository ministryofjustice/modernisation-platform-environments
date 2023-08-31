locals {
  cloudfront_validation_records = {
    for dvo in aws_acm_certificate.cloudfront.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
      zone = lookup(
        local.route53_zones,
        dvo.domain_name,
        lookup(
          local.route53_zones,
          replace(dvo.domain_name, "/^[^.]*./", ""),
          lookup(
            local.route53_zones,
            replace(dvo.domain_name, "/^[^.]*.[^.]*./", ""),
            { provider = "external" }
      )))
      # zone_id = data.aws_route53_zone.portal-dev-private["${local.application_data.accounts[local.environment].acm_domain_name}"].zone_id
    }
  }

  validation_records_cloudfront = {
    for key, value in local.cloudfront_validation_records : key => {
      name   = value.name
      record = value.record
      type   = value.type
    } if value.zone.provider == "external"
  }

  s3_origin_id = "portalerrorpagebucketorigin"

}

### Cloudfront Secret Creation
resource "random_password" "cloudfront" {
  length  = 16
  special = false
}

resource "aws_secretsmanager_secret" "cloudfront" {
  name        = "cloudfront-v1-secret-${local.application_name}-${formatdate("DDMMMYYYYhhmm", timestamp())}"
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


##### Cloudfront Cert
resource "aws_acm_certificate_validation" "cloudfront_certificate_validation" {
  count           = (length(local.validation_records_cloudfront) == 0 || local.external_validation_records_created) ? 1 : 0
  provider        = aws.us-east-1
  certificate_arn = aws_acm_certificate.cloudfront.arn
  validation_record_fqdns = [
    for key, value in local.validation_records_cloudfront : replace(value.name, "/\\.$/", "")
  ]
  depends_on = [
    aws_route53_record.cloudfront_validation_core_network_services,
    aws_route53_record.cloudfront_validation_core_vpc
  ]
}

resource "aws_acm_certificate" "cloudfront" {
  domain_name               = local.application_data.accounts[local.environment].cloudfront_acm_domain_name
  validation_method         = "DNS"
  provider                  = aws.us-east-1
  subject_alternative_names = local.environment == "production" ? null : ["mp-portal.${data.aws_route53_zone.external.name}"]
  tags                      = local.tags
  # TODO Set prevent_destroy to true to stop Terraform destroying this resource in the future if required
  lifecycle {
    prevent_destroy = false
  }
}

resource "aws_route53_record" "cloudfront_validation_core_network_services" {
  provider = aws.core-network-services
  for_each = {
    for key, value in local.cloudfront_validation_records : key => value if value.zone.provider == "core-network-services"
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  # NOTE: value.zone is null indicates the validation zone could not be found
  # Ensure route53_zones variable contains the given validation zone or
  # explicitly provide the zone details in the validation variable.
  zone_id = each.value.zone.zone_id

  depends_on = [
    aws_acm_certificate.cloudfront
  ]
}

resource "aws_route53_record" "cloudfront_validation_core_vpc" {
  provider = aws.core-vpc
  for_each = {
    for key, value in local.cloudfront_validation_records : key => value if value.zone.provider == "core-vpc"
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = each.value.zone.zone_id

  depends_on = [
    aws_acm_certificate.cloudfront
  ]
}