data "aws_route53_zone" "network-services-production" {
  count   = local.is-production ? 1 : 0
  provider = aws.core-network-services

  name         = "jitbit.cr.probation.service.justice.gov.uk."
  private_zone = false
}

resource "aws_route53_record" "external" {
  count    = local.is-production ? 0 : 1
  provider = aws.core-vpc

  zone_id = data.aws_route53_zone.external.zone_id
  name    = local.app_url
  type    = "A"

  alias {
    name                   = aws_lb.external.dns_name
    zone_id                = aws_lb.external.zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "external-prod" {
  count    = local.is-production ? 1 : 0
  provider = aws.core-network-services

  zone_id = data.aws_route53_zone.network-services-production[0].zone_id
  name    = local.app_url
  type    = "A"

  alias {
    name                   = aws_lb.external.dns_name
    zone_id                = aws_lb.external.zone_id
    evaluate_target_health = true
  }
}

resource "aws_acm_certificate" "external" {
  domain_name       = local.domain
  validation_method = "DNS"

  subject_alternative_names = [
    local.app_url
  ]
  tags = {
    Environment = local.environment
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "external_validation" {
  count    = local.is-production ? 0 : 1 # Temporary until we have a production dns delegation in place
  provider = aws.core-network-services

  allow_overwrite = true
  name            = local.domain_name_main[0]
  records         = local.domain_record_main
  ttl             = 60
  type            = local.domain_type_main[0]
  zone_id         = data.aws_route53_zone.network-services.zone_id
}

resource "aws_route53_record" "external_validation_subdomain" {
  count    = local.is-production ? 0 : 1
  provider = aws.core-vpc

  allow_overwrite = true
  name            = local.domain_name_sub[0]
  records         = local.domain_record_sub
  ttl             = 60
  type            = local.domain_type_sub[0]
  zone_id         = data.aws_route53_zone.external.zone_id
}

resource "aws_route53_record" "external_validation_subdomain_prod" {
  count    = local.is-production ? 1 : 0
  provider = aws.core-network-services

  allow_overwrite = true
  name            = local.domain_name_sub[0]
  records         = local.domain_record_sub
  ttl             = 60
  type            = local.domain_type_sub[0]
  zone_id         = data.aws_route53_zone.external.zone_id
}

resource "aws_acm_certificate_validation" "external" {
  count                   = local.is-production ? 0 : 1 # Temporary until we have a production dns delegation in place
  certificate_arn         = aws_acm_certificate.external.arn
  validation_record_fqdns = [local.domain_name_main[0], local.domain_name_sub[0]]
}
