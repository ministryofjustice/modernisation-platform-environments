locals {
  lower_env_cloudfront_url = "${local.application_name}.${data.aws_route53_zone.external.name}"
  # TODO: The production CloudFront FQDN is to be determined
  prod_fqdn         = data.aws_route53_zone.production_network_services.name
  cloudfront_alias  = local.environment == "production" ? local.prod_fqdn : local.lower_env_cloudfront_url
  cloudfront_domain = local.environment == "production" ? data.aws_route53_zone.production_network_services.name : local.application_data.accounts[local.environment].acm_cert_domain_name

  custom_header = "X-Custom-Header-LAA-${upper(local.application_name)}"

  cloudfront_default_cache_behavior = {
    smooth_streaming                           = false
    min_ttl                                    = 0
    max_ttl                                    = 31536000
    default_ttl                                = 86400
    allowed_methods                            = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods                             = ["HEAD", "GET"]
    forwarded_values_query_string              = true
    forwarded_values_headers                   = ["Authorization", "CloudFront-Forwarded-Proto", "CloudFront-Is-Desktop-Viewer", "CloudFront-Is-Mobile-Viewer", "CloudFront-Is-SmartTV-Viewer", "CloudFront-Is-Tablet-Viewer", "CloudFront-Viewer-Country", "Host", "User-Agent"]
    forwarded_values_cookies_forward           = "whitelist"
    forwarded_values_cookies_whitelisted_names = ["AWSALB", "JSESSIONID", "ORA_WWV_*"]
    viewer_protocol_policy                     = "https-only"
  }

  # Other cache behaviors are processed in the order in which they're listed in the CloudFront console or, if you're using the CloudFront API, the order in which they're listed in the DistributionConfig element for the distribution.
  # The 3 TTL values are set to achieve the setting of 'Use origin cache headers' without a linked cache policy - see https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudfront_distribution#cache-behavior-arguments
  cloudfront_ordered_cache_behavior = {
    "cache_behavior_0" = {
      smooth_streaming                 = false
      path_pattern                     = "*.png"
      min_ttl                          = 0
      max_ttl                          = 31536000
      default_ttl                      = 86400
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
      max_ttl                          = 31536000
      default_ttl                      = 86400
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
      max_ttl                          = 31536000
      default_ttl                      = 86400
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
      max_ttl                          = 31536000
      default_ttl                      = 86400
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
      max_ttl                          = 31536000
      default_ttl                      = 86400
      allowed_methods                  = ["GET", "HEAD"]
      cached_methods                   = ["HEAD", "GET"]
      forwarded_values_query_string    = false
      forwarded_values_headers         = ["Host", "User-Agent"]
      forwarded_values_cookies_forward = "none"
      viewer_protocol_policy           = "https-only"
    }
  }

  cloudfront_domain_types = { for dvo in aws_acm_certificate.cloudfront.domain_validation_options : dvo.domain_name => {
    name   = dvo.resource_record_name
    record = dvo.resource_record_value
    type   = dvo.resource_record_type
    }
  }
  cloudfront_domain_name_main   = [for k, v in local.cloudfront_domain_types : v.name if k == local.cloudfront_domain]
  cloudfront_domain_name_sub    = [for k, v in local.cloudfront_domain_types : v.name if k != "modernisation-platform.service.justice.gov.uk"]
  cloudfront_domain_record_main = [for k, v in local.cloudfront_domain_types : v.record if k == local.cloudfront_domain]
  cloudfront_domain_record_sub  = [for k, v in local.cloudfront_domain_types : v.record if k != "modernisation-platform.service.justice.gov.uk"]
  cloudfront_domain_type_main   = [for k, v in local.cloudfront_domain_types : v.type if k == local.cloudfront_domain]
  cloudfront_domain_type_sub    = [for k, v in local.cloudfront_domain_types : v.type if k != "modernisation-platform.service.justice.gov.uk"]
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
    object_ownership = local.environment == "production" ? "ObjectWriter" : "BucketOwnerPreferred"
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

resource "aws_s3_bucket_lifecycle_configuration" "cloudfront" {
  count  = local.environment == "production" ? 1 : 0
  bucket = aws_s3_bucket.cloudfront.id

  rule {
    id = "delete-after-90days"

    expiration {
      days = 90
    }

    noncurrent_version_expiration {
      newer_noncurrent_versions = 1
      noncurrent_days           = 90
    }

    status = "Enabled"
  }
}

resource "aws_cloudfront_distribution" "external" {
  # http_version = "http2"
  origin {
    domain_name = module.alb.load_balancer_arn
    origin_id   = module.alb.load_balancer_id
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
      value = module.alb.cloudfront_alb_secret
    }
  }
  enabled = "true"
  aliases = [local.cloudfront_alias]
  default_cache_behavior {
    target_origin_id = module.alb.load_balancer_id
    smooth_streaming = lookup(local.cloudfront_default_cache_behavior, "smooth_streaming", null)
    min_ttl          = lookup(local.cloudfront_default_cache_behavior, "min_ttl", null)
    default_ttl      = lookup(local.cloudfront_default_cache_behavior, "default_ttl", null)
    max_ttl          = lookup(local.cloudfront_default_cache_behavior, "max_ttl", null)
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
      target_origin_id = module.alb.load_balancer_id
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
  name     = "${local.application_name}.${data.aws_route53_zone.external.name}"
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
  zone_id  = data.aws_route53_zone.production_network_services.zone_id
  name     = local.prod_fqdn # TODO Production URL to be confirmed
  type     = "A"
  alias {
    name                   = aws_cloudfront_distribution.external.domain_name
    zone_id                = aws_cloudfront_distribution.external.hosted_zone_id
    evaluate_target_health = true
  }
}

resource "aws_acm_certificate" "cloudfront" {
  domain_name               = local.cloudfront_domain
  validation_method         = "DNS"
  provider                  = aws.us-east-1
  subject_alternative_names = local.environment == "production" ? null : [local.lower_env_cloudfront_url]
  tags                      = local.tags
  # TODO Set prevent_destroy to true to stop Terraform destroying this resource in the future if required
  lifecycle {
    prevent_destroy = false
  }
}

resource "aws_route53_record" "cloudfront_external_validation_prod" {
  provider = aws.core-network-services

  count           = local.environment == "production" ? 1 : 0
  allow_overwrite = true
  name            = local.cloudfront_domain_name_main[0]
  records         = local.cloudfront_domain_record_main
  ttl             = 60
  type            = local.cloudfront_domain_type_main[0]
  zone_id         = data.aws_route53_zone.production_network_services.zone_id
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

