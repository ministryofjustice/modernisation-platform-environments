// ACM Public Certificate
resource "aws_acm_certificate" "external" {
  domain_name       = local.is-production ? "wardship-agreements-register.service.justice.gov.uk" : "modernisation-platform.service.justice.gov.uk"
  validation_method = "DNS"

  subject_alternative_names = local.is-production ? null : ["${var.networking[0].application}.${var.networking[0].business-unit}-${local.environment}.modernisation-platform.service.justice.gov.uk"]
  tags = {
    Environment = local.environment
  }

  lifecycle {
    create_before_destroy = true
  }
}

// Validate Cert based on external route53 fqdn
resource "aws_acm_certificate_validation" "external" {
  certificate_arn         = aws_acm_certificate.external.arn
  validation_record_fqdns = [for record in aws_route53_record.cert_validation : record.fqdn]
}

// Non production zone for validation is network-services (production is application zone)
resource "aws_route53_record" "cert_validation" {

  provider = aws.core-network-services

  for_each = {
    for dvo in aws_acm_certificate.external.domain_validation_options : dvo.domain_name => {
      name  = dvo.resource_record_name
      type  = dvo.resource_record_type
      value = dvo.resource_record_value
    }
  }
  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.value]
  ttl             = 300
  type            = each.value.type
  zone_id         = local.is-production ? data.aws_route53_zone.application_zone.zone_id : data.aws_route53_zone.network-services.zone_id
}

// sub-domain validation only required for non-production sites
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

// Route53 DNS record for directing traffic to the service
// Provider, zone and name dependent on production or non-production environment
resource "aws_route53_record" "external-prod" {
  count    = local.is-production ? 1 : 0
  provider = aws.core-network-services
  zone_id  = data.aws_route53_zone.application_zone.zone_id
  name     = "wardship-agreements-register.service.justice.gov.uk"
  type     = "A"

  alias {
    name                   = aws_lb.wardship_lb.dns_name
    zone_id                = aws_lb.wardship_lb.zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "external" {
  count    = local.is-production ? 0 : 1
  provider = aws.core-vpc
  zone_id  = data.aws_route53_zone.external.zone_id
  name     = "${var.networking[0].application}.${var.networking[0].business-unit}-${local.environment}.modernisation-platform.service.justice.gov.uk"
  type     = "A"

  alias {
    name                   = aws_lb.wardship_lb.dns_name
    zone_id                = aws_lb.wardship_lb.zone_id
    evaluate_target_health = true
  }
}
