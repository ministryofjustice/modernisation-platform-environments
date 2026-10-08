terraform {
  required_version = ">= 1.2, < 2.0"

  required_providers {
    aws = {
      source                = "hashicorp/aws"
      version               = "~> 6.0"
      configuration_aliases = [aws.us_east_1]
    }
  }
}

variable "configuration" {
  description = "Shared static hosting configuration. Prototype hostnames are registered in the associated CloudFront KeyValueStore by the publishing workflow."
  type = object({
    domain_name        = string
    hosted_zone_id     = string
    certificate_arn    = string
    bucket_prefix      = string
    allowed_ipv4_cidrs = set(string)
  })
  nullable = false

  validation {
    condition = (
      length(var.configuration.domain_name) <= 253 &&
      length(split(".", var.configuration.domain_name)) > 1 &&
      alltrue([for label in split(".", var.configuration.domain_name) : can(regex("^[a-z0-9]([a-z0-9-]{0,61}[a-z0-9])?$", label))]) &&
      can(regex("^arn:aws:acm:us-east-1:[0-9]{12}:certificate/", var.configuration.certificate_arn)) &&
      can(regex("^[a-z0-9]([a-z0-9-]{1,34}[a-z0-9])$", var.configuration.bucket_prefix)) &&
      length(var.configuration.allowed_ipv4_cidrs) > 0 &&
      alltrue([for cidr in var.configuration.allowed_ipv4_cidrs : can(cidrnetmask(cidr)) && try(tonumber(split("/", cidr)[1]) > 0, false)])
    )
    error_message = "Supply a lowercase domain, a us-east-1 ACM certificate, a 3-36 character account-regional bucket prefix, and nonempty IPv4 CIDRs excluding 0.0.0.0/0."
  }
}

variable "tags" {
  type = map(string)
}

locals {
  name = var.configuration.bucket_prefix
}

module "prototypes" {
  source = "github.com/ministryofjustice/modernisation-platform-terraform-s3-bucket?ref=v11.2.0"

  providers = {
    aws                    = aws
    aws.bucket-replication = aws
  }

  bucket_prefix      = local.name
  bucket_namespace   = "account-regional"
  ownership_controls = "BucketOwnerEnforced"
  versioning_enabled = true
  sse_algorithm      = "AES256"
  force_destroy      = false

  lifecycle_rule = [{
    id      = "expire-noncurrent-prototype-versions"
    enabled = "Enabled"
    prefix  = ""
    noncurrent_version_expiration = {
      days = 30
    }
  }]

  bucket_policy_v2 = [{
    effect  = "Allow"
    actions = ["s3:GetObject"]
    principals = {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }
    conditions = [{
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = [aws_cloudfront_distribution.shared.arn]
    }]
  }]

  tags = var.tags
}

resource "aws_cloudfront_origin_access_control" "prototypes" {
  provider                          = aws.us_east_1
  name                              = local.name
  description                       = "Private shared static prototype origin"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_key_value_store" "prototypes" {
  provider = aws.us_east_1
  name     = "${local.name}-prototypes"
  comment  = "Registered AI prototype hostnames and S3 prefixes"
}

resource "aws_cloudfront_function" "route" {
  provider                     = aws.us_east_1
  name                         = "${local.name}-route"
  runtime                      = "cloudfront-js-2.0"
  publish                      = true
  code                         = file("${path.module}/route.js")
  key_value_store_associations = [aws_cloudfront_key_value_store.prototypes.arn]
}

resource "aws_wafv2_ip_set" "allowed" {
  provider           = aws.us_east_1
  name               = local.name
  scope              = "CLOUDFRONT"
  ip_address_version = "IPV4"
  addresses          = sort(tolist(var.configuration.allowed_ipv4_cidrs))
  tags               = var.tags
}

