# CloudFront Distribution - Visualiser
# Serves Visualiser ALB. Restricts direct ALB access using a shared custom header secret.

locals {
  # Primary domain name (under 65 char)
  cf_primary_domain = local.is-production ? trimprefix(local.application_data.accounts[local.environment].visualiser_domain, "visualiser.") : "modernisation-platform.service.justice.gov.uk"

  # Split cert domain_validation_options into primary and SAN for separate zone writes
  cf_cert_domain_types = {
    for dvo in aws_acm_certificate.cloudfront_visualiser.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }
  cf_cert_validation_main = [for k, v in local.cf_cert_domain_types : v if k == local.cf_primary_domain]
  cf_cert_validation_sub  = [for k, v in local.cf_cert_domain_types : v if k != local.cf_primary_domain]
}

# Custom header password
resource "random_password" "cloudfront_visualiser" {
  length  = 32
  special = false
}

# Custom header shared secret
resource "aws_secretsmanager_secret" "cloudfront_visualiser" {
  name        = "${local.application_name_short}-${local.environment}-cloudfront-visualiser-header"
  description = "Shared secret injected by CloudFront and verified by the visualiser ALB listener"
  kms_key_id  = data.aws_kms_key.general_shared.arn

  tags = merge(local.tags, { Name = "${local.application_name_short}-${local.environment}-cloudfront-visualiser-header" })
}

# Set custom header secret value
resource "aws_secretsmanager_secret_version" "cloudfront_visualiser" {
  secret_id     = aws_secretsmanager_secret.cloudfront_visualiser.id
  secret_string = random_password.cloudfront_visualiser.result
}

# ACM Certificate (us-east-1)
resource "aws_acm_certificate" "cloudfront_visualiser" {
  provider          = aws.us-east-1
  domain_name       = local.cf_primary_domain
  validation_method = "DNS"

  subject_alternative_names = [local.application_data.accounts[local.environment].visualiser_domain]

  lifecycle {
    create_before_destroy = true
  }

  tags = local.tags
}

# Validation record for primary domain - always written to the network-services zone.
resource "aws_route53_record" "cloudfront_visualiser_cert_validation_main" {
  provider = aws.core-network-services

  allow_overwrite = true
  name            = local.cf_cert_validation_main[0].name
  records         = [local.cf_cert_validation_main[0].record]
  ttl             = 300
  type            = local.cf_cert_validation_main[0].type
  zone_id         = data.aws_route53_zone.network-services.zone_id
}

# Non-prod: SAN validation record for visualiser subdomain -> external zone (hmpps-{env})
resource "aws_route53_record" "cloudfront_visualiser_cert_validation_sub_nonprod" {
  count    = local.is-production ? 0 : 1
  provider = aws.core-vpc

  allow_overwrite = true
  name            = local.cf_cert_validation_sub[0].name
  records         = [local.cf_cert_validation_sub[0].record]
  ttl             = 300
  type            = local.cf_cert_validation_sub[0].type
  zone_id         = data.aws_route53_zone.external.zone_id
}

# Prod: SAN validation record for visualiser subdomain -> network-services zone
resource "aws_route53_record" "cloudfront_visualiser_cert_validation_sub_prod" {
  count    = local.is-production ? 1 : 0
  provider = aws.core-network-services

  allow_overwrite = true
  name            = local.cf_cert_validation_sub[0].name
  records         = [local.cf_cert_validation_sub[0].record]
  ttl             = 300
  type            = local.cf_cert_validation_sub[0].type
  zone_id         = data.aws_route53_zone.network-services.zone_id
}

# ACM Certificate validation - wait for both primary and SAN records in all environments
resource "aws_acm_certificate_validation" "cloudfront_visualiser" {
  provider        = aws.us-east-1
  certificate_arn = aws_acm_certificate.cloudfront_visualiser.arn
  validation_record_fqdns = [
    local.cf_cert_validation_main[0].name,
    local.cf_cert_validation_sub[0].name
  ]
}

# CloudFront Distribution
resource "aws_cloudfront_distribution" "visualiser" {
  enabled         = true
  is_ipv6_enabled = true
  comment         = "CFO DMS Visualiser - ${local.environment}"
  aliases         = [local.application_data.accounts[local.environment].visualiser_domain]
  price_class     = "PriceClass_100" # USA, Canada, Europe, & Israel

  origin {
    domain_name = module.lb_visualiser.load_balancer.dns_name
    origin_id   = "visualiser-alb"

    custom_origin_config {
      http_port                = 80
      https_port               = 443
      origin_protocol_policy   = "https-only"
      origin_ssl_protocols     = ["TLSv1.2"]
      origin_read_timeout      = 60
      origin_keepalive_timeout = 60
    }

    # Secret injected into every request - verified by the ALB listener rule
    custom_header {
      name  = "X-CFO-DMS-Origin-Verify"
      value = random_password.cloudfront_visualiser.result
    }
  }

  default_cache_behavior {
    target_origin_id         = "visualiser-alb"
    viewer_protocol_policy   = "redirect-to-https"
    allowed_methods          = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods           = ["GET", "HEAD"]
    cache_policy_id          = "4135ea2d-6df8-44a3-9df3-4b5a84be39ad" # CachingDisabled
    origin_request_policy_id = "b689b0a8-53d0-40ab-baf2-68738e2966ac" # AllViewerExceptHostHeader
  }

  viewer_certificate {
    acm_certificate_arn      = aws_acm_certificate_validation.cloudfront_visualiser.certificate_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  restrictions {
    geo_restriction {
      restriction_type = "whitelist"
      locations        = ["GB"]
    }
  }

  tags = local.tags
}
