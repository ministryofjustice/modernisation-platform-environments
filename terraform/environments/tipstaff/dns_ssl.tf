resource "aws_route53_record" "external" {
  count    = local.is-production ? 0 : 1
  provider = aws.core-vpc

  zone_id = data.aws_route53_zone.external.zone_id
  name    = "${var.networking[0].application}.${var.networking[0].business-unit}-${local.environment}.modernisation-platform.service.justice.gov.uk"
  type    = "A"

  alias {
    name                   = aws_lb.tipstaff_lb.dns_name
    zone_id                = aws_lb.tipstaff_lb.zone_id
    evaluate_target_health = true
  }
}

resource "aws_acm_certificate" "external" {
  count             = local.is-production ? 0 : 1
  domain_name       = local.application_data.accounts[local.environment].domain_name
  validation_method = "DNS"

  subject_alternative_names = ["${var.networking[0].application}.${var.networking[0].business-unit}-${local.environment}.modernisation-platform.service.justice.gov.uk"]
  tags = {
    Environment = local.environment
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "external_validation" {
  count    = local.is-production ? 0 : 1
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

resource "aws_acm_certificate_validation" "external" {
  count                   = local.is-production ? 0 : 1
  certificate_arn         = aws_acm_certificate.external[0].arn
  validation_record_fqdns = [local.domain_name_main[0], local.domain_name_sub[0]]
}

// prod dns

resource "aws_route53_record" "external_prod" {
  count    = local.is-production ? 1 : 0
  provider = aws.core-vpc

  zone_id = data.aws_route53_zone.external.zone_id
  name    = "tipstaff.service.justice.gov.uk"
  type    = "A"

  alias {
    name                   = aws_lb.tipstaff_lb.dns_name
    zone_id                = aws_lb.tipstaff_lb.zone_id
    evaluate_target_health = true
  }
}

resource "aws_acm_certificate" "external_prod" {
  count             = local.is-production ? 1 : 0
  domain_name       = local.application_data.accounts[local.environment].domain_name
  validation_method = "DNS"

  subject_alternative_names = ["tipstaff.service.justice.gov.uk"]
  tags = {
    Environment = local.environment
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "external_validation_prod" {
  count    = local.is-production ? 1 : 0
  provider = aws.core-network-services

  allow_overwrite = true
  name            = local.domain_name_main[0]
  records         = local.domain_record_main
  ttl             = 60
  type            = local.domain_type_main[0]
  zone_id         = data.aws_route53_zone.network-services.zone_id
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

resource "aws_acm_certificate_validation" "external_prod" {
  count                   = local.is-production ? 1 : 0
  certificate_arn         = aws_acm_certificate.external_prod[0].arn
  validation_record_fqdns = [local.domain_name_main[0], local.domain_name_sub[0]]
}
