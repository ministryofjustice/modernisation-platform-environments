locals {
  application_url_prefix   = "meansassessment"
  lower_env_cloudfront_url = "${local.application_url_prefix}.${data.aws_route53_zone.external.name}"
  custom_header            = "X-Custom-Header-LAA-${upper(local.application_name)}"

  # TODO Note that the application variable's domain_name will be the actual CloudFront alias for production
  prod_fqdn         = data.aws_route53_zone.production-network-services.name
  cloudfront_alias  = local.environment == "production" ? local.prod_fqdn : local.lower_env_cloudfront_url
  cloudfront_domain = local.environment == "production" ? local.prod_fqdn : local.application_data.accounts[local.environment].cloudfront_domain_name


  cloudfront_default_cache_behavior = {
    smooth_streaming                           = false
    allowed_methods                            = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods                             = ["HEAD", "GET"]
    forwarded_values_query_string              = true
    forwarded_values_headers                   = ["Authorization", "CloudFront-Forwarded-Proto", "CloudFront-Is-Desktop-Viewer", "CloudFront-Is-Mobile-Viewer", "CloudFront-Is-SmartTV-Viewer", "CloudFront-Is-Tablet-Viewer", "CloudFront-Viewer-Country", "Host", "User-Agent"]
    forwarded_values_cookies_forward           = "whitelist"
    forwarded_values_cookies_whitelisted_names = ["AWSALB", "JSESSIONID"]
    viewer_protocol_policy                     = "redirect-to-https"
  }

  # Other cache behaviors are processed in the order in which they're listed in the CloudFront console or, if you're using the CloudFront API, the order in which they're listed in the DistributionConfig element for the distribution.
  cloudfront_ordered_cache_behavior = {
    "cache_behavior_0" = {
      smooth_streaming                 = false
      path_pattern                     = "*.png"
      min_ttl                          = 0
      allowed_methods                  = ["GET", "HEAD"]
      cached_methods                   = ["HEAD", "GET"]
      forwarded_values_query_string    = false
      forwarded_values_headers         = ["Host", "User-Agent"]
      forwarded_values_cookies_forward = "none"
      viewer_protocol_policy           = "https-only"
    },
    "cache_behavior_1" = {
      smooth_streaming                 = false
      path_pattern                     = "*.jpg"
      min_ttl                          = 0
      allowed_methods                  = ["GET", "HEAD"]
      cached_methods                   = ["HEAD", "GET"]
      forwarded_values_query_string    = false
      forwarded_values_headers         = ["Host", "User-Agent"]
      forwarded_values_cookies_forward = "none"
      viewer_protocol_policy           = "https-only"
    },
    "cache_behavior_2" = {
      smooth_streaming                 = false
      path_pattern                     = "*.gif"
      min_ttl                          = 0
      allowed_methods                  = ["GET", "HEAD"]
      cached_methods                   = ["HEAD", "GET"]
      forwarded_values_query_string    = false
      forwarded_values_headers         = ["Host", "User-Agent"]
      forwarded_values_cookies_forward = "none"
      viewer_protocol_policy           = "https-only"
    },
    "cache_behavior_3" = {
      smooth_streaming                 = false
      path_pattern                     = "*.css"
      min_ttl                          = 0
      allowed_methods                  = ["GET", "HEAD"]
      cached_methods                   = ["HEAD", "GET"]
      forwarded_values_query_string    = false
      forwarded_values_headers         = ["Host", "User-Agent"]
      forwarded_values_cookies_forward = "none"
      viewer_protocol_policy           = "https-only"
    },
    "cache_behavior_4" = {
      smooth_streaming                 = false
      path_pattern                     = "*.js"
      min_ttl                          = 0
      allowed_methods                  = ["GET", "HEAD"]
      cached_methods                   = ["HEAD", "GET"]
      forwarded_values_query_string    = false
      forwarded_values_headers         = ["Host", "User-Agent"]
      forwarded_values_cookies_forward = "none"
      viewer_protocol_policy           = "https-only"
    }
  }
}

# data "aws_ec2_managed_prefix_list" "cloudfront" {
#   name = "com.amazonaws.global.cloudfront.origin-facing"
# }

resource "random_password" "cloudfront" {
  length  = 16
  special = false
}

