locals {
  sandbox_app_url = "${var.networking[0].application}-sandbox.${var.networking[0].business-unit}-${local.environment}.${local.domain}"
  sandbox_domain_name_sub =  [for k, v in local.sandbox_domain_types : v.name if k == local.sandbox_app_url]
  sandbox_domain_record_sub = [for k, v in local.sandbox_domain_types : v.record if k == local.sandbox_app_url]
  sandbox_domain_type_sub = [for k, v in local.sandbox_domain_types : v.type if k == local.sandbox_app_url]
  sandbox_domain_types = { for dvo in aws_acm_certificate.external_sandbox[0].domain_validation_options : dvo.domain_name => {
    name   = dvo.resource_record_name
    record = dvo.resource_record_value
    type   = dvo.resource_record_type
    }
  }
}

resource "aws_route53_record" "external_sandbox" {
  count    = local.is-development ? 1 : 0

  provider = aws.core-vpc

  zone_id = data.aws_route53_zone.external.zone_id
  name    = local.sandbox_app_url
  type    = "A"

  alias {
    name                   = aws_lb.external_sandbox[0].dns_name
    zone_id                = aws_lb.external_sandbox[0].zone_id
    evaluate_target_health = true
  }
}

resource "aws_acm_certificate" "external_sandbox" {
  count = local.is-development ? 1 : 0

  domain_name       = local.domain
  validation_method = "DNS"

  subject_alternative_names = [
    local.sandbox_app_url
  ]
  tags = {
    Environment = "sandbox"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "external_validation_sandbox" {
  count    = local.is-development ? 1 : 0

  provider = aws.core-network-services

  allow_overwrite = true
  name            = local.domain_name_main[0]
  type            = local.domain_type_main[0]
  zone_id         = data.aws_route53_zone.external.zone_id
  records         = [local.domain_record_main[0]]
}

resource "aws_route53_record" "external_validation_subdomain_sandbox" {
  count    = local.is-development ? 1 : 0

  provider = aws.core-vpc

  allow_overwrite = true
  name            = local.sandbox_domain_name_sub[0]
  records         = local.sandbox_domain_record_sub
  type            = local.sandbox_domain_type_sub[0]
  zone_id         = data.aws_route53_zone.external.zone_id
}

resource "aws_acm_certificate_validation" "external_sandbox" {
    count = local.is-development ? 1 : 0
    
    certificate_arn         = aws_acm_certificate.external_sandbox[0].arn
    validation_record_fqdns = [local.domain_name_main[0], local.sandbox_domain_name_sub[0]]
}