resource "aws_wafv2_web_acl" "shared" {
  provider = aws.us_east_1
  name     = local.name
  scope    = "CLOUDFRONT"
  tags     = var.tags

  default_action {
    allow {}
  }

  rule {
    name     = "BlockOutsideAllowedNetworks"
    priority = 0
    action {
      block {}
    }
    statement {
      not_statement {
        statement {
          ip_set_reference_statement {
            arn = aws_wafv2_ip_set.allowed.arn
          }
        }
      }
    }
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "BlockOutsideAllowedNetworks"
      sampled_requests_enabled   = false
    }
  }

  rule {
    name     = "CommonThreats"
    priority = 1
    override_action {
      none {}
    }
    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    }
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "CommonThreats"
      sampled_requests_enabled   = false
    }
  }

  rule {
    name     = "KnownBadInputs"
    priority = 2
    override_action {
      none {}
    }
    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesKnownBadInputsRuleSet"
        vendor_name = "AWS"
      }
    }
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "KnownBadInputs"
      sampled_requests_enabled   = false
    }
  }

  rule {
    name     = "RateLimit"
    priority = 3
    action {
      block {}
    }
    statement {
      rate_based_statement {
        limit              = 2000
        aggregate_key_type = "IP"
      }
    }
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "RateLimit"
      sampled_requests_enabled   = false
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = local.name
    sampled_requests_enabled   = false
  }
}

resource "aws_cloudwatch_log_group" "waf" {
  provider          = aws.us_east_1
  name              = "aws-waf-logs-${local.name}"
  retention_in_days = 30
  tags              = var.tags
}

resource "aws_wafv2_web_acl_logging_configuration" "shared" {
  provider                = aws.us_east_1
  resource_arn            = aws_wafv2_web_acl.shared.arn
  log_destination_configs = [aws_cloudwatch_log_group.waf.arn]
  redacted_fields {
    single_header {
      name = "cookie"
    }
  }
  redacted_fields {
    single_header {
      name = "authorization"
    }
  }
  redacted_fields {
    query_string {}
  }
}

resource "aws_cloudfront_response_headers_policy" "security" {
  provider = aws.us_east_1
  name     = "${local.name}-security"
  security_headers_config {
    content_type_options {
      override = true
    }
    frame_options {
      frame_option = "SAMEORIGIN"
      override     = true
    }
    referrer_policy {
      referrer_policy = "no-referrer"
      override        = true
    }
    strict_transport_security {
      access_control_max_age_sec = 31536000
      include_subdomains         = true
      override                   = true
    }
  }
}

resource "aws_cloudfront_distribution" "shared" {
  provider        = aws.us_east_1
  enabled         = true
  is_ipv6_enabled = false
  aliases         = ["*.${var.configuration.domain_name}"]
  comment         = "Shared static prototype edge"
  price_class     = "PriceClass_100"
  web_acl_id      = aws_wafv2_web_acl.shared.arn
  tags            = var.tags

  origin {
    domain_name              = module.prototypes.bucket.bucket_regional_domain_name
    origin_id                = "shared-static"
    origin_access_control_id = aws_cloudfront_origin_access_control.prototypes.id
  }

  default_cache_behavior {
    target_origin_id           = "shared-static"
    viewer_protocol_policy     = "redirect-to-https"
    allowed_methods            = ["GET", "HEAD", "OPTIONS"]
    cached_methods             = ["GET", "HEAD"]
    compress                   = true
    min_ttl                    = 0
    default_ttl                = 300
    max_ttl                    = 86400
    response_headers_policy_id = aws_cloudfront_response_headers_policy.security.id

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    function_association {
      event_type   = "viewer-request"
      function_arn = aws_cloudfront_function.route.arn
    }
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn      = var.configuration.certificate_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }
}

resource "aws_route53_record" "prototypes" {
  zone_id = var.configuration.hosted_zone_id
  name    = "*.${var.configuration.domain_name}"
  type    = "A"
  alias {
    name                   = aws_cloudfront_distribution.shared.domain_name
    zone_id                = aws_cloudfront_distribution.shared.hosted_zone_id
    evaluate_target_health = false
  }
}

output "hosting" {
  value = {
    distribution_id        = aws_cloudfront_distribution.shared.id
    distribution_arn       = aws_cloudfront_distribution.shared.arn
    web_acl_arn            = aws_wafv2_web_acl.shared.arn
    bucket_name            = module.prototypes.bucket.id
    domain_name            = var.configuration.domain_name
    prototype_url_template = "https://{prototype-id}.${var.configuration.domain_name}"
    upload_prefix_template = "{prototype-id}/"
    key_value_store_arn    = aws_cloudfront_key_value_store.prototypes.arn
  }
}
