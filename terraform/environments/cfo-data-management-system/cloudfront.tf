# CloudFront Distribution — Visualiser
# Serves Visualiser ALB. Restricts direct ALB access using a shared custom header secret.

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
  domain_name       = local.application_data.accounts[local.environment].visualiser_domain
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }

  tags = local.tags
}

# Route53 validation records for ACM certificate
resource "aws_route53_record" "cloudfront_visualiser_cert_validation" {
  provider = aws.core-vpc

  for_each = {
    for dvo in aws_acm_certificate.cloudfront_visualiser.domain_validation_options : dvo.domain_name => dvo
  }

  zone_id = data.aws_route53_zone.external.zone_id
  name    = each.value.resource_record_name
  type    = each.value.resource_record_type
  records = [each.value.resource_record_value]
  ttl     = 300

  allow_overwrite = true
}

# ACM Certificate validation
resource "aws_acm_certificate_validation" "cloudfront_visualiser" {
  provider        = aws.us-east-1
  certificate_arn = aws_acm_certificate.cloudfront_visualiser.arn
  validation_record_fqdns = [
    for record in aws_route53_record.cloudfront_visualiser_cert_validation : record.fqdn
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

    # Secret injected into every request — verified by the ALB listener rule
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
