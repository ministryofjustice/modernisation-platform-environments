// DEV + PRE-PRODUCTION DNS CONFIGURATION

// ACM Public Certificate
resource "aws_acm_certificate" "external" {
  domain_name       = "modernisation-platform.service.justice.gov.uk"
  validation_method = "DNS"

  subject_alternative_names = ["*.${var.networking[0].application}.${var.networking[0].business-unit}-${local.environment}.modernisation-platform.service.justice.gov.uk"]
  tags = {
    Environment = local.environment
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_acm_certificate_validation" "external" {
  certificate_arn         = aws_acm_certificate.external.arn
  validation_record_fqdns = [local.domain_name_main[0], local.domain_name_sub[0]]
}

// Route53 DNS records for certificate validation
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

// Create one Route 53 record for each entry in the list of tribunals (assigned in platform_locals.tf)
resource "aws_route53_record" "external_appeals" {
  provider = aws.core-vpc
  zone_id = data.aws_route53_zone.external.zone_id
  name    = "administrativeappeals.${var.networking[0].application}.${var.networking[0].business-unit}-${local.environment}.modernisation-platform.service.justice.gov.uk"
  type    = "A"

  alias {
    name                   = module.appeals.tribunals_lb.dns_name
    zone_id                = module.appeals.tribunals_lb.zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "external_ahmlr" {
  provider = aws.core-vpc 
  zone_id = data.aws_route53_zone.external.zone_id
  name    = "landregistrationdivision.${var.networking[0].business-unit}-${local.environment}.modernisation-platform.service.justice.gov.uk"
  type    = "A"

  alias {
    name                   = module.ahmlr.tribunals_lb.dns_name
    zone_id                = module.ahmlr.tribunals_lb.zone_id
    evaluate_target_health = true
  }
}