resource "aws_secretsmanager_secret" "cloudfront" {
  name        = "cloudfront-secret-${upper(local.application_name)}" # ${formatdate("DDMMMYYYYhhmm", timestamp())}
  description = "Simple secret created by AWS CloudFormation to be shared between ALB and CloudFront"
  tags = merge(
    local.tags,
    {
      Name = "cloudfront-secret-${upper(local.application_name)}"
    }
  )
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

# Mirroring laa-cloudfront-logging-development in laa-dev
resource "aws_s3_bucket" "cloudfront" {
  bucket = "laa-${local.application_name}-cloudfront-logging-${local.environment}"
  # force_destroy = true # Enable to recreate bucket deleting everything inside
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
    custom_header {
      name  = local.custom_header
      value = data.aws_secretsmanager_secret_version.cloudfront.secret_string
    }
  }
  enabled = "true"
  aliases = [local.cloudfront_alias]
  default_cache_behavior {
    target_origin_id = aws_lb.external.id
    smooth_streaming = lookup(local.cloudfront_default_cache_behavior, "smooth_streaming", null)
    allowed_methods  = lookup(local.cloudfront_default_cache_behavior, "allowed_methods", null)
    cached_methods   = lookup(local.cloudfront_default_cache_behavior, "cached_methods", null)
    forwarded_values {
      query_string = lookup(local.cloudfront_default_cache_behavior, "forwarded_values_query_string", null)
      headers      = lookup(local.cloudfront_default_cache_behavior, "forwarded_values_headers", null)
      cookies {
        forward           = lookup(local.cloudfront_default_cache_behavior, "forwarded_values_cookies_forward", null)
        whitelisted_names = lookup(local.cloudfront_default_cache_behavior, "forwarded_values_cookies_whitelisted_names", null)
      }
    }
    viewer_protocol_policy = lookup(local.cloudfront_default_cache_behavior, "viewer_protocol_policy", null)
  }

  dynamic "ordered_cache_behavior" {
    for_each = local.cloudfront_ordered_cache_behavior
    content {
      target_origin_id = aws_lb.external.id
      smooth_streaming = lookup(ordered_cache_behavior.value, "smooth_streaming", null)
      path_pattern     = lookup(ordered_cache_behavior.value, "path_pattern", null)
      min_ttl          = lookup(ordered_cache_behavior.value, "min_ttl", null)
      default_ttl      = lookup(ordered_cache_behavior.value, "default_ttl", null)
      max_ttl          = lookup(ordered_cache_behavior.value, "max_ttl", null)
      allowed_methods  = lookup(ordered_cache_behavior.value, "allowed_methods", null)
      cached_methods   = lookup(ordered_cache_behavior.value, "cached_methods", null)
      forwarded_values {
        query_string = lookup(ordered_cache_behavior.value, "forwarded_values_query_string", null)
        headers      = lookup(ordered_cache_behavior.value, "forwarded_values_headers", null)
        cookies {
          forward           = lookup(ordered_cache_behavior.value, "forwarded_values_cookies_forward", null)
          whitelisted_names = lookup(ordered_cache_behavior, "forwarded_values_cookies_whitelisted_names", null)
        }
      }
      viewer_protocol_policy = lookup(ordered_cache_behavior.value, "viewer_protocol_policy", null)
    }
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

  web_acl_id = aws_wafv2_web_acl.waf_acl.arn

  depends_on = [aws_wafv2_web_acl.waf_acl]

  # This is a required block in Terraform. Here we are having no geo restrictions.
  restrictions {
    geo_restriction {
      restriction_type = "none"
      locations        = []
    }
  }

  #   is_ipv6_enabled = true

  tags = local.tags

}

resource "aws_route53_record" "cloudfront-non-prod" {
  count    = local.environment != "production" ? 1 : 0
  provider = aws.core-vpc
  zone_id  = data.aws_route53_zone.external.zone_id
  name     = "${local.application_url_prefix}.${data.aws_route53_zone.external.name}"
  type     = "A"
  alias {
    name                   = aws_cloudfront_distribution.external.domain_name
    zone_id                = aws_cloudfront_distribution.external.hosted_zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "cloudfront-prod" {
  count    = local.environment == "production" ? 1 : 0
  provider = aws.core-network-services
  zone_id  = data.aws_route53_zone.production-network-services.zone_id
  name     = local.application_data.accounts[local.environment].cloudfront_domain_name # TODO Production URL to be confirmed
  type     = "A"
  alias {
    name                   = aws_cloudfront_distribution.external.domain_name
    zone_id                = aws_cloudfront_distribution.external.hosted_zone_id
    evaluate_target_health = true
  }
}

resource "aws_acm_certificate" "cloudfront" {
  domain_name               = local.application_data.accounts[local.environment].cloudfront_domain_name
  validation_method         = "DNS"
  provider                  = aws.us-east-1
  subject_alternative_names = local.environment == "production" ? null : [local.lower_env_cloudfront_url]
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
  validation_record_fqdns = local.environment == "production" ? [local.cloudfront_domain_name_main[0]] : [local.cloudfront_domain_name_main[0], local.cloudfront_domain_name_sub[0]]
}
