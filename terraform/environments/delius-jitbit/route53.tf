## JitBit DNS Cutover Test
locals {
  zone_name = "jitbit.dev.cr.probation.service.justice.gov.uk"
}

data "aws_route53_zone" "external_test" {
  provider = aws.core-network-services

  name         = local.zone_name
  private_zone = false
}

resource "aws_route53_record" "external_test" {
  provider = aws.core-network-services

  zone_id = data.aws_route53_zone.external_test.zone_id
  name    = "helpdesk.${local.zone_name}"
  type    = "A"

  alias {
    name                   = aws_lb.external.dns_name
    zone_id                = aws_lb.external.zone_id
    evaluate_target_health = true
  }
}

# END JitBit DNS Cutover Test

resource "aws_route53_record" "external" {
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

resource "aws_acm_certificate" "external" {
  domain_name       = "modernisation-platform.service.justice.gov.uk"
  validation_method = "DNS"

  subject_alternative_names = [
    "${var.networking[0].application}.${var.networking[0].business-unit}-${local.environment}.modernisation-platform.service.justice.gov.uk",
    "helpdesk.jitbit.dev.cr.probation.service.justice.gov.uk" # JitBit DNS Cutover Test
  ]
  tags = {
    Environment = local.environment
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "external_validation" {
  provider = aws.core-network-services

  allow_overwrite = true
  name            = local.domain_name_main[0]
  records         = local.domain_record_main
  ttl             = 60
  type            = local.domain_type_main[0]
  zone_id         = data.aws_route53_zone.network-services.zone_id
}

resource "aws_route53_record" "external_validation_subdomain" {
  provider = aws.core-vpc

  allow_overwrite = true
  name            = local.domain_name_sub[0]
  records         = local.domain_record_sub
  ttl             = 60
  type            = local.domain_type_sub[0]
  zone_id         = data.aws_route53_zone.external.zone_id
}

# JitBit DNS Cutover Test
resource "aws_route53_record" "external_validation_subdomain_test" {
  provider = aws.core-network-services

  allow_overwrite = true
  name            = local.domain_name_prod[0]
  records         = local.domain_record_prod
  ttl             = 60
  type            = local.domain_type_prod[0]
  zone_id         = data.aws_route53_zone.external_test.zone_id
}

resource "aws_acm_certificate_validation" "external" {
  certificate_arn         = aws_acm_certificate.external.arn
  validation_record_fqdns = [local.domain_name_main[0], local.domain_name_sub[0], local.domain_name_prod[0]]
}
