terraform {
  required_version = ">= 1.2, < 2.0"

  required_providers {
    aws = {
      source                = "hashicorp/aws"
      version               = "~> 6.0"
      configuration_aliases = [aws.us_east_1]
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

variable "configuration" {
  description = "Shared prototype edge configuration for CloudFront, WAF, and the public ALB origin protected by CloudFront ingress and a secret header."
  type = object({
    domain_name            = string
    hosted_zone_id         = string
    certificate_arn        = string
    origin_certificate_arn = string
    name_prefix            = string
    vpc_id                 = string
    public_subnet_ids      = list(string)
    allowed_ipv4_cidrs     = set(string)
  })
  nullable = false

  validation {
    condition = (
      length(var.configuration.domain_name) <= 253 &&
      length(split(".", var.configuration.domain_name)) > 1 &&
      alltrue([for label in split(".", var.configuration.domain_name) : can(regex("^[a-z0-9]([a-z0-9-]{0,61}[a-z0-9])?$", label))]) &&
      can(regex("^arn:aws:acm:us-east-1:[0-9]{12}:certificate/", var.configuration.certificate_arn)) &&
      can(regex("^arn:aws:acm:eu-west-2:[0-9]{12}:certificate/", var.configuration.origin_certificate_arn)) &&
      can(regex("^[a-z0-9]([a-z0-9-]{1,34}[a-z0-9])$", var.configuration.name_prefix)) &&
      length(var.configuration.vpc_id) > 0 &&
      length(var.configuration.public_subnet_ids) >= 2 &&
      length(var.configuration.allowed_ipv4_cidrs) > 0 &&
      alltrue([for cidr in var.configuration.allowed_ipv4_cidrs : can(cidrnetmask(cidr)) && try(tonumber(split("/", cidr)[1]) > 0, false)])
    )
    error_message = "Supply a lowercase domain, us-east-1 and eu-west-2 ACM certificates, a valid name prefix, a VPC with at least two public subnets, and nonempty IPv4 CIDRs excluding 0.0.0.0/0."
  }
}

variable "tags" {
  type = map(string)
}

locals {
  name                = var.configuration.name_prefix
  origin_token_header = "X-Origin-Verify-${upper(replace(local.name, "-", ""))}"
}

resource "random_password" "origin_token" {
  length  = 48
  special = false
}

resource "aws_secretsmanager_secret" "origin_token" {
  name        = "${local.name}/cloudfront-origin-token"
  description = "Shared secret header used to authenticate CloudFront requests at the prototype ALB."
  tags        = var.tags
}

resource "aws_secretsmanager_secret_version" "origin_token" {
  secret_id     = aws_secretsmanager_secret.origin_token.id
  secret_string = random_password.origin_token.result
}

data "aws_ec2_managed_prefix_list" "cloudfront" {
  name = "com.amazonaws.global.cloudfront.origin-facing"
}

resource "aws_security_group" "alb" {
  name        = "${local.name}-prototype-alb"
  description = "Allow CloudFront origin-facing addresses to reach the prototype ALB"
  vpc_id      = var.configuration.vpc_id
  tags        = var.tags

  ingress {
    description     = "CloudFront origin-facing prefix list only"
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    prefix_list_ids = [data.aws_ec2_managed_prefix_list.cloudfront.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_lb" "shared" {
  name               = substr("${local.name}-alb", 0, 32)
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = var.configuration.public_subnet_ids
  tags               = var.tags
}

resource "aws_lb_listener" "shared" {
  load_balancer_arn = aws_lb.shared.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = var.configuration.origin_certificate_arn

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "Access denied - requests must come through CloudFront with a valid origin token and prototype host rule"
      status_code  = "403"
    }
  }
}

resource "aws_cloudfront_cache_policy" "dynamic" {
  name    = "${local.name}-dynamic"
  comment = "Disable caching for dynamic prototype applications"

  min_ttl     = 0
  default_ttl = 0
  max_ttl     = 0

  parameters_in_cache_key_and_forwarded_to_origin {
    cookies_config {
      cookie_behavior = "none"
    }
    headers_config {
      header_behavior = "none"
    }
    query_strings_config {
      query_string_behavior = "none"
    }
  }
}

resource "aws_cloudfront_origin_request_policy" "all_viewer" {
  name    = "${local.name}-all-viewer"
  comment = "Forward host, headers, cookies, and query strings to prototype services"

  cookies_config {
    cookie_behavior = "all"
  }
  headers_config {
    header_behavior = "allViewer"
  }
  query_strings_config {
    query_string_behavior = "all"
  }
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
  name = "${local.name}-security"
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
  enabled         = true
  is_ipv6_enabled = false
  aliases         = ["*.${var.configuration.domain_name}"]
  comment         = "Shared dynamic prototype edge"
  price_class     = "PriceClass_100"
  web_acl_id      = aws_wafv2_web_acl.shared.arn
  tags            = var.tags

  origin {
    domain_name = aws_route53_record.origin.fqdn
    origin_id   = "prototype-alb"

    custom_origin_config {
      http_port                = 80
      https_port               = 443
      origin_protocol_policy   = "https-only"
      origin_ssl_protocols     = ["TLSv1.2"]
      origin_read_timeout      = 30
      origin_keepalive_timeout = 60
    }

    custom_header {
      name  = local.origin_token_header
      value = aws_secretsmanager_secret_version.origin_token.secret_string
    }
  }

  default_cache_behavior {
    target_origin_id           = "prototype-alb"
    viewer_protocol_policy     = "redirect-to-https"
    allowed_methods            = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods             = ["GET", "HEAD"]
    compress                   = true
    cache_policy_id            = aws_cloudfront_cache_policy.dynamic.id
    origin_request_policy_id   = aws_cloudfront_origin_request_policy.all_viewer.id
    response_headers_policy_id = aws_cloudfront_response_headers_policy.security.id
  }

  dynamic "custom_error_response" {
    for_each = toset([400, 403, 404, 500, 502, 503, 504])

    content {
      error_code            = custom_error_response.value
      error_caching_min_ttl = 0
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

resource "aws_route53_record" "origin" {
  zone_id = var.configuration.hosted_zone_id
  name    = "origin.${var.configuration.domain_name}"
  type    = "A"

  alias {
    name                   = aws_lb.shared.dns_name
    zone_id                = aws_lb.shared.zone_id
    evaluate_target_health = true
  }
}

output "hosting" {
  value = {
    distribution_id         = aws_cloudfront_distribution.shared.id
    distribution_arn        = aws_cloudfront_distribution.shared.arn
    web_acl_arn             = aws_wafv2_web_acl.shared.arn
    load_balancer_arn       = aws_lb.shared.arn
    listener_arn            = aws_lb_listener.shared.arn
    origin_domain_name      = aws_route53_record.origin.fqdn
    origin_token_secret_arn = aws_secretsmanager_secret.origin_token.arn
    origin_token_header     = local.origin_token_header
    domain_name             = var.configuration.domain_name
    prototype_url_template  = "https://{prototype-id}.${var.configuration.domain_name}"
  }
}
