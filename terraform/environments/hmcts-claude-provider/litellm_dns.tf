locals {
  litellm_hostname = "claude-gateway.${var.networking[0].business-unit}-${local.environment}.modernisation-platform.service.justice.gov.uk"

  # ACM limits the primary domain to 64 characters, so the platform apex is primary and the hostname is a SAN
  litellm_cert_domain = "modernisation-platform.service.justice.gov.uk"

  litellm_cert_validation = {
    for dvo in aws_acm_certificate.litellm.domain_validation_options : dvo.domain_name => {
      name  = dvo.resource_record_name
      type  = dvo.resource_record_type
      value = dvo.resource_record_value
    }
  }
}

resource "aws_acm_certificate" "litellm" {
  domain_name               = local.litellm_cert_domain
  subject_alternative_names = [local.litellm_hostname]
  validation_method         = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "litellm_cert_validation_apex" {
  provider = aws.core-network-services

  allow_overwrite = true
  name            = local.litellm_cert_validation[local.litellm_cert_domain].name
  records         = [local.litellm_cert_validation[local.litellm_cert_domain].value]
  ttl             = 60
  type            = local.litellm_cert_validation[local.litellm_cert_domain].type
  zone_id         = data.aws_route53_zone.network-services.zone_id
}

resource "aws_route53_record" "litellm_cert_validation_hostname" {
  provider = aws.core-vpc

  allow_overwrite = true
  name            = local.litellm_cert_validation[local.litellm_hostname].name
  records         = [local.litellm_cert_validation[local.litellm_hostname].value]
  ttl             = 60
  type            = local.litellm_cert_validation[local.litellm_hostname].type
  zone_id         = data.aws_route53_zone.external.zone_id
}

resource "aws_acm_certificate_validation" "litellm" {
  certificate_arn = aws_acm_certificate.litellm.arn
  validation_record_fqdns = [
    aws_route53_record.litellm_cert_validation_apex.fqdn,
    aws_route53_record.litellm_cert_validation_hostname.fqdn,
  ]
}

resource "aws_route53_record" "litellm" {
  provider = aws.core-vpc

  zone_id = data.aws_route53_zone.external.zone_id
  name    = local.litellm_hostname
  type    = "A"

  alias {
    name                   = aws_lb.litellm.dns_name
    zone_id                = aws_lb.litellm.zone_id
    evaluate_target_health = true
  }
}
